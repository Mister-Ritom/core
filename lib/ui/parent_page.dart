import 'package:core/pages/home_page.dart';
import 'package:core/pages/profile_page.dart';
import 'package:core/pages/user_group_page.dart';
import 'package:core/pages/user_sign_page/sign_in.dart';
import 'package:core/utils/models/nav_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../pages/chat_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  var _selectedIndex = 0;
  late PageController _controller;

  void _handlePageChange(int index) {
    print("Index $index");
    setState(() {
      _selectedIndex = index;
    });
  }

  final _buttons = [
    NavigationButton(
      icon: const Icon(Icons.home_outlined),
      label: 'Home',
      page: const HomePage()
    ),
    NavigationButton(
      icon: const Icon(Icons.group_outlined),
      label: 'Users',
      page: const UserPage(),
    ),
    NavigationButton(
      icon: const Icon(Icons.chat_bubble_outline),
      label: 'Chat',
      page: const ChatPage(),
    ),
    NavigationButton(
      icon: const Icon(Icons.person_outline),
      label: 'Profile',
      page: const ProfilePage(),
    ),
  ];

  void _onMenu() async {
    await showMenu(
        context: context,
        position: const RelativeRect.fromLTRB(100, 12, 0, 0),
        items: [
          PopupMenuItem(
            child: TextButton(
              onPressed: () {},
              child: const Text('Edit Profile', textAlign: TextAlign.center,),
            ),
          ),
          PopupMenuItem(
            child: TextButton(
              onPressed: () {},
              child: const Text('Settings', textAlign: TextAlign.center,),
            ),
          ),
          PopupMenuItem(
            child: TextButton(
              onPressed: () {},
              child: const Text('Help fund', textAlign: TextAlign.center,),
            ),
          ),
          PopupMenuItem(
            child: TextButton(
              onPressed: () {},
              child: const Text('Terms \n and conditions', textAlign: TextAlign.center,),
            ),
          ),
          PopupMenuItem(
            child: TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                }
              },
              child: const Text('Logout', textAlign: TextAlign.center,),
            ),
          ),
        ]
    );
  }

  @override
  void initState() {
    _controller = PageController(initialPage: 0,);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(),);
          }
          else {
            final user = snapshot.data;
            if (user == null) {
              //navigate to login page
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You are not logged in'),
                      const SizedBox(height: 16,),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Scaffold(
                appBar: AppBar(
                  title: Text(_buttons[_selectedIndex].label),
                  leading: Icon(_buttons[_selectedIndex].icon.icon,size: 32,),
                  actions: _selectedIndex==3? [
                    IconButton(
                      onPressed: _onMenu,
                      icon: const Icon(FontAwesomeIcons.ellipsisVertical,size: 20,),
                    ),] : null,
                  toolbarHeight: 48,
                ),
                //set to body to a page view with all the widgets
                body: PageView(
                  controller: _controller,
                  onPageChanged: _handlePageChange,
                  children: _buttons.map((e) => e.page).toList(),
                ),
                bottomNavigationBar: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 8.0),
                  clipBehavior: Clip.hardEdge,
                  //rounded shape
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    items:_buttons.map((e) =>
                        BottomNavigationBarItem(icon: e.icon, label: e.label)
                    ).toList(),
                    onTap: (index) {
                      _controller.jumpToPage(index);
                    },
                  ),
                )
            );
          }
        }
    );
  }
}