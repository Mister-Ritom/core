import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/models/post_model.dart';

class UserDetails extends StatefulWidget {
  final UserModel user;
  const UserDetails({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}
class _UserDetailsState extends State<UserDetails> {

  Future<void> followUser() async {
    if (widget.user.id == FirebaseAuth.instance.currentUser!.uid) {
      return Future.error("You cannot follow yourself");
    }
    final followersCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.user.id).collection("followers");
    final currentUserFollowingCol = FirebaseFirestore.instance.collection('details')
        .doc(FirebaseAuth.instance.currentUser!.uid).collection("following");
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final followersDoc = await followersCol.doc(FirebaseAuth.instance.currentUser!.uid).get();
      final followingDoc = await currentUserFollowingCol.doc(widget.user.id).get();
      if (followersDoc.exists && followingDoc.exists) {
        transaction.delete(followersCol.doc(FirebaseAuth.instance.currentUser!.uid));
        transaction.delete(currentUserFollowingCol.doc(widget.user.id));
      } else {
        final actionId = UniqueKey().toString();
        transaction.set(followersCol.doc(FirebaseAuth.instance.currentUser!.uid),{"actionId": actionId});
        transaction.set(currentUserFollowingCol.doc(widget.user.id), {"actionId": actionId});
      }
    });

  }

  Stream<DocumentSnapshot>? getFollowingStream() {
    if (widget.user.id == FirebaseAuth.instance.currentUser!.uid) {
      return null;
    }
    final followersCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.user.id).collection("followers");
    return followersCol.doc(FirebaseAuth.instance.currentUser!.uid).snapshots();

  }
  Future<Map<String,int>> getDetails() async {
    final followersCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.user.id).collection("followers");
    final followingCol = FirebaseFirestore.instance.collection('details')
        .doc(widget.user.id).collection("following");
    final postsCol = FirebaseFirestore.instance.collection('posts')
        .where("uploaderId", isEqualTo: widget.user.id);
    final posts = await postsCol.count().get();
    final followers = await followersCol.count().get();
    final following = await followingCol.count().get();
    return {
      "followers": followers.count,
      "following": following.count,
      "posts": posts.count,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.only(top: 42),
        child: Column(
          children: [
            buildUserInfo(context, user),
            const SizedBox(height: 8,),
            buildUserStats(context, user),
            const SizedBox(height: 8,),
            buildButtons(context),
            const SizedBox(height: 8,),
            Expanded(
              child: buildPosts(),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Post>> getPosts(userId) async {
    final snapshot = await FirebaseFirestore.instance.collection('posts')
        .where("uploaderId", isEqualTo: userId)
        .orderBy("timestamp", descending: true).limit(20).get();
    if(snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => Post.fromJson(doc.data())).toList();
    }
    return [];
  }

  Widget buildPosts() {
    return FutureBuilder<List<Post>>(
      future: getPosts(widget.user.id),
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          final posts = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context)
                  .colorScheme.primary.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              shrinkWrap: true,
              primary: false,
              itemCount: posts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                childAspectRatio: 4/3,
              ),
              itemBuilder: (context, index) {
                final post = posts[index];
                if (post.image == null) {
                  return Card(
                    child: Center(
                      child: Text(
                          post.caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ),
                  );
                }
                //TODO make this clickable and goto post screen
                return Image.network(post.image!);
              },
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(),);
      },
    );
  }

  Widget buildButtons(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: getFollowingStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        }
        else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()),);
        }
          final doc = snapshot.data;
          if (doc==null) {
            return const SizedBox.shrink();
          }
          final isFollowing = doc.exists;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: followUser,
                child: SizedBox(
                  width: isFollowing?80: 60,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(isFollowing?"Unfollow":"Follow"),
                      const Icon(FontAwesomeIcons.userPlus, size: 16),
                    ],
                  ),
                )
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: (){},
                child: SizedBox(
                  width: isFollowing?60:120,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(isFollowing?"Chat":"Follow to chat"),
                      const Icon(FontAwesomeIcons.comment, size: 16),
                    ],
                  ),
                )
            ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 12,
      forceMaterialTransparency: true,
      leading:           IconButton(
        onPressed: () {},
        icon: CircleAvatar(
          radius: 21,
          backgroundColor: Theme.of(context).colorScheme.
          secondary.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(
              FontAwesomeIcons.arrowLeft,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: CircleAvatar(
            radius: 21,
            backgroundColor: Theme.of(context).colorScheme.
            secondary.withOpacity(0.3),
            child: const Icon(
              FontAwesomeIcons.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Center buildUserInfo(BuildContext context, UserModel user) {
    return Center(
            child: Container(
                width: MediaQuery.of(context).size.width*0.9,
                height: 250,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: user.bannerUrl!=null?null : const LinearGradient(
                        colors: [Colors.blue,Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight
                    ),
                    image: user.bannerUrl==null?null : DecorationImage(
                        image: NetworkImage(user.bannerUrl!),
                        fit: BoxFit.cover
                    )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8,),
                      SizedBox(
                        width: MediaQuery.of(context).size.width*0.7,
                        height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  height: user.bio!=null? 120 : 60,
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                    child: Container(
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(user.name, style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ), overflow: TextOverflow.ellipsis , maxLines: 3,),
                                    const SizedBox(height: 4,),
                                    if (user.bio!=null)
                                    Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Colors.white,
                                    ),),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
            ),
          );
  }

  Widget buildUserStats(BuildContext context, UserModel user) {
    return FutureBuilder<Map<String,int>>(
      future: getDetails(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final details = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context)
                  .colorScheme.primary.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Card(
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildStat(context, "Posts", details["posts"]!),
                    buildStat(context, "Followers", details["followers"]!),
                    buildStat(context, "Following", details["following"]!),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  Widget buildStat(BuildContext context, String title, int count) {
    return Column(
      children: [
        Text(count.toString(), style: Theme.of(context).textTheme.titleLarge,),
        Text(title, style: Theme.of(context).textTheme.bodyMedium,),
      ],
    );
  }
}