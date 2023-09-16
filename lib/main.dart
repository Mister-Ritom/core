import 'package:core/providers/user_provider.dart';
import 'package:core/ui/pages/introduction_page.dart';
import 'package:core/ui/parent_page.dart';
import 'package:core/providers/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  //check if all widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );
  runApp(
    const MyApp(),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: ChangeNotifierProvider<ThemeChanger>(
        create: (_) => ThemeChanger(ThemeMode.system),
        child: const MaterialAppWithTheme(),
      ),
    );
  }
}

class MaterialAppWithTheme extends StatelessWidget {
  const MaterialAppWithTheme({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeChanger>(context);
    final userProvider = Provider.of<AuthProvider>(context);
    return MaterialApp(
      home: userProvider.user!=null?const Home(): const IntroductionPage(),
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          enableFeedback: true,
          backgroundColor: Colors.white54,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.black38,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        bottomNavigationBarTheme:  const BottomNavigationBarThemeData(
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          enableFeedback: true,
          backgroundColor: Colors.black45,
          selectedItemColor: Colors.lightBlue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: theme.getTheme(),
    );
  }
}