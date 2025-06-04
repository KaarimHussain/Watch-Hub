import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:watch_hub/components/logo.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/login.model.dart';
import 'package:watch_hub/screens/base/forget_password_screen.dart';
import 'package:watch_hub/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Auth
  final AuthService _auth = AuthService();
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Controller Property
  bool _obscurePassword = true;
  bool _rememberMe = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Canvas

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);

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
                      // Logo and brand
                      Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Watch logo
                              logoComponent(),
                              const SizedBox(height: 16),
                              Text(
                                'WATCH HUB',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Welcome text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Welcome back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Login to continue',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email field
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password field
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

                      const SizedBox(height: 16),

                      // Remember me and forgot password
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember me
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),

                            // Forgot password
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ],
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
                            onPressed: _isLoading ? null : _handleLogin,
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
                                      'Login',
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

                      // Create account button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              );
                            },
                            child: const Text(
                              'Create an Account',
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

  // Building UI

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

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Validation
      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Please fill in all fields');
        return;
      }

      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _showSnackBar('Invalid email format');
        return;
      }

      LoginModel loginModel = LoginModel(email: email, password: password);

      // Admin login check
      if (email == 'admin@watchhub.com' && password == 'admin123') {
        await _auth.adminLogin(context, loginModel, _rememberMe);
        if (mounted) Navigator.pushReplacementNamed(context, '/admin_home');
      }
      // Regular user login
      else {
        final User? user = await _auth.login(context, loginModel, _rememberMe);
        if (user != null && mounted) {
          if (user.emailVerified) {
            Navigator.pushReplacementNamed(context, '/user_index');
          } else {
            showSnackBar(
              context,
              "Please verify your email to complete the registration",
              type: SnackBarType.info,
            );
          }
        } else {
          _showSnackBar(
            'Login failed. Please check your credentials.',
            isError: true,
          );
        }
      }
    } catch (e) {
      _showSnackBar(
        'An error occurred during login: ${e.toString()}',
        isError: true,
      );
      _getFriendlyError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        return 'Too many login attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }
}
