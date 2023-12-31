import 'package:core/pages/user_sign_page/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 12,
          title: const Text('Core'),
          centerTitle: true,
          leading: Image.asset('assets/Core.webp', height: 42),
          toolbarHeight: 48,
        ),
        body: IntroductionScreen(
          pages: [
            PageViewModel(
              title: "Welcome to Core",
              body:
                  "Core is a social media platform that allows you to connect with your friends and family.",
              image: Center(
                child: Image.asset(
                  'assets/Core.webp',
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            PageViewModel(
              title: "Create a profile",
              body:
                  "Create a profile and share your interests, hobbies, and more.",
              image: Center(
                child: Image.asset(
                  'assets/Realme-10-Core-Post.png',
                  height: 400,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            PageViewModel(
              title: "Connect with friends",
              body:
                  "Connect with your friends around the world without worrying about softwares.",
              image: Center(
                child: Image.asset(
                  'assets/iPhone 14 Pro.png',
                  height: 400,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            //Another page for telling users about the media posts
            PageViewModel(
              title: "Share your interests",
              body: "Share your interests with your preferred media.",
              image: Center(
                child: Image.asset(
                  'assets/iPhone_12_Pro-Intro.png',
                  height: 300,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
          ],
          dotsDecorator: DotsDecorator(
              activeColor: Theme.of(context).colorScheme.primary,
              size: const Size.square(10.0),
              activeSize: const Size(20.0, 10.0),
              activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0))),
          showSkipButton: true,
          showNextButton: false,
          done: const Text("Join friends"),
          skip: const Text("Skip"),
          onSkip: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupPage(),
              ),
            );
          },
          onDone: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupPage(),
              ),
            );
          },
        ));
  }
}
