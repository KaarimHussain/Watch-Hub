import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/login.model.dart';
import 'package:watch_hub/models/signup.model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as dev;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(SignupModel signupModel) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: signupModel.email,
            password: signupModel.password,
          );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': signupModel.name,
          'email': signupModel.email,
          'role': signupModel.role,
          'address': signupModel.address ?? '',
          'createdAt': signupModel.createdAt,
        });
        return user;
      }
    } catch (e) {
      dev.log("Signup Error: $e");
      rethrow;
    }
    return null;
  }

  // Login
  Future<User?> login(
    BuildContext context,
    LoginModel loginModel,
    bool rememberMe,
  ) async {
    try {
      // First set persistence
      if (kIsWeb) {
        await _auth.setPersistence(
          rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      // Then sign in
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: loginModel.email,
            password: loginModel.password,
          );
      // Save rememberMe preference
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);
      return userCredential.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      return null;
    }
  }

  Future<User?> adminLogin(
    BuildContext context,
    LoginModel loginModel,
    bool rememberMe,
  ) async {
    try {
      debugPrint("Before persistence setting");
      if (kIsWeb) {
        await _auth.setPersistence(
          rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      debugPrint("After persistence setting");
      debugPrint("Admin Login Model: $loginModel");
      // Fixed admin credentials
      const String adminEmail = 'admin@watchhub.com';
      const String adminPassword = 'admin123';

      if (loginModel.email == adminEmail &&
          loginModel.password == adminPassword) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', rememberMe);
        await prefs.setBool('isAdmin', true);

        debugPrint("Admin Credentials Matched");
      } else {
        throw Exception('Invalid admin credentials');
      }
    } catch (e) {
      debugPrint("Admin Login Error: $e");
      rethrow;
    }
    return null;
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await prefs.remove('isAdmin');
    showSnackBar(
      context,
      'Logged out successfully',
      type: SnackBarType.success,
    );
  }

  // Get current user
  User? getCurrentUser() => _auth.currentUser;

  // Check session state
  Future<bool> isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    final user = _auth.currentUser;
    return rememberMe && user != null;
  }
}
