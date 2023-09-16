import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/models/post_model.dart';
import '../utils/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _HomeState();
}
class _HomeState extends State<ProfilePage> {
  var _currentTab = 0;

  void _onTabClick(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  Future<UserModel> getUserModel(String id) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return buildProfilePage(FirebaseAuth.instance.currentUser!);
  }

  Widget buildProfilePage(User user) {
    return FutureBuilder<UserModel>(
        future: getUserModel(user.uid),
        builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(),);
          }else if(snapshot.hasData){
            return buildProfile(snapshot.data!);
          }else{
            return const Center(child: Text("Something Went Wrong"),);
          }
        }
    );
  }

  Widget buildProfile(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(top: 25,left: 20,right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width*0.9,
            height: 250,
            child: Stack(
              children: [
                buildUserPhoto(user),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge,),
                      Text(
                        user.bio?? "",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.secondary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1)
              ),
              width: MediaQuery.of(context).size.width*0.8,
              height: 50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: (){_onTabClick(0);},
                      child: Text("Posts",
                        style: getTabStyle(0),
                      ),
                    ),
                    TextButton(
                      onPressed: (){_onTabClick(1);},
                      child: Text("Texts",
                        style: getTabStyle(1),
                      ),
                    ),
                    TextButton(
                      onPressed: (){_onTabClick(2);},
                      child: Text("Connections",
                        style: getTabStyle(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Expanded(
            child: _currentTab == 2 ?buildConnections(): buildPosts(user.id),
          )
        ],
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

  Widget buildPosts(userId) {
    return FutureBuilder<List<Post>>(
      future: getPosts(userId),
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          var posts = snapshot.data!;
          if (_currentTab==1) {
            posts = posts.where((element) => element.image==null).toList();
          }
          else if (_currentTab==0) {
            posts = posts.where((element) => element.image!=null).toList();
          }
          return GridView.builder(
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final post = posts[index];
              return Image.network(post.image!);
            },
          );
        }
        return const Center(child: CircularProgressIndicator(),);
      },
    );
  }

  Widget buildConnections() {
    return const Center(child: Text("Connections"),);
  }

  TextStyle getTabStyle(int index) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: _currentTab == index ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary.withOpacity(0.5)
    );
  }
  Widget buildUserPhoto(UserModel user) {
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
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                width: 150,
                height: 150,
              ),
            ),
          ),
        )
      ),
    );
  }

}