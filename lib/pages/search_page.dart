import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/ui/pages/user_details_page.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _HomeState();
}
class _HomeState extends State<UserPage> {

  var query = "";

  Future<List<UserModel>> _searchCreator() async {
    //create a firestore query with query string
    if (query.isNotEmpty) {
      //if query is not empty, search for users
      final users = await FirebaseFirestore.instance.
      collection('users').orderBy("username").startAt([query])
          .endAt(['$query\uf8ff']).get();
      //convert the user documents to user models
      return users.docs.map((user) => UserModel.fromJson(user.data())).toList();
    }
    //if query is empty, return empty list
    return [];
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
                  query = value;
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
              const Center(child: Text('Posts')),
              buildCreatorSearch(context),
              const Center(child: Text('Chats')),
            ],
          ),
      )
    );
  }

}