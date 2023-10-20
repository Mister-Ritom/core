import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/widgets/small_image_post.dart';
import 'package:core/ui/widgets/small_story_widget.dart';
import 'package:core/ui/widgets/small_text_post.dart';
import 'package:core/utils/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:story_creator_plus/story_creator.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../utils/models/story_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  Stream<QuerySnapshot<Map<String, dynamic>>> getFollowings() {
    final currentUserFollowingCol = FirebaseFirestore.instance
        .collection('details')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("following");
    return currentUserFollowingCol.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts(List<String> userId) {
    final postCol = FirebaseFirestore.instance
        .collection('posts')
        .where('uploaderId', whereIn: userId)
        .orderBy('timestamp', descending: true)
        .limit(10);
    return postCol.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStories(String userId) {
    // Get the current timestamp
    DateTime now = DateTime.now();

    // Calculate the timestamp 24 hours ago
    DateTime twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final storyCol = FirebaseFirestore.instance
        .collection('stories')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(twentyFourHoursAgo))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('uploaderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    return storyCol.snapshots();
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

  Future<void> _createStory() async {
    final result = await Navigator.push(context,
            MaterialPageRoute(builder: (context) => const StoryCreator()))
        as StoryCreatorResult?;
    if (result != null) {
      final caption = result.caption;
      final image = result.image;
      final id = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('images')
          .child("stories")
          .child(userId)
          .child(id);
      final task = storageRef.putData(image.bytes);
      final snapshot = await task.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      final story = Story(
        id: id,
        uploaderId: userId,
        caption: caption,
        image: downloadUrl,
      );
      final storyCol = FirebaseFirestore.instance.collection('stories');
      await storyCol.doc(id).set(story.toJson());
    }
  }

  final posts = [];
  final postIds = [];
  @override
  Widget build(BuildContext context) {
    //Return a stream of posts
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getFollowings(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data!;
          final followings = docs.docs.map((e) => e.id).toList();
          if (followings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Follow someone to see their posts"),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Find people to follow"),
                  )
                ],
              ),
            );
          }
          followings.shuffle();
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: getPosts(followings),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final docs = snapshot.data!;
                if (!postIds.contains("story")) {
                  posts.add(
                    Post(
                      id: "story",
                      uploaderId: "story",
                      image: "story",
                      caption: "story",
                      description: "story",
                    ),
                  );
                  postIds.add("story");
                }
                final newPosts = docs.docs
                    .map((e) => Post.fromJson(e.data()))
                    .where((element) => !postIds.contains(element.id))
                    .toList();
                for (Post post in newPosts) {
                  if (!postIds.contains(post.id)) {
                    postIds.add(post.id);
                    posts.add(post);
                  }
                }
                posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    if (post.id == "story" && post.uploaderId == "story") {
                      return Card(
                        margin:
                            const EdgeInsets.only(top: 4, left: 8, right: 8),
                        elevation: 6,
                        child: SizedBox(
                          height: 120,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: buildStoryList(followings),
                          ),
                        ),
                      );
                    } else {
                      return VisibilityDetector(
                        key: Key(post.id),
                        onVisibilityChanged: (info) async {
                          final visiblePercentage = info.visibleFraction * 100;
                          if (visiblePercentage > 50) {
                            await setViews(post.id);
                          }
                        },
                        child: post.image == null
                            ? SmallTextPost(
                                post: post,
                              )
                            : SmallImagePost(
                                post: post,
                              ),
                      );
                    }
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
                return const SizedBox.shrink();
              }
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
          return const SizedBox.shrink();
        }
      },
    );
  }

  ListView buildStoryList(List<String> followerIds) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: followerIds.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Container(
                width: 90,
                height: 110,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 85,
                        height: 105,
                        child: Image.network(
                            FirebaseAuth.instance.currentUser!.photoURL!,
                            fit: BoxFit.cover),
                      ),
                    ),
                    BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: Container(
                          color: Colors.black.withOpacity(0.2),
                        )),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Add story",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3),
                            child: IconButton(
                              onPressed: _createStory,
                              icon: const Icon(FontAwesomeIcons.plus),
                            ),
                          ),
                        )),
                      ],
                    )
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: getStories(FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final docs = snapshot.data!;
                    final stories =
                        docs.docs.map((e) => Story.fromJson(e.data())).toList();
                    if (stories.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SmallStoryWidget(
                      stories: stories,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          );
        }
        final followerId = followerIds[index - 1];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getStories(followerId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final docs = snapshot.data!;
              final stories =
                  docs.docs.map((e) => Story.fromJson(e.data())).toList();
              if (stories.isEmpty) {
                return const SizedBox.shrink();
              }
              return SmallStoryWidget(
                stories: stories,
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}
