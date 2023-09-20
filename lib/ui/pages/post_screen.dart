import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/widgets/animated_heart.dart';
import 'package:core/ui/widgets/animated_title.dart';
import 'package:core/utils/models/comment_model.dart';
import 'package:core/utils/models/post_model.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostScreen extends StatefulWidget {
  final String postId;

  const PostScreen({super.key, required this.postId});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {

  final commentController = TextEditingController();

  Future<Map<String, int>> getDetails() async {
    final likesCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("likes");
    final commentsCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("comments");
    final viewsCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
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
  Future<void> setViews(String postId) async {
    final viewCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(postId)
        .collection("views");
    final viewsDoc =
    await viewCol.doc(FirebaseAuth.instance.currentUser!.uid).get();
    if (!viewsDoc.exists) {
      final uniqueId = UniqueKey().toString();
      await viewCol.doc(FirebaseAuth.instance.currentUser!.uid).set({
        "actionId": uniqueId,
      });
    }
  }
  Future<bool> isLikedByUser() async {
    final likesCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("likes");
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final like = await likesCol.doc(currentUserId).get();
    return like.exists;
  }

  Future<void> addComment() async {
    final content = commentController.text;
    commentController.clear();
    final time = Timestamp.now();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final comment = Comment(userId: userId, content: content, timestamp: time);
    final commentCol = FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("comments");
    await commentCol.add(comment.toJson());
  }

  Future<Post> getPost() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
    if (!doc.exists || doc.data() == null) throw 'Post does not exist';
    return Post.fromJson(doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    setViews(widget.postId);
    return Scaffold(
      appBar: AppBar(
        actions: [
          //show a cricle avatar of the current user
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                FirebaseAuth.instance.currentUser!.photoURL!,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: getPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          final post = snapshot.data as Post;
          return buildBody(post);
        },
      ),
    );
  }

  Widget buildBody(Post post) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          ListView(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                    post.image!,
                    fit: BoxFit.cover,
                ),
              ),
              AnimatedTitleDescription(
                  title: post.caption, description: post.description),
              buildUser(post.uploaderId),
              Stack(
                children: [
                  buildComments(),
                  buildActions(),
                ],
              ),
            ],
          ),
          buildCommentBox(),
        ],
      ),
    );
  }

  Widget buildCommentBox() {
    //return a textfield for commenting with some decoration
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: commentController,
          maxLines: 6,
          minLines: 1,
          maxLength: 200,
          decoration: InputDecoration(
            filled: true,
            hintText: "Add a comment",
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser!.photoURL!,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16.0),
            ),
            contentPadding: const EdgeInsets.all(0),
            suffixIcon: IconButton(
              onPressed: addComment,
              icon: const Icon(Icons.send),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActions() {
    //fututre builder with the details
    return FutureBuilder<Map<String, int>>(
      future: getDetails(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final details = snapshot.data!;
        return Align(
          alignment: Alignment.centerRight,
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 12,
            //a shape that has the top left border rounded and others rectangle
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                FutureBuilder(
                    future: isLikedByUser(),
                    builder: (context,snapshot) {
                      if (snapshot.hasData) {
                        return SizedBox(
                          width: 50,
                          child: AnimatedHeartButton(
                              count: details['likes']??0,
                              postId: widget.postId,
                              isLiked: snapshot.data as bool,
                            width: 50,
                          ),
                        );
                      }
                      else {
                        return const Icon(FontAwesomeIcons.heart);
                      }
                    }
                ),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(FontAwesomeIcons.comment)),
                Text(details['comments'].toString()),
                IconButton(
                    onPressed: () {}, icon: const Icon(FontAwesomeIcons.eye)),
                Text(details['views'].toString()),
                IconButton(
                    onPressed: () {}, icon: const Icon(FontAwesomeIcons.share)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserModel> getUser(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(id).get();
    if (!doc.exists || doc.data() == null) throw 'User does not exist';
    return UserModel.fromJson(doc.data()!);
  }

  Future<int> getFollowers(String id) async {
    final followersCol = FirebaseFirestore.instance
        .collection('details')
        .doc(id)
        .collection("followers");
    final followers = await followersCol.count().get();
    return followers.count;
  }

  Widget buildUser(String id) {
    return FutureBuilder(
      future: getUser(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        final user = snapshot.data as UserModel;
        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundImage:
                  NetworkImage(user.photoUrl!),
                ),
                Column(
                  children: [
                    Text(user.username),
                    SizedBox(
                      width: 218,
                        child: Text(user.bio??"",
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,)
                    ),
                  ],
                ),
            FutureBuilder(
                 future: getFollowers(id),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(
                       child: CircularProgressIndicator(),
                     );
                   }
                   if (snapshot.hasError) {
                     return Center(
                       child: Text(snapshot.error.toString()),
                     );
                   }
                   final followers = snapshot.data as int;
                   return Column(
                     children: [
                       Text(followers.toString()),
                        const SizedBox(
                          width: 50,
                            child: FittedBox(child: Text("Followers")),
                        ),
                     ],
                   );
                 },
               ),
              ],
            ),
          ),
        );
      },
    );
  }
  DocumentSnapshot<Map<String,dynamic>>? lastCommentDocument;
  Stream<QuerySnapshot<Map<String, dynamic>>> getCommentStream() {
    if (lastCommentDocument == null) {
      return FirebaseFirestore.instance
          .collection('postDetails')
          .doc(widget.postId)
          .collection("comments")
          .orderBy("timestamp", descending: true)
          .limit(10)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('postDetails')
        .doc(widget.postId)
        .collection("comments")
        .orderBy("timestamp", descending: true)
        .limit(10)
        .startAfterDocument(lastCommentDocument!)
        .snapshots();
  }
final comments = [];
  Widget buildComments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getCommentStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data!;
          comments.addAll(docs.docs.map((e) => Comment.fromJson(e.data())).toList());
          return ListView.builder(
            //it is a child list view so change the physics
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return FutureBuilder(
                future: getUser(comment.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }
                  final user = snapshot.data as UserModel;
                  return VisibilityDetector(
                    key: Key(index.toString()),
                    onVisibilityChanged: (VisibilityInfo info) {
                      //check if the last item is partly visible
                      if (lastCommentDocument!=docs.docs.last && index == comments.length - 1 && info.visibleFraction > 0.5) {
                        setState(() {
                          lastCommentDocument = docs.docs.last;
                        });
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.photoUrl!),
                      ),
                      title: Text(user.username),
                      subtitle: Text(comment.content),
                    ),
                  );
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong"),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return const Center(
            child: Text("No comments"),
          );
        }
      },
    );
  }
}
