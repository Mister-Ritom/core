import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/pages/image_fullscreen.dart';
import 'package:core/ui/widgets/animated_title.dart';
import 'package:core/utils/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/models/user_model.dart';
import '../pages/user_details_page.dart';
import 'animated_heart.dart';

class SmallImagePost extends StatefulWidget {
  final Post post;
  const SmallImagePost({Key? key, required this.post}) : super(key: key);

  @override
  State<SmallImagePost> createState() => _SmallImagePostState();
}

class _SmallImagePostState extends State<SmallImagePost> {
  Future<UserModel> getUser(String id) {
    final userCol = FirebaseFirestore.instance.collection('users').doc(id);
    return userCol
        .get()
        .then((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>));
  }

  Future<Map<String, int>> getDetails() async {
    final likesCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.post.id)
        .collection("likes");
    final commentsCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.post.id)
        .collection("comments");
    final viewsCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.post.id)
        .collection("views");
    final views = await viewsCol.count().get();
    final likes = await likesCol.count().get();
    final comments = await commentsCol.count().get();
    return {
      "likes": likes.count,
      "comments": comments.count,
      "views": views.count
    };
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<UserModel>(
              future: getUser(post.uploaderId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final user = snapshot.data!;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: user.photoUrl == null
                        ? null
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetails(
                                    user: user.id,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(user.photoUrl!),
                            ),
                          ),
                    trailing: CircleAvatar(
                      radius: 21,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.3),
                      child: IconButton(
                        icon: const Icon(
                          FontAwesomeIcons.ellipsis,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: user.bio == null
                        ? null
                        : Text(
                            user.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    //image can't be null it is checked in the home
                    child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FullScreenImage(url: post.image!)));
                        },
                        child: Hero(
                            tag: post.image!,
                            child: Image.network(
                              post.image!,
                              fit: BoxFit.fitWidth,
                            ))),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: AnimatedTitleDescription(
                      title: post.caption, description: post.description),
                )
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> isLikedByUser() async {
    final likesCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.post.id)
        .collection("likes");
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final like = await likesCol.doc(currentUserId).get();
    return like.exists;
  }

  Widget buildActions() {
    return FutureBuilder<Map<String, int>>(
        future: getDetails(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder(
                future: isLikedByUser(),
                builder: (context, snapshot2) {
                  if (snapshot2.hasData) {
                    final liked = snapshot2.data as bool;
                    return AnimatedHeartButton(
                      isLiikedbyUser: liked,
                      postId: widget.post.id,
                      count: snapshot.data?["likes"] ?? 0,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              buildButton(context, FontAwesomeIcons.comment,
                  "${snapshot.data?["comments"] ?? 0}  Comments",
                  onClick: () {}),
              buildButton(context, FontAwesomeIcons.eye,
                  "${snapshot.data?["views"] ?? 0}"),
              buildButton(context, FontAwesomeIcons.share, null),
            ],
          );
        });
  }

  Row buildButton(BuildContext context, IconData icon, String? text,
      {Function()? onClick}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClick,
          child: Icon(
            icon,
            size: text == null ? 16 : 14,
          ),
        ),
        if (text != null)
          const Padding(
            padding: EdgeInsets.all(2.0),
            child: Icon(
              FontAwesomeIcons.solidCircle,
              size: 5.0,
            ),
          ),
        if (text != null)
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
      ],
    );
  }
}
