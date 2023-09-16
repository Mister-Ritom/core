import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/utils/models/story_model.dart';
import 'package:core/utils/models/user_model.dart';
import 'package:flutter/material.dart';

class SmallStoryWidget extends StatefulWidget {

  final List<Story> stories;
  const SmallStoryWidget({super.key, required this.stories});

  @override
  State<StatefulWidget> createState()=> _StoryState();

}
class _StoryState extends State<SmallStoryWidget> {
  @override
  Widget build(BuildContext context) {
    final story = widget.stories[0];
    return Container(
      width: 92,
      height: 102,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary,width: 1),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Stack(
        children: [
          if (story.image!=null)
            Center(child: Image.network(
              story.image!,
              fit: BoxFit.cover,
              width: 92,
              height: 100,)
            ),
          createStoryInfo(),
        ],
      ),
    );
  }

  Widget createStoryInfo() {
    final story = widget.stories[0];
    return FutureBuilder<UserModel>(
      future: getUser(),
      builder: (context,snapshot){
        if (snapshot.hasError){
          return const Center(child: Text("Something went wrong"),);
        }
        if (snapshot.connectionState==ConnectionState.done) {
          if (snapshot.hasData){
            final user = snapshot.data!;
            return story.caption!=null?buildCaptionStack(story,user)
                :buildUserStack(user);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget buildCaptionStack(Story story,UserModel user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (user.photoUrl!=null) Row(
          children: [
            CircleAvatar(
              radius: 7,
              foregroundImage: NetworkImage(user.photoUrl!),
            ),
            Text(
              user.name,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ) else Text(
          user.name,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          story.caption!,
          maxLines: 2,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget buildUserStack(user) {
    if (user.photoUrl!=null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            radius: 7,
            foregroundImage: NetworkImage(user.photoUrl!),
          ),
          Text(
            user.name,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
        return Text(
        user.name,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Future<UserModel> getUser() async {
    final userCol = FirebaseFirestore.instance.collection('users')
        .doc(widget.stories[0].uploaderId);
    return userCol.get().then((doc) =>
        UserModel.fromJson(doc.data() as Map<String, dynamic>));
  }

}