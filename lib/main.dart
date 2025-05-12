import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/screens/admin/add_watch_screen.dart';
import 'package:watch_hub/screens/admin/admin_home_screen.dart';
import 'package:watch_hub/screens/admin/edit_watch_screen.dart';
import 'package:watch_hub/screens/admin/watch_screen.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/screens/base/signup_screen.dart';
import 'package:watch_hub/screens/base/splash_screen.dart';
import 'package:watch_hub/screens/user/profile_screen.dart';
import 'package:watch_hub/screens/user/user_home_screen.dart';
import 'package:watch_hub/screens/user/wishlist_screen.dart';
import 'package:watch_hub/services/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCvg1_WWShLO09l-fMG9nQg5333YQIDl1k',
        appId: '1:883631800883:android:e27cdf595a623674c29946',
        messagingSenderId: '883631800883',
        projectId: 'watch-hub-1f030',
        storageBucket: 'watch-hub-1f030.firebasestorage.app',
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch Hub',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      initialRoute: '/',
      routes: {
        // base routes
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthPage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        // user routes
        '/user_home': (context) => UserHomeScreen(),
        '/user_wishlist': (context) => WishlistScreen(),
        '/user_profile': (context) => ProfileScreen(),
        // admin routes
        '/admin_home': (context) => AdminHomeScreen(),
        '/admin_watch': (context) => WatchScreen(),
        '/admin_add_watch': (context) => AddWatchScreen(),
      },
    );
  }
}
