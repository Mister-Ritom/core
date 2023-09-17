import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/pages/home_page.dart';
import 'package:core/pages/search_page.dart';
import 'package:core/ui/pages/introduction_page.dart';
import 'package:core/ui/pages/user_details_page.dart';
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

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  void uploadPost(Post post, File? file) async {
    //This is used here so even if the user navigates away from the page
    // While the post is uploading, it will not stop midway
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
  final controller = PageController();

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
      icon: FirebaseAuth.instance.currentUser != null &&
              FirebaseAuth.instance.currentUser!.photoURL != null
          ? CircleAvatar(
              radius: 17,
              backgroundImage:
                  NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!),
            )
          : const Icon(FontAwesomeIcons.circleUser),
      label: 'Profile',
      page: UserDetails(
        key: const ValueKey<int>(3),
        user: FirebaseAuth.instance.currentUser!.uid,
        showAppbar: false,
      ),
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
    final userProvider = Provider.of<AuthProvider>(context);
    if (userProvider.user == null) {
      return const IntroductionPage();
    }
    return buildParentPage();
  }

  Scaffold buildParentPage() {
    return Scaffold(
        appBar: AppBar(
          elevation: 12,
          title: Text(_buttons[_selectedIndex].label),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buttons[_selectedIndex].icon,
          ),
          actions: [getAction()],
          toolbarHeight: 48,
        ),
        body: PageView(
          controller: controller,
          children: _buttons.map((e) => e.page).toList(),
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
                });
                //Animate to page
                controller.jumpToPage(index);
              }
            },
          ),
        ));
  }
}
