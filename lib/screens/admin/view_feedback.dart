import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/components/format_date.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/services/feedback_service.dart';

class ViewFeedback extends StatefulWidget {
  const ViewFeedback({super.key});

  @override
  State<ViewFeedback> createState() => _ViewFeedbackState();
}

class _ViewFeedbackState extends State<ViewFeedback>
    with SingleTickerProviderStateMixin {
  // Service
  final FeedbackService _feedbackService = FeedbackService();

  // Filter state
  String _filterType = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest';

  // Animation controller
  late AnimationController _animationController;

  // Feedback types and their colors
  final Map<String, Color> _feedbackTypeColors = {
    'Bug Report': Colors.red,
    'Feature Request': Colors.blue,
    'Suggestion': Colors.green,
    'Complaint': Colors.orange,
    'Praise': Colors.purple,
    'Other': Colors.grey,
  };

  // Get all unique feedback types
  List<String> get _feedbackTypes => ['All', ..._feedbackTypeColors.keys];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Filter feedback based on type and search query
  bool _filterFeedback(DocumentSnapshot feedback) {
    final type = feedback['feedbackType'] ?? 'Other';
    final text = feedback['feedbackText'] ?? '';
    final userName = feedback['userName'] ?? '';

    final matchesType = _filterType == 'All' || type == _filterType;
    final matchesSearch =
        _searchQuery.isEmpty ||
        text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        userName.toLowerCase().contains(_searchQuery.toLowerCase());

    return matchesType && matchesSearch;
  }

  // Sort feedback
  List<DocumentSnapshot> _sortFeedback(List<DocumentSnapshot> feedbackList) {
    switch (_sortBy) {
      case 'Newest':
        feedbackList.sort(
          (a, b) => (b['timestamp'] as Timestamp).compareTo(
            a['timestamp'] as Timestamp,
          ),
        );
        break;
      case 'Oldest':
        feedbackList.sort(
          (a, b) => (a['timestamp'] as Timestamp).compareTo(
            b['timestamp'] as Timestamp,
          ),
        );
        break;
      case 'Type':
        feedbackList.sort(
          (a, b) =>
              (a['feedbackType'] ?? '').compareTo(b['feedbackType'] ?? ''),
        );
        break;
    }
    return feedbackList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'Newest',
                    child: Text('Sort by Newest'),
                  ),
                  const PopupMenuItem(
                    value: 'Oldest',
                    child: Text('Sort by Oldest'),
                  ),
                  const PopupMenuItem(
                    value: 'Type',
                    child: Text('Sort by Type'),
                  ),
                ],
          ),
        ],
      ),
      drawer: const AdminDrawer(selectedIndex: 2),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  _feedbackTypes.map((type) {
                    final isSelected = _filterType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(type),
                        onSelected: (selected) {
                          setState(() {
                            _filterType = type;
                          });
                        },
                        backgroundColor: theme.cardColor,
                        selectedColor:
                            type == 'All'
                                ? theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                )
                                : (_feedbackTypeColors[type] ?? Colors.grey)
                                    .withValues(alpha: 0.2),
                        checkmarkColor:
                            type == 'All'
                                ? theme.colorScheme.primary
                                : _feedbackTypeColors[type] ?? Colors.grey,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? (type == 'All'
                                      ? theme.colorScheme.primary
                                      : _feedbackTypeColors[type] ??
                                          Colors.grey)
                                  : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Search bar (if search is active)
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search: "$_searchQuery"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Feedback list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _feedbackService.getFeedback(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error fetching feedback',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          onPressed: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No feedback available',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When customers provide feedback, it will appear here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter and sort feedback
                final filteredDocs =
                    snapshot.data!.docs.where(_filterFeedback).toList();

                final sortedDocs = _sortFeedback(filteredDocs);

                if (sortedDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching feedback',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your filters or search query.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Filters'),
                          onPressed: () {
                            setState(() {
                              _filterType = 'All';
                              _searchQuery = '';
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }

                return AnimatedList(
                  initialItemCount: sortedDocs.length,
                  itemBuilder: (context, index, animation) {
                    final feedback = sortedDocs[index];
                    final type = feedback['feedbackType'] ?? 'Other';
                    final text = feedback['feedbackText'] ?? '';
                    final userName = feedback['userName'] ?? 'Anonymous';
                    final userEmail = feedback['userEmail'] ?? '';
                    final timestamp =
                        feedback['timestamp'] as Timestamp? ??
                        Timestamp.fromDate(DateTime.now());
                    final isResolved = feedback['isResolved'] ?? false;

                    return _buildFeedbackCard(
                      animation,
                      feedback.id,
                      type,
                      text,
                      userName,
                      userEmail,
                      timestamp,
                      isResolved,
                      theme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh the feedback list
          setState(() {});
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFeedbackCard(
    Animation<double> animation,
    String id,
    String type,
    String text,
    String userName,
    String userEmail,
    Timestamp timestamp,
    bool isResolved,
    ThemeData theme,
  ) {
    final typeColor = _feedbackTypeColors[type] ?? Colors.grey;

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isResolved
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: isResolved ? 1 : 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and timestamp
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getIconForType(type),
                                size: 16,
                                color: typeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                type,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isResolved)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Resolved',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      formatTimestampToTimeAgo(timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feedback content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: typeColor.withValues(alpha: 0.2),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (userEmail.isNotEmpty)
                              Text(
                                userEmail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        isResolved ? Icons.unpublished : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        isResolved ? 'Mark Unresolved' : 'Mark Resolved',
                      ),
                      onPressed: () {
                        // Toggle resolved status
                        _feedbackService.updateFeedbackStatus(id, !isResolved);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Reply'),
                      onPressed: () {
                        // Show reply dialog
                        _showReplyDialog(id, userName, userEmail);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  void _showReplyDialog(String feedbackId, String userName, String userEmail) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reply to $userName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Email: $userEmail',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                TextField(
                  controller: replyController,
                  decoration: const InputDecoration(
                    hintText: 'Type your reply...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Send reply (implement this in your feedback service)
                  await _feedbackService.sendReply(
                    feedbackId,
                    replyController.text,
                    userEmail,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    showSnackBar(
                      context,
                      "Reply sent successfully",
                      type: SnackBarType.success,
                    );
                  }
                },
                child: const Text('Send Reply'),
              ),
            ],
          ),
    );
  }
}
