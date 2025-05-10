import 'package:cloud_firestore/cloud_firestore.dart';

class SignupModel {
  final String name;
  final String email;
  final String password;
  final String? address;
  final String role;
  final Timestamp createdAt;

  SignupModel({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.address,
    required this.createdAt,
  });
}
