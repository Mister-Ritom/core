import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/pages/user_details_page.dart';
import 'package:core/utils/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/models/user_model.dart';
import 'animated_heart.dart';

class SmallTextPost extends StatefulWidget {
  final Post post;
  const SmallTextPost({Key? key, required this.post}) : super(key: key);

  @override
  State<SmallTextPost> createState() => _SmallTextPostState();
}
class _SmallTextPostState extends State<SmallTextPost> {

  Future<UserModel> getUser(String id) {
    final userCol = FirebaseFirestore.instance.collection('users').doc(id);
    return userCol.get().then((doc) =>
        UserModel.fromJson(doc.data() as Map<String, dynamic>));
  }

  Future<Map<String,int>> getPostDetails() async {
    final likesCol = FirebaseFirestore.instance.collection('postDetails')
        .doc(widget.post.id).collection("likes");
    final commentsCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.post.id).collection("comments");
    final likes = await likesCol.count().get();
    final comments = await commentsCol.count().get();
    return {
      "likes": likes.count,
      "comments": comments.count,
    };
  }

  Future<String> getUserFollowers() async {
    final followersCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.post.uploaderId).collection("followers");
    final followers = await followersCol.count().get();
    final count = followers.count;
    if (count > 1000) {
      return "${(count/1000).toStringAsFixed(1)}K";
    }
    else if (count > 1000000) {
      return "${(count/1000000).toStringAsFixed(1)}M";
    }
    else {
      return count.toString();
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<UserModel>(
            future: getUser(post.uploaderId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: SizedBox(
                        width: 60.0,
                        height: 100,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: (){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder:
                                (context) => UserDetails(user: user)));
                              },
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(user.photoUrl!),
                              ),
                            ),
                            const SizedBox(height: 8.0,),
                            FutureBuilder<String>(
                              future: getUserFollowers(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return SizedBox(
                                    width: 60,
                                    child: FittedBox(
                                      child: Text(
                                        "${snapshot.data} Followers",
                                      ),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const Center(child: Text('Something went wrong'));
                                }
                                else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0,),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 8, top: 8.0),
                                child: CircleAvatar(
                                  radius: 16.0,
                                  backgroundColor: Colors.grey[200]?.withOpacity(0.3),
                                  child: IconButton(
                                      onPressed: (){},
                                      icon: const Icon(FontAwesomeIcons.ellipsis,
                                        size: 16.0,)
                                  ),
                                ),
                              )
                            ],
                          ),
                          Text(
                            user.username,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width*0.77,
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              children: [
                                Text(
                                  post.caption,
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Divider(),
                                Text(
                                  post.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildActions(),
          ),
        ],
      ),
    );
  }

  Widget buildActions() {
    return FutureBuilder<Map<String,int>>(
        future: getPostDetails(),
        builder:(context,snapshot) {
          if (snapshot.hasError)return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState==ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedHeartButton(
                  count: snapshot.data?["likes"] ?? 0,
                  postId: widget.post.id,
                ),
                buildButton(context, FontAwesomeIcons.comment,
                    "${snapshot.data?["comments"] ?? 0}  Comments",
                    onClick: () {}),
                buildButton(context, FontAwesomeIcons.share, "Share"),
              ],
            );
        }
    );
  }

  Row buildButton(BuildContext context, IconData icon, String text, {Function()? onClick}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClick,
          child: Icon(icon, size: 16.0,),
        ),
        const Padding(
          padding: EdgeInsets.all(2.0),
          child: Icon(FontAwesomeIcons.solidCircle, size: 5.0,),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

}