import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggedIn = false;
  bool _rememberMe = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('rememberMe') ?? false;

    try {
      await _auth.setPersistence(
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    } catch (e) {
      print("Persistence error: $e");
    }

    _isLoggedIn = _rememberMe && _auth.currentUser != null;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberMe', _rememberMe);
    notifyListeners();
  }

  void updateLoginState(bool loggedIn) {
    _isLoggedIn = loggedIn;
    notifyListeners();
  }

  void logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('rememberMe');
    _isLoggedIn = false;
    notifyListeners();
  }
}
