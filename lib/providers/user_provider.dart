import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  void setUser(User? user) {
    _user = user;
    notifyListeners();
    if (user != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e, s) {
      debugPrint(e.toString());
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }
}
