import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub/screens/admin/admin_home_screen.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/screens/user/index_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _rememberMe = false;
  bool _isAdmin = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    debugPrint("Checking login status");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('rememberMe') ?? false;
    _isAdmin = prefs.getBool('isAdmin') ?? false;
    _user = _auth.currentUser;
    debugPrint(
      "RememberMe: $_rememberMe, IsAdmin: $_isAdmin, User: ${_user?.uid}",
    );

    if (!_rememberMe || _user == null) {
      // Clear session if not remembered
      await _auth.signOut();
      _user = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building AuthPage");

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isAdmin) {
      debugPrint("Admin user detected from shared preferences");
      return const AdminHomeScreen();
    }

    if (_user == null) {
      debugPrint("User is null, showing login screen");
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(_user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasData) {
          final doc = snapshot.data!;
          if (!doc.exists) {
            // Create a new user document with default data
            _firestore.collection('users').doc(_user!.uid).set({
              'role': 'User',
              'createdAt': Timestamp.now(),
              'email': _user!.email,
            }, SetOptions(merge: true));
            debugPrint("Created new user document in Firestore");
            return const IndexScreen();
          }

          final String role = doc.get('role');
          debugPrint("Firestore role: $role");
          if (role == 'Admin') {
            return const AdminHomeScreen();
          } else {
            return const IndexScreen();
          }
        }

        debugPrint("Error fetching user role, fallback to login");
        return const LoginScreen();
      },
    );
  }
}
