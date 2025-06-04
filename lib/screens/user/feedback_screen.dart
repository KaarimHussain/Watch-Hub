import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/feedback.model.dart';
import 'package:watch_hub/services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final FeedbackService _feedbackService = FeedbackService();

  // Form
  final _formKey = GlobalKey<FormState>();
  String _feedbackType = 'Suggestion';

  // Updated feedback types to match admin view
  final List<String> _feedbackTypes = [
    'Bug Report',
    'Feature Request',
    'Suggestion',
    'Complaint',
    'Praise',
    'Other',
  ];

  // Controllers
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // State Manager
  bool _isLoading = false;
  bool _isSubmitted = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Get icon for feedback type
  IconData _getIconForType(String type) {
    switch (type) {
      case 'Bug Report':
        return Icons.bug_report;
      case 'Feature Request':
        return Icons.lightbulb;
      case 'Suggestion':
        return Icons.tips_and_updates;
      case 'Complaint':
        return Icons.thumb_down;
      case 'Praise':
        return Icons.thumb_up;
      default:
        return Icons.feedback;
    }
  }

  // Get color for feedback type
  Color _getColorForType(String type) {
    switch (type) {
      case 'Bug Report':
        return Colors.red;
      case 'Feature Request':
        return Colors.blue;
      case 'Suggestion':
        return Colors.green;
      case 'Complaint':
        return Colors.orange;
      case 'Praise':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitFeedback() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _feedbackService.addFeedback(
        FeedbackModel(
          feedbackType: _feedbackType,
          feedbackText: _feedbackController.text,
          userName: _nameController.text,
          userEmail: _emailController.text,
          timestamp: Timestamp.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });

        // Reset form after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(
          context,
          'Error submitting feedback: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkGray = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Cal_Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body:
          _isSubmitted
              ? _buildSuccessView(theme)
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with illustration
                          Center(
                            child: Column(
                              children: [
                                // Illustration
                                Container(
                                  height: 160,
                                  width: 160,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.rate_review_outlined,
                                    size: 80,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  'We Value Your Feedback',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontFamily: 'Cal_Sans',
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    'Your feedback helps us improve our products and services. We appreciate your time!',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      color: theme.colorScheme.onBackground
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),

                          // Feedback Type Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 20,
                                      color: darkGray,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Feedback Type",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: darkGray,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Feedback Type Selection - Improved UI
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _feedbackTypes.length,
                                    itemBuilder: (context, index) {
                                      final type = _feedbackTypes[index];
                                      final isSelected = _feedbackType == type;
                                      final color = _getColorForType(type);

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _feedbackType = type;
                                          });
                                        },
                                        child: Container(
                                          width: 100,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? color.withOpacity(0.1)
                                                    : theme
                                                        .colorScheme
                                                        .background,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? color
                                                      : theme.dividerColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? color.withOpacity(
                                                            0.2,
                                                          )
                                                          : theme
                                                              .colorScheme
                                                              .background,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _getIconForType(type),
                                                  color:
                                                      isSelected
                                                          ? color
                                                          : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.7),
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                type,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          isSelected
                                                              ? color
                                                              : theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Feedback Content Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getIconForType(_feedbackType),
                                      size: 20,
                                      color: _getColorForType(_feedbackType),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Your $_feedbackType",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: _getColorForType(
                                              _feedbackType,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Feedback Field - Improved UI
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getColorForType(
                                        _feedbackType,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your feedback';
                                      }
                                      return null;
                                    },
                                    maxLines: 5,
                                    controller: _feedbackController,
                                    decoration: InputDecoration(
                                      hintText: _getHintTextForType(
                                        _feedbackType,
                                      ),
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Contact Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.contact_mail_outlined,
                                      size: 20,
                                      color: darkGray,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Contact Information",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: darkGray,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Name Field
                                _buildTextField(
                                  controller: _nameController,
                                  hintText: 'Your Name',
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email Field
                                _buildTextField(
                                  controller: _emailController,
                                  hintText: 'Email Address',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    } else if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit Button - Improved UI
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () {
                                        if (_formKey.currentState!.validate()) {
                                          _submitFeedback();
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _getColorForType(
                                  _feedbackType,
                                ),
                                elevation: 2,
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send_rounded, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Submit Feedback',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  // Success view shown after submission
  Widget _buildSuccessView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Thank You!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cal_Sans',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your feedback has been submitted successfully. We appreciate your input!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Return to App'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: theme.colorScheme.primary.withOpacity(0.7),
            size: 20,
          ),
        ),
      ),
    );
  }

  // Get hint text based on feedback type
  String _getHintTextForType(String type) {
    switch (type) {
      case 'Bug Report':
        return 'Please describe the issue in detail. What happened? What did you expect to happen?';
      case 'Feature Request':
        return 'What feature would you like to see added? How would it benefit you?';
      case 'Suggestion':
        return 'How can we improve our product or service? We value your suggestions!';
      case 'Complaint':
        return 'We\'re sorry you\'re having issues. Please tell us what went wrong...';
      case 'Praise':
        return 'Thank you for your positive feedback! Tell us what you enjoyed...';
      default:
        return 'Please share your thoughts with us...';
    }
  }
}
