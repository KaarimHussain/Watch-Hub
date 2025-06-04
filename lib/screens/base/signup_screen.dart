import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/components/logo.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/recent_activity.model.dart';
import 'package:watch_hub/models/signup.model.dart';
import 'package:watch_hub/services/auth_service.dart';
import 'package:watch_hub/services/recent_activity_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final AuthService _auth = AuthService();
  final RecentActivityService _recentActivityService = RecentActivityService();
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Controller Property
  bool _obscurePassword = true;
  // Animations Controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // State Management
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              logoComponent(),
                              const SizedBox(height: 16),
                              Text(
                                'WATCH HUB',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                  color: colorScheme.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Create an Account',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Signup to watch timepieces',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTextField(
                          controller: _nameController,
                          hintText: 'Name',
                          keyboardType: TextInputType.name,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: theme.iconTheme.color,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Sign in button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // OR divider
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: Divider(thickness: 1)),
                            const SizedBox(width: 5),
                            Text(
                              "OR",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text(
                              'Already have an account?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    // Use the theme from context
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hintText, suffixIcon: suffixIcon),
    );
  }
  // Backend Logic

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('All fields are required');
      setState(() => _isLoading = false);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('Invalid email format');
      setState(() => _isLoading = false);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      setState(() => _isLoading = false);
      return;
    }

    try {
      SignupModel user = SignupModel(
        name: name,
        email: email,
        password: password,
        role: 'User',
        createdAt: Timestamp.now(),
        verified: false,
      );

      await _auth.signUp(user);

      // Send email verification
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      await firebaseUser?.sendEmailVerification();

      showSnackBar(
        context,
        "Please verify your email to complete the registration, check your email for the verification link",
        type: SnackBarType.info,
      );
      sendRecentActivity(
        "User",
        "New User Added",
        "Welcome! ${name.toUpperCase()}",
        DateTime.now(),
      );
      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getFriendlyError(e.code);
      _showSnackBar(errorMessage);
      setState(() => _isLoading = false);
    }
  }

  // Error Handling

  void _showSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red[400] : Colors.green[400],
      duration: const Duration(seconds: 4),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _getFriendlyError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many signup attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Signup failed. Please check your credentials.';
    }
  }

  void sendRecentActivity(
    String type,
    String title,
    String description,
    DateTime timestamp,
  ) {
    RecentActivity userActivity = RecentActivity(
      type: type,
      title: title,
      description: description,
      timestamp: timestamp,
    );
    _recentActivityService.addRecentActivity(userActivity);
  }
}
