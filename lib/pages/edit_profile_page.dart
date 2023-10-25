import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text("Something went wrong");
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Column(
        children: [
          Center(
            child: CircleAvatar(
              child: Image.network(user.photoURL ??
                  "https://firebasestorage.googleapis.com/v0/b/core-blaze.appspot.com/o/image_processing20200512-26746-1t9kpjd.png?alt=media&token=22ebad12-adfd-49d9-bbf4-257498adc9a1&_gl=1*1b400hp*_ga*MjAzMTcwNDUzLjE2OTQxNDcyNjA.*_ga_CW55HF8NVT*MTY5ODI0NTQwOC4zNS4xLjE2OTgyNDU0NDUuMjMuMC4w"),
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Name ",
              hintText: user.displayName ?? "Your name",
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Email",
              hintText: user.email ?? "Your email",
            ),
          ),
        ],
      ),
    );
  }
}
