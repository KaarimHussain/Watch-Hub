import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivitiesScreen extends StatefulWidget {
  const RecentActivitiesScreen({super.key});

  @override
  State<RecentActivitiesScreen> createState() => _RecentActivitiesScreenState();
}

class _RecentActivitiesScreenState extends State<RecentActivitiesScreen>
    with TickerProviderStateMixin {
  // Theme colors from your app
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkGray = Color(0xFF343A40);
  static const Color mediumGray = Color(0xFF6C757D);
  static const Color lightGray = Color(0xFFCED4DA);
  static const Color accentGray = Color(0xFFADB5BD);

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Filter states
  String _selectedTypeFilter = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  String _sortBy = 'Newest First';

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<String> _typeFilters = [
    'All',
    'Watch Management',
    'Orders',
    'Users',
    'Collections',
    'Feedback',
    'System',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Type A-Z',
    'Type Z-A',
  ];

  // Activity type mappings
  final Map<String, List<String>> _activityTypeMap = {
    'Watch Management': ['add_watch', 'update_watch', 'delete_watch'],
    'Orders': [
      'new_order',
      'order_updated',
      'order_cancelled',
      'order_delivered',
    ],
    'Users': ['user_registered', 'user_updated', 'user_deleted'],
    'Collections': [
      'collection_created',
      'collection_updated',
      'collection_deleted',
    ],
    'Feedback': ['feedback_received', 'feedback_responded'],
    'System': ['system_update', 'backup_created', 'maintenance'],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Safe date parsing function
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  // Build query based on filters
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'recentActivity',
    );

    // Apply type filter
    if (_selectedTypeFilter != 'All') {
      final activityTypes = _activityTypeMap[_selectedTypeFilter] ?? [];
      if (activityTypes.isNotEmpty) {
        query = query.where('type', whereIn: activityTypes);
      }
    }

    // For date filtering, we'll handle it in the client side since we need to support both formats
    // Apply sorting - only use orderBy if no date filter is applied to avoid conflicts
    if (_selectedDateRange == null) {
      switch (_sortBy) {
        case 'Newest First':
          // Try to order by timestamp, but handle gracefully if field types are mixed
          query = query.orderBy('timestamp', descending: true);
          break;
        case 'Oldest First':
          query = query.orderBy('timestamp', descending: false);
          break;
        case 'Type A-Z':
          query = query.orderBy('type', descending: false);
          break;
        case 'Type Z-A':
          query = query.orderBy('type', descending: true);
          break;
      }
    }

    return query.limit(100); // Limit for performance
  }

  // Filter activities by search query and date range
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterActivities(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
  ) {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      activities =
          activities.where((activity) {
            final data = activity.data();
            final title = (data['title'] ?? '').toLowerCase();
            final description = (data['description'] ?? '').toLowerCase();
            final type = (data['type'] ?? '').toLowerCase();

            return title.contains(query) ||
                description.contains(query) ||
                type.contains(query);
          }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      activities =
          activities.where((activity) {
            final data = activity.data();
            final activityDate = _parseDate(data['timestamp']);

            if (activityDate == null) return false;

            final startDate = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final endDate = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
              23,
              59,
              59,
            );

            return activityDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                activityDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
    }

    // Apply sorting if date filter is active (since we couldn't use orderBy in query)
    if (_selectedDateRange != null) {
      switch (_sortBy) {
        case 'Newest First':
          activities.sort((a, b) {
            final dateA = _parseDate(a.data()['timestamp']);
            final dateB = _parseDate(b.data()['timestamp']);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });
          break;
        case 'Oldest First':
          activities.sort((a, b) {
            final dateA = _parseDate(a.data()['timestamp']);
            final dateB = _parseDate(b.data()['timestamp']);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });
          break;
        case 'Type A-Z':
          activities.sort(
            (a, b) =>
                (a.data()['type'] ?? '').compareTo(b.data()['type'] ?? ''),
          );
          break;
        case 'Type Z-A':
          activities.sort(
            (a, b) =>
                (b.data()['type'] ?? '').compareTo(a.data()['type'] ?? ''),
          );
          break;
      }
    }

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Recent Activities',
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGray),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Trigger rebuild to refresh data
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilterSummary(),
            Expanded(child: _buildActivitiesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSummary() {
    final hasActiveFilters =
        _selectedTypeFilter != 'All' ||
        _selectedDateRange != null ||
        _searchQuery.isNotEmpty ||
        _sortBy != 'Newest First';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search, color: mediumGray),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: mediumGray),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: darkGray),
              ),
              filled: true,
              fillColor: lightBackground,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Sort and filter summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Activities',
                  style: TextStyle(
                    color: mediumGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lightGray),
                ),
                child: DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 18, color: mediumGray),
                  style: const TextStyle(color: mediumGray, fontSize: 14),
                  items:
                      _sortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            // Active filters summary
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedTypeFilter != 'All')
                  _buildFilterChip('Type: $_selectedTypeFilter', () {
                    setState(() {
                      _selectedTypeFilter = 'All';
                    });
                  }),
                if (_selectedDateRange != null)
                  _buildFilterChip(
                    'Date: ${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                    () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  ),
                if (_sortBy != 'Newest First')
                  _buildFilterChip('Sort: $_sortBy', () {
                    setState(() {
                      _sortBy = 'Newest First';
                    });
                  }),
                // Clear all filters button
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(
                    Icons.clear_all,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: darkGray.withOpacity(0.1),
      deleteIconColor: darkGray,
      labelStyle: const TextStyle(color: darkGray),
    );
  }

  Widget _buildActivitiesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: darkGray),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final activities = _filterActivities(snapshot.data!.docs);

        if (activities.isEmpty) {
          return _buildNoResultsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              // Trigger rebuild to refresh data
            });
          },
          color: darkGray,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final data = activity.data();
              return _buildActivityCard(data, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data, int index) {
    final timestampValue = data['timestamp'];
    final activityDate = _parseDate(timestampValue);
    final type = data['type'] ?? '';
    final title = data['title'] ?? 'Unknown Activity';
    final description = data['description'] ?? '';
    final user = data['user'] ?? 'System';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showActivityDetails(data),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Activity icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getActivityColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getActivityIcon(type),
                    color: _getActivityColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Activity details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getActivityColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getActivityTypeLabel(type),
                              style: TextStyle(
                                color: _getActivityColor(type),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          style: const TextStyle(
                            color: mediumGray,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: accentGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user,
                            style: const TextStyle(
                              color: accentGray,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time, size: 14, color: accentGray),
                          const SizedBox(width: 4),
                          Text(
                            activityDate != null
                                ? _formatTimestamp(activityDate)
                                : 'Unknown time',
                            style: const TextStyle(
                              color: accentGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                const Icon(Icons.arrow_forward_ios, size: 16, color: lightGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    print(error);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading activities',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger rebuild to retry
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGray,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightGray.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history, size: 64, color: accentGray),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Activities Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Activities will appear here as they happen',
            style: TextStyle(color: mediumGray, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightGray.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 64, color: accentGray),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: mediumGray, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearAllFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGray,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _FilterBottomSheet(
            selectedTypeFilter: _selectedTypeFilter,
            selectedDateRange: _selectedDateRange,
            typeFilters: _typeFilters,
            onFiltersChanged: (typeFilter, dateRange) {
              setState(() {
                _selectedTypeFilter = typeFilter;
                _selectedDateRange = dateRange;
              });
            },
            onDateRangeSelect: _selectDateRange,
          ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: darkGray),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTypeFilter = 'All';
      _selectedDateRange = null;
      _searchQuery = '';
      _sortBy = 'Newest First';
      _searchController.clear();
    });
  }

  void _showActivityDetails(Map<String, dynamic> data) {
    final timestampValue = data['timestamp'];
    final activityDate = _parseDate(timestampValue);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  _getActivityIcon(data['type'] ?? ''),
                  color: _getActivityColor(data['type'] ?? ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'] ?? 'Activity Details',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['description'] != null &&
                    data['description'].isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(data['description']),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Type',
                  _getActivityTypeLabel(data['type'] ?? ''),
                ),
                _buildDetailRow('User', data['user'] ?? 'System'),
                _buildDetailRow(
                  'Time',
                  activityDate != null
                      ? _formatFullTimestamp(activityDate)
                      : 'Unknown',
                ),
                if (data['additionalInfo'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Additional Info', data['additionalInfo']),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: mediumGray, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: darkGray, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'add_watch':
      case 'update_watch':
      case 'delete_watch':
        return Icons.watch;
      case 'new_order':
      case 'order_updated':
      case 'order_cancelled':
      case 'order_delivered':
        return Icons.shopping_cart;
      case 'user_registered':
      case 'user_updated':
      case 'user_deleted':
        return Icons.person;
      case 'collection_created':
      case 'collection_updated':
      case 'collection_deleted':
        return Icons.collections;
      case 'feedback_received':
      case 'feedback_responded':
        return Icons.feedback;
      case 'system_update':
      case 'backup_created':
      case 'maintenance':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'add_watch':
      case 'collection_created':
      case 'user_registered':
        return Colors.green;
      case 'update_watch':
      case 'order_updated':
      case 'collection_updated':
      case 'user_updated':
        return Colors.blue;
      case 'delete_watch':
      case 'order_cancelled':
      case 'collection_deleted':
      case 'user_deleted':
        return Colors.red;
      case 'new_order':
      case 'order_delivered':
        return Colors.purple;
      case 'feedback_received':
      case 'feedback_responded':
        return Colors.orange;
      case 'system_update':
      case 'backup_created':
      case 'maintenance':
        return Colors.teal;
      default:
        return mediumGray;
    }
  }

  String _getActivityTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'add_watch':
        return 'WATCH ADDED';
      case 'update_watch':
        return 'WATCH UPDATED';
      case 'delete_watch':
        return 'WATCH DELETED';
      case 'new_order':
        return 'NEW ORDER';
      case 'order_updated':
        return 'ORDER UPDATED';
      case 'order_cancelled':
        return 'ORDER CANCELLED';
      case 'order_delivered':
        return 'ORDER DELIVERED';
      case 'user_registered':
        return 'USER REGISTERED';
      case 'user_updated':
        return 'USER UPDATED';
      case 'user_deleted':
        return 'USER DELETED';
      case 'collection_created':
        return 'COLLECTION CREATED';
      case 'collection_updated':
        return 'COLLECTION UPDATED';
      case 'collection_deleted':
        return 'COLLECTION DELETED';
      case 'feedback_received':
        return 'FEEDBACK RECEIVED';
      case 'feedback_responded':
        return 'FEEDBACK RESPONDED';
      case 'system_update':
        return 'SYSTEM UPDATE';
      case 'backup_created':
        return 'BACKUP CREATED';
      case 'maintenance':
        return 'MAINTENANCE';
      default:
        return type.toUpperCase();
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatFullTimestamp(DateTime date) {
    return DateFormat('MMM dd, yyyy at hh:mm a').format(date);
  }
}

// Filter bottom sheet widget
class _FilterBottomSheet extends StatefulWidget {
  final String selectedTypeFilter;
  final DateTimeRange? selectedDateRange;
  final List<String> typeFilters;
  final Function(String, DateTimeRange?) onFiltersChanged;
  final VoidCallback onDateRangeSelect;

  const _FilterBottomSheet({
    required this.selectedTypeFilter,
    required this.selectedDateRange,
    required this.typeFilters,
    required this.onFiltersChanged,
    required this.onDateRangeSelect,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _tempTypeFilter;
  late DateTimeRange? _tempDateRange;

  // Theme colors
  static const Color darkGray = Color(0xFF343A40);
  static const Color mediumGray = Color(0xFF6C757D);
  static const Color lightGray = Color(0xFFCED4DA);
  static const Color lightBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tempTypeFilter = widget.selectedTypeFilter;
    _tempDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: mediumGray),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Activity Type Filter
          const Text(
            'Activity Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                widget.typeFilters.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _tempTypeFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _tempTypeFilter = filter;
                      });
                    },
                    selectedColor: darkGray.withOpacity(0.1),
                    checkmarkColor: darkGray,
                    backgroundColor: lightBackground,
                    labelStyle: TextStyle(
                      color: _tempTypeFilter == filter ? darkGray : mediumGray,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 20),

          // Date Range Filter
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              widget.onDateRangeSelect();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: lightGray),
                borderRadius: BorderRadius.circular(8),
                color: lightBackground,
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: mediumGray),
                  const SizedBox(width: 8),
                  Text(
                    _tempDateRange == null
                        ? 'Select date range'
                        : '${DateFormat('MMM dd, yyyy').format(_tempDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_tempDateRange!.end)}',
                    style: const TextStyle(color: darkGray),
                  ),
                ],
              ),
            ),
          ),

          if (_tempDateRange != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _tempDateRange = null;
                });
              },
              icon: const Icon(Icons.clear, size: 16, color: Colors.red),
              label: const Text(
                'Clear date range',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],

          const SizedBox(height: 30),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempTypeFilter = 'All';
                      _tempDateRange = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: darkGray),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: darkGray),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_tempTypeFilter, _tempDateRange);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGray,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
