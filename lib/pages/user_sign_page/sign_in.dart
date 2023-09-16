import 'dart:developer';

import 'package:core/pages/user_sign_page/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _signIn() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in'),
          ),
        );
        Provider.of<AuthProvider>(context, listen: false)
            .setUser(FirebaseAuth.instance.currentUser);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        //show snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found for that email.'),
            ),
          );
        }
      } else if (e.code == 'wrong-password') {
        //show snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wrong password provided for that user.'),
            ),
          );
        }
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      log(e.toString(), stackTrace: s);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGitHub() async {
    // Create a new provider
    GithubAuthProvider githubProvider = GithubAuthProvider();

    return await FirebaseAuth.instance.signInWithProvider(githubProvider);
  }

  Future<void> signIn(int provider) async {
    try {
      switch (provider) {
        case 0:
          await signInWithGoogle();
          break;
        case 1:
          await signInWithGitHub();
          break;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in'),
          ),
        );
        Provider.of<AuthProvider>(context, listen: false)
            .setUser(FirebaseAuth.instance.currentUser);
        Navigator.pop(context);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
      log(e.toString(), stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset("assets/Core.webp", height: 200, width: 200),
            Text("Sign in to Core",
                style: Theme.of(context).textTheme.headlineMedium),
            //create a form for sign up
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.inverseSurface.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        buildCustomTextField('Email', FontAwesomeIcons.envelope,
                            _emailController),
                        const SizedBox(height: 10),
                        buildCustomTextField(
                          'Password',
                          FontAwesomeIcons.lock,
                          _passwordController,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _signIn,
                          child: const SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(FontAwesomeIcons.fireFlameSimple),
                                Text('Sign in'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text("Sign up with providers",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          signIn(0);
                        },
                        icon: const Icon(FontAwesomeIcons.google),
                      ),
                      IconButton(
                        onPressed: () {
                          signIn(1);
                        },
                        icon: const Icon(FontAwesomeIcons.github),
                      ),
                      IconButton(
                        onPressed: () {
                          //show snackbar that apple sign in is coming later in 2024
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Apple sign in is coming later in 2024'),
                            ),
                          );
                        },
                        icon: const Icon(FontAwesomeIcons.apple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            buildPreviousPage(),
          ],
        ),
      ),
    );
  }

  TextFormField buildCustomTextField(
      String hint, IconData icon, TextEditingController controller) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
      controller: controller,
      decoration: InputDecoration(
        icon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        labelText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  TextButton buildPreviousPage() {
    return TextButton(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignupPage()));
      },
      child: const Text('Don\'t have an account? Sign up'),
    );
  }
}
