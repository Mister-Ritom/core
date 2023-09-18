import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/models/post_model.dart';

class UserDetails extends StatefulWidget {
  final String user;
  const UserDetails({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  Future<void> followUser() async {
    if (widget.user == FirebaseAuth.instance.currentUser!.uid) {
      return Future.error("You cannot follow yourself");
    }
    final followersCol = FirebaseFirestore.instance
        .collection('details')
        .doc(widget.user)
        .collection("followers");
    final currentUserFollowingCol = FirebaseFirestore.instance
        .collection('details')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("following");
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final followersDoc =
          await followersCol.doc(FirebaseAuth.instance.currentUser!.uid).get();
      final followingDoc = await currentUserFollowingCol.doc(widget.user).get();
      if (followersDoc.exists && followingDoc.exists) {
        transaction
            .delete(followersCol.doc(FirebaseAuth.instance.currentUser!.uid));
        transaction.delete(currentUserFollowingCol.doc(widget.user));
      } else {
        final actionId = UniqueKey().toString();
        transaction.set(
            followersCol.doc(FirebaseAuth.instance.currentUser!.uid),
            {"actionId": actionId});
        transaction.set(
            currentUserFollowingCol.doc(widget.user), {"actionId": actionId});
      }
    });
  }

  Stream<DocumentSnapshot>? getFollowingStream() {
    if (widget.user == FirebaseAuth.instance.currentUser!.uid) {
      return null;
    }
    final followersCol = FirebaseFirestore.instance
        .collection('details')
        .doc(widget.user)
        .collection("followers");
    return followersCol.doc(FirebaseAuth.instance.currentUser!.uid).snapshots();
  }

  Future<Map<String, int>> getDetails() async {
    final followersCol = FirebaseFirestore.instance
        .collection('details')
        .doc(widget.user)
        .collection("followers");
    final followingCol = FirebaseFirestore.instance
        .collection('details')
        .doc(widget.user)
        .collection("following");
    final postsCol = FirebaseFirestore.instance
        .collection('posts')
        .where("uploaderId", isEqualTo: widget.user);
    final posts = await postsCol.count().get();
    final followers = await followersCol.count().get();
    final following = await followingCol.count().get();
    return {
      "followers": followers.count,
      "following": following.count,
      "posts": posts.count,
    };
  }

  Future<UserModel> getUserModel(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(id).get();
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<String?> findMostLikedPost(
      List<QueryDocumentSnapshot> postList) async {
    String? mostLikedPostId;
    int maxLikes = -1;

    for (QueryDocumentSnapshot postDoc in postList) {
      String postId = postDoc.id;

      final likesCol = FirebaseFirestore.instance
          .collection('postDetails')
          .doc(postId)
          .collection("likes");

      final likes = await likesCol.count().get();
      int numLikes = likes.count;

      // Update if this post has more likes than the current max
      if (numLikes > maxLikes) {
        maxLikes = numLikes;
        mostLikedPostId = postId;
      }
    }

    return mostLikedPostId;
  }

  Future<Post?> getBestPost() async {
    String id = widget.user;
    final postCollection = FirebaseFirestore.instance
        .collection('posts')
        .where("uploaderId", isEqualTo: id);
    final postList = await postCollection.get();
    final mostLikedPostId = await findMostLikedPost(postList.docs);
    if (mostLikedPostId == null) {
      return null;
    }
    final postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(mostLikedPostId)
        .get();
    if (!postDoc.exists) {
      return null;
    }
    return Post.fromJson(postDoc.data() as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
        future: getUserModel(widget.user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasData) {
            return buildProfileNew(snapshot.data!);
          } else {
            return const Center(
              child: Text("Something Went Wrong"),
            );
          }
        });
  }

  Widget buildProfileNew(UserModel user) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: buildTopImage(user),
        ),
        Expanded(
            flex: 1,
            child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16))),
              elevation: 12,
              clipBehavior: Clip.hardEdge,
              child: buildBottom(user),
            ))
      ],
    );
  }

  Stack buildTopImage(UserModel user) {
    return Stack(
      children: [
        user.bannerUrl != null
            ? Image.network(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                user.bannerUrl!,
                fit: BoxFit.fill,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.inversePrimary,
                    ],
                  ),
                ),
              ),
        FirebaseAuth.instance.currentUser!.uid != widget.user
            ? buildTopAppbar()
            : const SizedBox.shrink(),
        FutureBuilder(
            future: getDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.hasError) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data as Map<String, int>;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                  ),
                  height: 75,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildInfoCard(
                          "Following",
                          data["following"].toString(),
                        ),
                        buildInfoCard(
                          "Posts",
                          data["posts"].toString(),
                        ),
                        buildInfoCard(
                          "Followers",
                          data["followers"].toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget buildTopAppbar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      primary: false,
      forceMaterialTransparency: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 8),
        child: CircleAvatar(
          maxRadius: 14,
          minRadius: 14,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            FontAwesomeIcons.userPlus,
            size: 18,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.more_vert,
            size: 22,
            color: Colors.white,
          ),
        )
      ],
    );
  }

  Column buildInfoCard(String text, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget buildBottom(UserModel user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                user.photoUrl != null
                    ? CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              user.bio ?? "",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildActions(),
                const SizedBox(
                  height: 10,
                ),
                buildBestPost(),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 24,
              ),
              onPressed: () {},
              child: Text(
                "Check out my other posts",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildBestPost() {
    return FutureBuilder<Post?>(
        future: getBestPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final post = snapshot.data;
          if (post == null) return const SizedBox.shrink();
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    post.image != null
                        ? FontAwesomeIcons.image
                        : FontAwesomeIcons.heading,
                    size: 16,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    "${widget.user == FirebaseAuth.instance.currentUser!.uid ? "Your" : "My"} best post",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              post.image != null
                  ? SizedBox(
                      height: 100,
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          post.image ?? "",
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 100,
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Theme.of(context).colorScheme.primary,
                          child: Center(
                            child: Text(
                              post.caption,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        });
  }

  Widget buildActions() {
    if (widget.user == FirebaseAuth.instance.currentUser!.uid) {
      return SizedBox(
        width: 150,
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text("Edit Account")),
            ElevatedButton(onPressed: () {}, child: const Text("Logout")),
            SelectableText(
                "Email: ${FirebaseAuth.instance.currentUser!.email}}"),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder<DocumentSnapshot>(
            stream: getFollowingStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final doc = snapshot.data;
              if (doc == null) return const SizedBox.shrink();
              final isFollowing = doc.exists;
              if (!isFollowing) {
                return ElevatedButton(
                  onPressed: followUser,
                  //TODO change color on tap
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.plus,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        "Follow",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }
              return ElevatedButton(
                onPressed: followUser,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.userCheck,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Following",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
        const SizedBox(
          width: 10,
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Row(
            children: [
              const Icon(
                FontAwesomeIcons.comment,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                "Message",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
