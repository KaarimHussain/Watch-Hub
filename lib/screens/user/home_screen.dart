// ignore_for_file: unused_field
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_hub/components/get_watch_count.component.dart';
import 'package:watch_hub/components/logo.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/components/watch_card.component.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/models/wishlist.model.dart';
import 'package:watch_hub/screens/user/product_details_screen.dart';
import 'package:watch_hub/services/cart_service.dart';
import 'package:watch_hub/services/collection_service.dart';
import 'package:watch_hub/services/watch_service.dart';
import 'package:watch_hub/services/wishlist_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Keep alive to prevent rebuilds when switching tabs
  @override
  bool get wantKeepAlive => true;

  // Consolidated loading state
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  // Error states - only track critical errors
  String? _criticalError;

  // Data with better state management
  int? _watchCount;
  List<QueryDocumentSnapshot> _watches = [];
  List<QueryDocumentSnapshot> _displayedWatches = [];
  List<Map<String, dynamic>> _featuredCollections = [];
  int _currentCarouselIndex = 0;

  // Simple filter states
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showFilters = false;

  // Available categories
  List<String> _categories = [];

  // Pagination for better performance
  static const int _watchesPerPage = 10;
  bool _hasMoreWatches = true;
  bool _isLoadingMoreWatches = false;

  // Animation controllers - only create what's needed
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Constants for better performance
  static const double kAppBarExpandedHeight = 120.0;
  static const double kAppBarCollapsedHeight = 60.0;
  static const double kLogoMaxSize = 40.0;
  static const double kLogoMinSize = 30.0;

  // Services - initialize once
  late final CartService _cartService;
  late final WishlistService _wishlistService;
  late final WatchService _watchService;
  late final CollectionService _collectionService;

  // Image cache for base64 images
  final Map<String, Uint8List> _imageCache = {};

  // Scroll controller for pagination
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeScrollController();
    _loadInitialData();
  }

  void _initializeServices() {
    _cartService = CartService();
    _wishlistService = WishlistService();
    _watchService = WatchService();
    _collectionService = CollectionService();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  void _initializeScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreWatches();
    }
  }

  // Optimized data loading with better error handling
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isInitialLoading = true;
        _criticalError = null;
      });

      // Load critical data in parallel
      final results = await Future.wait([
        _loadWatchCount(),
        _loadWatches(isInitial: true),
        _loadFeaturedCollections(),
      ], eagerError: false);

      // Check if any critical operations failed
      bool hasError = results.any((result) => result == false);

      if (!hasError && mounted) {
        _extractCategories();
        _applyFilters();
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _criticalError = 'Failed to load data. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<bool> _loadWatchCount() async {
    try {
      final count = await getTotalWatches();
      if (mounted) {
        setState(() {
          _watchCount = count;
        });
        return true;
      }
    } catch (e) {
      debugPrint('Watch count error: $e');
    }
    return false;
  }

  Future<bool> _loadWatches({bool isInitial = false}) async {
    if (_isLoadingMoreWatches && !isInitial) return false;

    try {
      if (!isInitial) {
        setState(() {
          _isLoadingMoreWatches = true;
        });
      }

      final watchList = await _watchService.getAllWatches();

      if (mounted) {
        setState(() {
          if (isInitial) {
            _watches = watchList;
            _hasMoreWatches = watchList.length > _watchesPerPage;
          } else {
            // For pagination, you might want to implement this differently
            // For now, we'll just use all watches
            _watches = watchList;
          }

          if (!isInitial) {
            _isLoadingMoreWatches = false;
          }
        });
        return true;
      }
    } catch (e) {
      if (mounted && !isInitial) {
        setState(() {
          _isLoadingMoreWatches = false;
        });
      }
      debugPrint('Watches error: $e');
    }
    return false;
  }

  Future<bool> _loadFeaturedCollections() async {
    try {
      final collections = await _collectionService.getCollectionsForCarousel();
      if (mounted) {
        setState(() {
          _featuredCollections = collections;
        });
        return true;
      }
    } catch (e) {
      debugPrint('Collections error: $e');
    }
    return false;
  }

  void _extractCategories() {
    if (_watches.isEmpty) return;

    // Extract unique categories
    final categorySet = <String>{};
    for (var watch in _watches) {
      final category = watch['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categorySet.add(category);
      }
    }

    setState(() {
      _categories = categorySet.toList()..sort();
    });
  }

  void _applyFilters() {
    List<QueryDocumentSnapshot> filtered = List.from(_watches);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((watch) {
            final name = (watch['name'] as String? ?? '').toLowerCase();
            final category = (watch['category'] as String? ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();

            return name.contains(query) || category.contains(query);
          }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered =
          filtered
              .where((watch) => watch['category'] == _selectedCategory)
              .toList();
    }

    setState(() {
      _displayedWatches = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
    });
    _applyFilters();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Future<void> _loadMoreWatches() async {
    if (!_hasMoreWatches || _isLoadingMoreWatches) return;
    await _loadWatches();
  }

  // Optimized refresh with minimal rebuilds
  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        _loadWatchCount(),
        _loadWatches(isInitial: true),
        _loadFeaturedCollections(),
      ]);
      _extractCategories();
      _applyFilters();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Optimized image caching
  // Uint8List? _getCachedImage(String base64String) {
  //   if (_imageCache.containsKey(base64String)) {
  //     return _imageCache[base64String];
  //   }

  //   try {
  //     final bytes = base64Decode(base64String);
  //     _imageCache[base64String] = bytes;
  //     return bytes;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // @override
  // void dispose() {
  //   _fadeController.dispose();
  //   _scrollController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Show critical error state
    if (_criticalError != null && _isInitialLoading) {
      return Scaffold(body: _buildCriticalErrorView(theme));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Optimized App Bar with Search and Filter
              _buildOptimizedAppBar(theme, isDarkMode),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Static sections - no rebuilds needed
                      const _HeroSection(),
                      const _FeatureHighlights(),

                      // Dynamic sections with optimized rebuilds
                      if (!_isInitialLoading) ...[
                        _buildFeaturedCollectionsSection(theme),
                        // Simple Filter Panel
                        if (_showFilters) _buildSimpleFilterPanel(theme),
                        _buildWatchListSection(theme),
                      ] else
                        const _InitialLoadingView(),

                      // Load more indicator
                      if (_isLoadingMoreWatches)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedAppBar(ThemeData theme, bool isDarkMode) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: kAppBarExpandedHeight,
      collapsedHeight: kAppBarCollapsedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedPercentage =
              1.0 -
              ((constraints.maxHeight - kToolbarHeight) /
                      (kAppBarExpandedHeight - kToolbarHeight))
                  .clamp(0.0, 1.0);

          final logoSize =
              kLogoMaxSize -
              (collapsedPercentage * (kLogoMaxSize - kLogoMinSize));
          final fontSize = 35 - (collapsedPercentage * 4);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.05),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16 * (1 - collapsedPercentage),
                  bottom: 16 * (1 - collapsedPercentage),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment:
                            Alignment.lerp(
                              Alignment.bottomLeft,
                              Alignment.centerLeft,
                              collapsedPercentage,
                            )!,
                        child: Row(
                          children: [
                            SizedBox(
                              width: logoSize,
                              height: logoSize,
                              child: logoComponent(
                                height: logoSize,
                                width: logoSize,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "WatchHub",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Lobster',
                                fontWeight: FontWeight.w100,
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Filter toggle button
                    IconButton(
                      onPressed: _toggleFilters,
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimpleFilterPanel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
            decoration: const InputDecoration(
              hintText: 'Search watches...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter
          if (_categories.isNotEmpty) ...[
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? null : _selectedCategory;
                    });
                    _applyFilters();
                  },
                ),
                ..._categories.map(
                  (category) => FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriticalErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _criticalError!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _loadInitialData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCollectionsSection(ThemeData theme) {
    if (_featuredCollections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Featured Collections",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/user_collection"),
              child: Text(
                "See All",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _OptimizedCarousel(
          collections: _featuredCollections,
          currentIndex: _currentCarouselIndex,
          onPageChanged: (index) {
            setState(() {
              _currentCarouselIndex = index;
            });
          },
          imageCache: _imageCache,
        ),
      ],
    );
  }

  Widget _buildWatchListSection(ThemeData theme) {
    // Use displayed watches (filtered) or all watches if no filters
    final watchesToShow =
        _displayedWatches.isEmpty &&
                _searchQuery.isEmpty &&
                _selectedCategory == null
            ? _watches
            : _displayedWatches;

    if (watchesToShow.isEmpty) {
      return _buildEmptyWatchesView(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          "Watches (${watchesToShow.length})",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _fadeAnimation,
          child: _OptimizedWatchList(
            watches: watchesToShow,
            imageCache: _imageCache,
            cartService: _cartService,
            wishlistService: _wishlistService,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWatchesView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? Icons.search_off
                : Icons.watch_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? "No Watches Found"
                : "No Watches Available",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? "Try adjusting your filters or search terms."
                : "We're working on adding new watches to our collection.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? Icons.clear
                  : Icons.refresh,
            ),
            label: Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? "Clear Filters"
                  : "Refresh",
            ),
            onPressed:
                _searchQuery.isNotEmpty || _selectedCategory != null
                    ? _clearFilters
                    : () => _loadWatches(isInitial: true),
          ),
        ],
      ),
    );
  }
}

// Keep all the existing static widgets (_HeroSection, _FeatureHighlights, etc.)
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF303030), Color(0xFF1A1A1A)],
          stops: [0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 3,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 3,
                  width: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Luxury Timepieces",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Discover our exclusive collection of premium watches",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/user_collection");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Explore Collection",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified,
      'title': 'Authentic',
      'subtitle': '100% Genuine',
      'color': Colors.blue,
    },
    {
      'icon': Icons.access_time,
      'title': '24/7 Support',
      'subtitle': 'Always available',
      'color': Colors.purple,
    },
    {
      'icon': Icons.workspace_premium,
      'title': 'Warranty',
      'subtitle': '2-Year Guarantee',
      'color': Colors.orange,
    },
    {
      'icon': Icons.payments_outlined,
      'title': 'Secure Payment',
      'subtitle': 'Protected Checkout',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return _FeatureCard(
            icon: feature['icon'],
            title: feature['title'],
            subtitle: feature['subtitle'],
            color: feature['color'],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialLoadingView extends StatelessWidget {
  const _InitialLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading watches...'),
          ],
        ),
      ),
    );
  }
}

class _OptimizedCarousel extends StatelessWidget {
  const _OptimizedCarousel({
    required this.collections,
    required this.currentIndex,
    required this.onPageChanged,
    required this.imageCache,
  });

  final List<Map<String, dynamic>> collections;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final Map<String, Uint8List> imageCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: collections.length,
          itemBuilder: (context, index, realIndex) {
            final collection = collections[index];
            return _CarouselItem(
              collection: collection,
              imageCache: imageCache,
            );
          },
          options: CarouselOptions(
            height: 200,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.easeInOut,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.85,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              collections.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        currentIndex == entry.key
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.3),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({required this.collection, required this.imageCache});

  final Map<String, dynamic> collection;
  final Map<String, Uint8List> imageCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child:
                  collection['coverImage'] != null
                      ? _OptimizedImage(
                        base64String: collection['coverImage'],
                        imageCache: imageCache,
                      )
                      : Container(
                        color: theme.colorScheme.surface,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection['name'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collection['description'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizedImage extends StatelessWidget {
  const _OptimizedImage({required this.base64String, required this.imageCache});

  final String base64String;
  final Map<String, Uint8List> imageCache;

  @override
  Widget build(BuildContext context) {
    final cachedBytes = imageCache[base64String];

    if (cachedBytes != null) {
      return Image.memory(
        cachedBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _decodeImage(base64String),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          imageCache[base64String] = snapshot.data!;
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<Uint8List?> _decodeImage(String base64String) async {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }
}

class _OptimizedWatchList extends StatelessWidget {
  const _OptimizedWatchList({
    required this.watches,
    required this.imageCache,
    required this.cartService,
    required this.wishlistService,
  });

  final List<QueryDocumentSnapshot> watches;
  final Map<String, Uint8List> imageCache;
  final CartService cartService;
  final WishlistService wishlistService;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: watches.length,
      itemBuilder: (context, index) {
        final watch = watches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _OptimizedWatchCard(
            watch: watch,
            imageCache: imageCache,
            cartService: cartService,
            wishlistService: wishlistService,
          ),
        );
      },
    );
  }
}

class _OptimizedWatchCard extends StatelessWidget {
  const _OptimizedWatchCard({
    required this.watch,
    required this.imageCache,
    required this.cartService,
    required this.wishlistService,
  });

  final QueryDocumentSnapshot watch;
  final Map<String, Uint8List> imageCache;
  final CartService cartService;
  final WishlistService wishlistService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: WatchCard(
            watchId: watch.id.toString(),
            name: watch['name'],
            price: (watch['price'] as num).toDouble(),
            category: watch['category'],
            imageUrl: watch['imageUrl'],
            onWishlistTap: (isAdded) => _handleWishlist(context, isAdded),
            onAddToCartTap: () => _handleAddToCart(context),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductDetailsScreen(
              watch: Watch(
                id: watch.id,
                name: watch['name'],
                price: (watch['price'] as num).toDouble(),
                category: watch['category'],
                description: watch['description'],
                imageUrl: watch['imageUrl'],
                stockCount: watch['stockCount'],
                model: watch['model'],
                movementType: watch['movementType'],
                caseMaterial: watch['caseMaterial'],
                diameter: (watch['diameter'] as num).toDouble(),
                thickness: (watch['thickness'] as num).toDouble(),
                bandMaterial: watch['bandMaterial'],
                bandWidth: (watch['bandWidth'] as num).toDouble(),
                weight: (watch['weight'] as num).toDouble(),
                warranty: watch['warranty'],
                specialFeature: watch['specialFeature'],
                waterResistant: watch['waterResistant'],
              ),
            ),
      ),
    );
  }

  void _handleWishlist(BuildContext context, bool isAdded) {
    final wishListData = WishList(
      userId: FirebaseAuth.instance.currentUser!.uid,
      watchId: watch.id.toString(),
    );

    if (isAdded) {
      wishlistService.addWishlist(wishListData).then((success) {
        if (success) {
          showSnackBar(
            context,
            "Watch added to wishlist",
            type: SnackBarType.success,
          );
        } else {
          showSnackBar(
            context,
            "Failed to add watch to wishlist",
            type: SnackBarType.error,
          );
        }
      });
    } else {
      wishlistService.removeWishlist(wishListData).then((success) {
        if (success) {
          showSnackBar(
            context,
            "Watch removed from wishlist",
            type: SnackBarType.success,
          );
        } else {
          showSnackBar(
            context,
            "Failed to remove watch from wishlist",
            type: SnackBarType.error,
          );
        }
      });
    }
  }

  void _handleAddToCart(BuildContext context) async {
    try {
      await cartService.addToCart(
        FirebaseAuth.instance.currentUser!.uid,
        watch.id.toString(),
      );
      showSnackBar(context, "Watch added to cart", type: SnackBarType.success);
    } catch (e) {
      showSnackBar(context, e.toString(), type: SnackBarType.error);
    }
  }
}
