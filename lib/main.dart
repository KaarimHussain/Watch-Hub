import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/screens/base/signup_screen.dart';
import 'package:watch_hub/screens/base/splash_screen.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
