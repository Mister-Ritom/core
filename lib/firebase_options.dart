// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGJQyTMAifWvM3fs2_7aTP3D5UfUeLYao',
    appId: '1:357937556372:web:fce5385c00929b4441fd81',
    messagingSenderId: '357937556372',
    projectId: 'core-blaze',
    authDomain: 'core-blaze.firebaseapp.com',
    storageBucket: 'core-blaze.appspot.com',
    measurementId: 'G-DDJ422RRYV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmpdeyTdhnGoqdy4cdoa3bZT1kK7j8CAM',
    appId: '1:357937556372:android:b0b127f69c2d962341fd81',
    messagingSenderId: '357937556372',
    projectId: 'core-blaze',
    storageBucket: 'core-blaze.appspot.com'
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBo3XFuV8zhrKD4pVEUhdNY-9FISk5WZ-Q',
    iosBundleId: 'site.ritom.core',
    appId: '1:357937556372:ios:c3ecc789b24b6b5241fd81',
    storageBucket: 'core-blaze.appspot.com',
    messagingSenderId: '357937556372',
    iosClientId: '357937556372-uqid78qt0vanpbknpehh3lheamptc20i.apps.googleusercontent.com',
    projectId: 'core-blaze'
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBo3XFuV8zhrKD4pVEUhdNY-9FISk5WZ-Q',
    appId: '1:357937556372:ios:ab83907ad6a3249041fd81',
    messagingSenderId: '357937556372',
    projectId: 'core-blaze',
    storageBucket: 'core-blaze.appspot.com',
    androidClientId: '357937556372-rgk14dnfresmbaprnt5j4niejmbquija.apps.googleusercontent.com',
    iosClientId: '357937556372-vttjdn9e9gnmqqt8khemukug6a6j9jp0.apps.googleusercontent.com',
    iosBundleId: 'site.ritom.core.RunnerTests',
  );
}
