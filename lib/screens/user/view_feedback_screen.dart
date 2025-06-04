import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/models/feedback.model.dart';
import 'package:watch_hub/services/feedback_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewFeedbackScreen extends StatefulWidget {
  const ViewFeedbackScreen({super.key});

  @override
  State<ViewFeedbackScreen> createState() => _ViewFeedbackScreenState();
}

class _ViewFeedbackScreenState extends State<ViewFeedbackScreen> {
  final _feedbackService = FeedbackService();
  final _scrollController = ScrollController();

  List<FeedbackModel> _feedbackList = [];
  bool _emailAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        setState(() {
          _emailAvailable = false;
          _isLoading = false;
        });
        return;
      }

      final feedbackList = await _feedbackService.getFeedbackList(email);
      setState(() {
        _feedbackList = feedbackList;
        _emailAvailable = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _emailAvailable = false;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(date)}, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Feedbacks"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_emailAvailable
              ? _buildErrorState(theme)
              : _feedbackList.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                onRefresh: _loadFeedback,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbackList.length,
                  itemBuilder: (context, index) {
                    final feedback = _feedbackList[index];
                    final hasReply =
                        feedback.adminReply != null &&
                        feedback.adminReply!.isNotEmpty;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? theme.cardColor : theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Feedback header with status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  hasReply
                                      ? theme.colorScheme.primary.withOpacity(
                                        0.1,
                                      )
                                      : theme.colorScheme.secondary.withOpacity(
                                        0.1,
                                      ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasReply
                                      ? Icons.mark_chat_read
                                      : Icons.mark_chat_unread,
                                  size: 20,
                                  color:
                                      hasReply
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasReply ? 'Replied' : 'Awaiting Reply',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        hasReply
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.secondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(feedback.timestamp.toDate()),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // User feedback content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary
                                          .withOpacity(0.2),
                                      child: Text(
                                        feedback.userName.isNotEmpty
                                            ? feedback.userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            feedback.userName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            'You',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  feedback.feedbackText,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),

                          // Admin reply section (if exists)
                          if (hasReply)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? theme.colorScheme.surface.withOpacity(
                                          0.5,
                                        )
                                        : theme.colorScheme.surface.withOpacity(
                                          0.5,
                                        ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: theme
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.2),
                                        child: const Icon(
                                          Icons.support_agent,
                                          color: Colors.deepPurple,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Admin Response',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              'WatchHub Support',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.deepPurple,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    feedback.adminReply ?? '',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000), // Pure black
                  Color(0xFF333333), // Dark gray
                  Color(0xFF555555), // Medium gray
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.feedback_outlined,
              size: 50,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),
          Text("No Feedbacks Yet", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "You haven't submitted any feedback yet",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to feedback submission screen
              Navigator.pushNamed(context, '/user_feedback');
            },
            icon: const Icon(Icons.add),
            label: const Text("Submit Feedback"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.warning_rounded,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text("Unable to fetch Feedbacks", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "Please sign in to view your feedbacks",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFeedback,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
