import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/pages/user_sign_page/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../utils/models/user_model.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _submitForm() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pop(context);
    }
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();
    signIn(2);
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

  Future<UserCredential> signInWithEmail() async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> signIn(int provider) async {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pop(context);
    }
    try {
      UserCredential userCredential;
      switch (provider) {
        case 0:
          userCredential = await signInWithGoogle();
          break;
        case 1:
          userCredential = await signInWithGitHub();
          break;
        case 2:
          userCredential = await signInWithEmail();
          break;
        default:
          userCredential = await signInWithEmail();
      }

      //check if user is new
      if (userCredential.additionalUserInfo!.isNewUser) {
        final email = _emailController.text;
        final firstName = _firstNameController.text;
        final lastName = _lastNameController.text;
        if (userCredential.user != null) {
          if (userCredential.user!.displayName == null) {
            await userCredential.user!
                .updateDisplayName('$firstName $lastName');
          }
          if (userCredential.user!.photoURL == null) {
            await userCredential.user!.updatePhotoURL(
                'https://firebasestorage.googleapis.com/v0/b/core-blaze.appspot.com/o/image_processing20200512-26746-1t9kpjd.png?alt=media&token=22ebad12-adfd-49d9-bbf4-257498adc9a1');
          }
          final userModel = UserModel(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? '$firstName $lastName',
            username: userCredential.user!.email ?? email,
            email: userCredential.user!.email ?? email,
            photoUrl: userCredential.user!.photoURL ??
                'https://firebasestorage.googleapis.com/v0/b/core-blaze.appspot.com/o/image_processing20200512-26746-1t9kpjd.png?alt=media&token=22ebad12-adfd-49d9-bbf4-257498adc9a1',
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userModel.toJson());
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully.'),
            ),
          );
          Provider.of<AuthProvider>(context)
              .setUser(FirebaseAuth.instance.currentUser);
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The password provided is too weak.'),
            ),
          );
        }
      } else if (e.code == 'email-already-in-use') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The account already exists for that email.'),
            ),
          );
        }
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset("assets/Core.webp", height: 125, width: 125),
            Text("Sign up to Core",
                style: Theme.of(context).textTheme.titleLarge),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: buildCustomTextField(
                                  'First Name',
                                  FontAwesomeIcons.signature,
                                  _firstNameController),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildCustomTextField(
                                  'Last Name',
                                  FontAwesomeIcons.addressBook,
                                  _lastNameController),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        buildCustomTextField('Email', FontAwesomeIcons.envelope,
                            _emailController),
                        const SizedBox(height: 10),
                        buildCustomTextField('Password', FontAwesomeIcons.lock,
                            _passwordController),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(FontAwesomeIcons.fireFlameCurved),
                                Text('Sign up'),
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
            Text(
              "By signing up, you agree to our Terms of Use and Privacy Policy.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            buildNextPage(),
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

  TextButton buildNextPage() {
    return TextButton(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignInPage()));
      },
      child: const Text('Already have an account? Login'),
    );
  }
}
