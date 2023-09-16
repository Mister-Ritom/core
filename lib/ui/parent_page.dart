import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/pages/home_page.dart';
import 'package:core/pages/profile_page.dart';
import 'package:core/pages/search_page.dart';
import 'package:core/utils/models/nav_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../pages/chat_page.dart';
import '../providers/user_provider.dart';
import '../utils/models/post_model.dart';
import 'dialog/create_dialog.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void uploadPost(Post post, File? file) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading post...'),
        ),
      );
    }
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final id = const Uuid().v4();
      String? imageUrl;
      if (file != null) {
        //post type is image
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child("posts")
            .child(userId)
            .child(id);
        final task = storageRef.putFile(file);
        final snapshot = await task.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          imageUrl = downloadUrl;
        });
      }
      final clonePost = post.copyWith(
        id: id,
        uploaderId: userId,
        image: imageUrl,
      );
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(id)
          .set(clonePost.toJson());
    } catch (e, s) {
      log("Failed to post", error: e, stackTrace: s);
      FirebaseCrashlytics.instance.recordError(e, s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload post'),
          ),
        );
      }
    }
  }

  var _selectedIndex = 0;
  Widget _currentPage = const HomePage(key: ValueKey<int>(0));

  final _buttons = [
    NavigationButton(
      icon: const Icon(Icons.home_outlined),
      label: 'Home',
      page: const HomePage(key: ValueKey<int>(0)),
    ),
    NavigationButton(
      icon: const Icon(FontAwesomeIcons.magnifyingGlass),
      label: 'Search',
      page: const SearchPage(key: ValueKey<int>(1)),
    ),
    NavigationButton(
      icon: const Icon(FontAwesomeIcons.bell),
      label: 'Notifications',
      page: const ChatPage(key: ValueKey<int>(2)),
    ),
    NavigationButton(
      icon: const Icon(FontAwesomeIcons.circleUser),
      label: 'Profile',
      page: const ProfilePage(key: ValueKey<int>(3)),
    ),
  ];

  Widget getAction() {
    if (_selectedIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: CircleAvatar(
          radius: 21,
          backgroundColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CreatePostDialog(
                    onSave: uploadPost,
                  );
                },
              );
            },
            icon: const Icon(FontAwesomeIcons.plus),
          ),
        ),
      );
    } else if (_selectedIndex == 3) {
      return PopupMenuButton(itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'edit_profile',
            child: Text('Edit Profile', textAlign: TextAlign.center),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Text('Settings', textAlign: TextAlign.center),
          ),
          PopupMenuItem(
            value: 'help_fund',
            child: Text('Help fund', textAlign: TextAlign.center),
          ),
          PopupMenuItem(
            value: 'terms_and_conditions',
            child: Text('Terms \n and conditions', textAlign: TextAlign.center),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Text('Logout', textAlign: TextAlign.center),
          ),
        ];
      }, onSelected: (value) async {
        if (value == 'logout') {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.signOut();
        }
      });
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 12,
          title: Text(_buttons[_selectedIndex].label),
          leading: Icon(
            _buttons[_selectedIndex].icon.icon,
            size: 32,
          ),
          actions: [getAction()],
          toolbarHeight: 48,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentPage,
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          clipBehavior: Clip.hardEdge,
          //rounded shape
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            items: _buttons
                .map((e) =>
                    BottomNavigationBarItem(icon: e.icon, label: e.label))
                .toList(),
            onTap: (index) {
              if (index != _selectedIndex) {
                setState(() {
                  _selectedIndex = index;
                  _currentPage = _buttons[index].page;
                });
              }
            },
          ),
        ));
  }
}
