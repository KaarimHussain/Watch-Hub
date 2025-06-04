import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/components/snackbar.component.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.watchId});
  // Watch ID Important Required
  final String? watchId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  // Loading State
  bool _isLoading = false;
  // Rating
  int _rating = 0;
  // Controllers
  final TextEditingController _reviewController = TextEditingController();
  // Collection Reference
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance
      .collection('reviews');

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "Write Review",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Cal_Sans',
                ),
              ),
              const SizedBox(height: 24),

              // Rating section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Rating",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color:
                                    index < _rating
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _rating > 0
                              ? "$_rating out of 5 stars"
                              : "Tap to rate",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                _rating > 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Review text field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Review",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        )
                        : ElevatedButton(
                          onPressed: () {
                            validateForm();
                          },
                          child: const Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isLoading = true); // Start loading
    await _reviewsCollection.add({
      'watchId': widget.watchId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'rating': _rating,
      'review': _reviewController.text.trim(),
      'createdAt': Timestamp.now(),
    });
    if (mounted) {
      showSnackBar(
        context,
        "Review submitted successfully!",
        type: SnackBarType.success,
      );
      Navigator.pop(context, true);
    }
    setState(() => _isLoading = false); // Stop loading
  }

  void validateForm() {
    if (_rating == 0) {
      showSnackBar(context, "Please select a rating", type: SnackBarType.error);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      showSnackBar(context, "Please write a review", type: SnackBarType.error);
      return;
    }

    if (widget.watchId == null) {
      showSnackBar(
        context,
        "Unable to fetch Watch ID! Try refreshing the app or try again.",
        type: SnackBarType.error,
      );
      return;
    }

    _submitReview();
  }
}
