import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/components/format_date.component.dart';
import 'package:watch_hub/screens/user/write_review_screen.dart';

class ViewReviewScreen extends StatefulWidget {
  const ViewReviewScreen({super.key, required this.watchId});
  final String? watchId;

  @override
  State<ViewReviewScreen> createState() => _ViewReviewScreenState();
}

class _ViewReviewScreenState extends State<ViewReviewScreen> {
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance
      .collection('reviews');

  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  List<Map<String, dynamic>> _reviewsWithUser = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  bool _isLoading = true;

  // Filter states
  String _ratingFilter = 'All';
  String _dateFilter = 'Newest';

  // Available filter options
  final List<String> _ratingOptions = [
    'All',
    '5 ★',
    '4 ★',
    '3 ★',
    '2 ★',
    '1 ★',
  ];
  final List<String> _dateOptions = ['Newest', 'Oldest'];

  @override
  void initState() {
    super.initState();
    _getReviewsWithUsers();
  }

  Future<void> _getReviewsWithUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(widget.watchId);
      final querySnapshot =
          await _reviewsCollection
              .where('watchId', isEqualTo: widget.watchId)
              .orderBy('createdAt', descending: true)
              .get();

      List<Map<String, dynamic>> reviews = [];

      for (var reviewDoc in querySnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>;
        final userId = reviewData['userId'];

        DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          reviews.add({
            'review': reviewData['review'],
            'rating': reviewData['rating'],
            'createdAt': reviewData['createdAt'],
            'name': userData['name'] ?? 'Anonymous',
            'id': reviewDoc.id,
          });
        }
      }

      setState(() {
        _reviewsWithUser = reviews;
        _applyFilters(); // Apply initial filters
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_reviewsWithUser);

    // Apply rating filter
    if (_ratingFilter != 'All') {
      int ratingValue = int.parse(_ratingFilter.split(' ')[0]);
      filtered =
          filtered.where((review) => review['rating'] == ratingValue).toList();
    }

    // Apply date filter
    if (_dateFilter == 'Newest') {
      filtered.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );
    } else if (_dateFilter == 'Oldest') {
      filtered.sort(
        (a, b) => (a['createdAt'] as Timestamp).compareTo(
          b['createdAt'] as Timestamp,
        ),
      );
    }

    setState(() {
      _filteredReviews = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WriteReviewScreen(watchId: widget.watchId),
            ),
          );

          if (result == true) {
            _getReviewsWithUsers(); // Refresh reviews
          }
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Write Review'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Reviews',
          style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'Cal_Sans'),
        ),
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(theme),

          // Reviews list
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Loading reviews...',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                    : _filteredReviews.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildReviewsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.filter_list,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Reviews',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  theme,
                  label: 'Rating',
                  icon: Icons.star_border,
                  value: _ratingFilter,
                  items: _ratingOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _ratingFilter = value;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  theme,
                  label: 'Date',
                  icon: Icons.calendar_today,
                  value: _dateFilter,
                  items: _dateOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _dateFilter = value;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.expand_more,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              borderRadius: BorderRadius.circular(8),
              items:
                  items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(item, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _reviewsWithUser.isEmpty
                ? 'No reviews yet'
                : 'No reviews match your filters',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _reviewsWithUser.isEmpty
                ? 'Be the first to share your thoughts!'
                : 'Try changing your filter settings',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_reviewsWithUser.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              WriteReviewScreen(watchId: widget.watchId),
                    ),
                  );

                  if (result == true) {
                    _getReviewsWithUsers();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          if (!_reviewsWithUser.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _ratingFilter = 'All';
                    _dateFilter = 'Newest';
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredReviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = _filteredReviews[index];
        return _buildReviewCard(theme, review);
      },
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> review) {
    final rating = review['rating'] as int;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    review['name'][0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontFamily: 'Cal_Sans',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Cal_Sans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRatingStars(theme, rating),
                          const SizedBox(width: 8),
                          Text(
                            formatTimestampToTimeAgo(review['createdAt']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(review['review'], style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(ThemeData theme, int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color:
              index < rating
                  ? Colors.amber
                  : theme.colorScheme.onSurfaceVariant,
          size: 16,
        );
      }),
    );
  }
}
