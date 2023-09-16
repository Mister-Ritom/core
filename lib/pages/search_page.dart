import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/pages/user_details_page.dart';
import 'package:core/ui/widgets/small_image_post.dart';
import 'package:core/ui/widgets/small_text_post.dart';
import 'package:core/utils/models/post_model.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchState();
}
class _SearchState extends State<SearchPage> {

  var creatorQuery = "";
  var postQuery = "";

  Future<List<UserModel>> _searchCreator() async {
    //create a firestore query with query string
    if (creatorQuery.isNotEmpty) {
      //if query is not empty, search for users
      final users = await FirebaseFirestore.instance.
      collection('users').orderBy("username").startAt([creatorQuery])
          .endAt(['$creatorQuery\uf8ff']).limit(10).get();
      //convert the user documents to user models
      return users.docs.map((user) => UserModel.fromJson(user.data())).toList();
    }
    //if query is empty, return empty list
    return [];
  }

  Future<List<Post>> _searchPost() async {
    //create a firestore query with query string
    if (postQuery.isNotEmpty) {
      //if query is not empty, search for posts
      final posts = await FirebaseFirestore.instance.
      collection('posts').orderBy("caption").startAt([postQuery])
          .endAt(['$postQuery\uf8ff']).limit(25).get();
      //convert the post documents to post models
      return posts.docs.map((post) => Post.fromJson(post.data())).toList();
    }
    //if query is empty, return empty list
    return [];
  }

  Widget buildPostSearch(BuildContext context) {
    //return a column with a text field and a list view of posts
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 48,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  postQuery = value;
                });
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
                prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 18,),
              ),
            ),
          ),
        ),
        Expanded(
            child: FutureBuilder<List<Post>>(
              future: _searchPost(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final posts = snapshot.data!;
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      if (post.image==null) {
                        return SmallTextPost(post: post);
                      }
                      else {
                        return SmallImagePost(post: post);
                      }
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                return const Center(child: CircularProgressIndicator());
              },
            )
        )
      ],
    );
  }
  
  Widget buildCreatorSearch(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 48,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  creatorQuery = value;
                });
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
                prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 18,),
              ),
            ),
          ),
        ),
        Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _searchCreator(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                              builder: (context) { return UserDetails(user: user); }));
                        },
                        leading: user.photoUrl==null?null: CircleAvatar(
                          backgroundImage: NetworkImage(user.photoUrl!),
                        ),
                        title: Text(user.name),
                        subtitle: user.bio==null?null :
                        Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis,),
                        trailing: const Icon(FontAwesomeIcons.arrowRight),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                return const Center(child: CircularProgressIndicator());
              },
            )
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            primary: false,
            bottom: TabBar(
              dividerColor: Theme.of(context).colorScheme.inverseSurface,
              tabs: const [
                Tab(icon: Icon(FontAwesomeIcons.faceSmileWink), text: 'Posts',),
                Tab(icon: Icon(FontAwesomeIcons.user), text: 'Creators',),
                Tab(icon: Icon(FontAwesomeIcons.comment), text: 'Chats',),
              ],
            ),
            toolbarHeight: 0,
          ),
          body: TabBarView(
            children: [
             buildPostSearch(context),
              buildCreatorSearch(context),
              const Center(child: Text('Chats')),
            ],
          ),
      )
    );
  }

}