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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: "Name ",
              hintText: user?.displayName ?? "Your name",
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Email",
              hintText: user?.email ?? "Your email",
            ),
          ),
        ],
      ),
    );
  }
}
