import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub/models/login.model.dart';
import 'package:watch_hub/models/signup.model.dart';

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
      print("Signup Error: $e");
      rethrow;
    }
    return null;
  }

  // Login
  Future<User?> login(LoginModel loginModel, bool rememberMe) async {
    try {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: loginModel.email,
            password: loginModel.password,
          );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
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
