import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/user/product_details_screen.dart';

// Optimized Firebase service with caching and batch operations
class OptimizedFirebaseService {
  static final OptimizedFirebaseService _instance =
      OptimizedFirebaseService._internal();
  factory OptimizedFirebaseService() => _instance;
  OptimizedFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory caches
  final Map<String, Map<String, dynamic>> _watchCache = {};
  final Map<String, List<Map<String, dynamic>>> _collectionCache = {};
  final Map<String, Uint8List> _imageCache = {};

  // Cache timestamps for invalidation
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Batch size for Firestore queries
  static const int _batchSize = 10;

  // Get cached data or fetch from Firestore
  Future<List<Map<String, dynamic>>> getCollectionsWithWatches({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'collections_with_watches';

    // Check cache first
    if (!forceRefresh &&
        _isCacheValid(cacheKey) &&
        _collectionCache.containsKey(cacheKey)) {
      return _collectionCache[cacheKey]!;
    }

    try {
      // Fetch collections and watches in parallel
      final results = await Future.wait([
        _fetchCollections(),
        _fetchAllWatches(),
      ]);

      final collections = results[0] as List<Map<String, dynamic>>;
      final allWatches = results[1] as Map<String, Map<String, dynamic>>;

      // Combine collections with their watches
      final collectionsWithWatches =
          collections.map((collection) {
            final watchIds = List<String>.from(collection['watchIds'] ?? []);
            final watches =
                watchIds
                    .map((id) => allWatches[id])
                    .where((watch) => watch != null)
                    .cast<Map<String, dynamic>>()
                    .toList();

            return {...collection, 'watches': watches};
          }).toList();

      // Cache the result
      _collectionCache[cacheKey] = collectionsWithWatches;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Cache to persistent storage
      await _cacheToStorage(cacheKey, collectionsWithWatches);

      return collectionsWithWatches;
    } catch (e) {
      // Try to return cached data on error
      if (_collectionCache.containsKey(cacheKey)) {
        return _collectionCache[cacheKey]!;
      }

      // Try to load from persistent storage
      final cachedData = await _loadFromStorage(cacheKey);
      if (cachedData != null) {
        _collectionCache[cacheKey] = cachedData;
        return cachedData;
      }

      rethrow;
    }
  }

  // Fetch all collections in a single query
  Future<List<Map<String, dynamic>>> _fetchCollections() async {
    final snapshot =
        await _firestore
            .collection('perfect_collection')
            .orderBy('createdAt', descending: false)
            .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Fetch all watches using batch queries for better performance
  Future<Map<String, Map<String, dynamic>>> _fetchAllWatches() async {
    // First, get all watch IDs from collections to know what to fetch
    final collectionsSnapshot =
        await _firestore.collection('perfect_collection').get();

    final Set<String> allWatchIds = {};
    for (final doc in collectionsSnapshot.docs) {
      final watchIds = List<String>.from(doc.data()['watchIds'] ?? []);
      allWatchIds.addAll(watchIds);
    }

    if (allWatchIds.isEmpty) {
      return {};
    }

    // Fetch watches in batches to avoid Firestore limitations
    final Map<String, Map<String, dynamic>> allWatches = {};
    final watchIdsList = allWatchIds.toList();

    for (int i = 0; i < watchIdsList.length; i += _batchSize) {
      final batch = watchIdsList.skip(i).take(_batchSize).toList();

      // Use 'in' query for batch fetching (max 10 items per query)
      final snapshot =
          await _firestore
              .collection('watches')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

      for (final doc in snapshot.docs) {
        allWatches[doc.id] = {'id': doc.id, ...doc.data()};

        // Cache individual watches
        _watchCache[doc.id] = allWatches[doc.id]!;
      }
    }

    return allWatches;
  }

  // Get individual watch with caching
  Future<Map<String, dynamic>?> getWatch(
    String watchId, {
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _watchCache.containsKey(watchId)) {
      return _watchCache[watchId];
    }

    try {
      final doc = await _firestore.collection('watches').doc(watchId).get();

      if (doc.exists) {
        final watchData = {'id': doc.id, ...doc.data()!};

        _watchCache[watchId] = watchData;
        return watchData;
      }
    } catch (e) {
      debugPrint('Error fetching watch $watchId: $e');
    }

    return null;
  }

  // Optimized image handling with caching
  Future<Uint8List?> getDecodedImage(String base64String) async {
    // Check memory cache first
    if (_imageCache.containsKey(base64String)) {
      return _imageCache[base64String];
    }

    try {
      // Decode image in background isolate for better performance
      final bytes = await compute(_decodeBase64Image, base64String);

      if (bytes != null) {
        // Cache the decoded image (limit cache size to prevent memory issues)
        if (_imageCache.length > 100) {
          _imageCache.clear(); // Simple cache eviction
        }
        _imageCache[base64String] = bytes;
      }

      return bytes;
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return null;
    }
  }

  // Static function for isolate computation
  static Uint8List? _decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  // Cache validation
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Persistent storage caching
  Future<void> _cacheToStorage(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString('cache_$key', jsonString);
      await prefs.setInt(
        'cache_timestamp_$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error caching to storage: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _loadFromStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cache_$key');
      final timestamp = prefs.getInt('cache_timestamp_$key');

      if (jsonString != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          return jsonList.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Error loading from storage: $e');
    }

    return null;
  }

  // Clear all caches
  void clearCache() {
    _watchCache.clear();
    _collectionCache.clear();
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  // Preload critical data
  Future<void> preloadCriticalData() async {
    try {
      // Start loading collections and watches in background
      getCollectionsWithWatches();
    } catch (e) {
      debugPrint('Error preloading data: $e');
    }
  }
}

// Optimized collection screen with progressive loading
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final OptimizedFirebaseService _firebaseService = OptimizedFirebaseService();

  List<Map<String, dynamic>> _collections = [];
  // ignore: unused_field
  int _currentCollectionIndex = 0;
  int _currentWatchIndex = 0;

  // Progressive loading states
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isInitialLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final collections = await _firebaseService.getCollectionsWithWatches(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _collections = collections;
          _isInitialLoading = false;
          _isRefreshing = false;
          _currentCollectionIndex = 0;
          _currentWatchIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Failed to load collections. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
            onPressed:
                _isRefreshing ? null : () => _loadData(forceRefresh: true),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isInitialLoading) {
      return _buildProgressiveLoading(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_collections.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildCollectionsView(theme);
  }

  // Progressive loading with skeleton and early content display
  Widget _buildProgressiveLoading(ThemeData theme) {
    return Column(
      children: [
        // Show app structure immediately
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: _buildShimmer(
            child: Container(
              height: 32,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        Expanded(
          child: _buildShimmer(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),

        // Show loading indicator
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading collections...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: child,
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadData(forceRefresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('No collections found', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildCollectionsView(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _collections.length,
        onPageChanged: (index) {
          setState(() {
            _currentCollectionIndex = index;
            _currentWatchIndex = 0;
          });
        },
        itemBuilder: (context, collectionIndex) {
          final collection = _collections[collectionIndex];
          final watches = List<Map<String, dynamic>>.from(
            collection['watches'] ?? [],
          );

          return _CollectionView(
            collection: collection,
            watches: watches,
            currentWatchIndex: _currentWatchIndex,
            onWatchChanged: (index) {
              setState(() {
                _currentWatchIndex = index;
              });
            },
            firebaseService: _firebaseService,
          );
        },
      ),
    );
  }
}

// Separate widget for individual collection to optimize rebuilds
class _CollectionView extends StatelessWidget {
  const _CollectionView({
    required this.collection,
    required this.watches,
    required this.currentWatchIndex,
    required this.onWatchChanged,
    required this.firebaseService,
  });

  final Map<String, dynamic> collection;
  final List<Map<String, dynamic>> watches;
  final int currentWatchIndex;
  final ValueChanged<int> onWatchChanged;
  final OptimizedFirebaseService firebaseService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (watches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.watch_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No watches in this collection',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Collection header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            collection['name'] ?? 'Unnamed Collection',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),

        if (collection['description']?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              collection['description'],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Main watch display with optimized image loading
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _OptimizedWatchImage(
              imageUrl: watches[currentWatchIndex]['imageUrl'],
              firebaseService: firebaseService,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Horizontal watch scroll with lazy loading
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: watches.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, watchIndex) {
              return GestureDetector(
                onTap: () => onWatchChanged(watchIndex),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          currentWatchIndex == watchIndex
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _OptimizedWatchImage(
                    imageUrl: watches[watchIndex]['imageUrl'],
                    firebaseService: firebaseService,
                    isSmall: true,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Watch details
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _WatchDetails(watch: watches[currentWatchIndex]),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// Optimized image widget with caching and progressive loading
class _OptimizedWatchImage extends StatefulWidget {
  const _OptimizedWatchImage({
    required this.imageUrl,
    required this.firebaseService,
    this.isSmall = false,
  });

  final String? imageUrl;
  final OptimizedFirebaseService firebaseService;
  final bool isSmall;

  @override
  State<_OptimizedWatchImage> createState() => _OptimizedWatchImageState();
}

class _OptimizedWatchImageState extends State<_OptimizedWatchImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_OptimizedWatchImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await widget.firebaseService.getDecodedImage(
        widget.imageUrl!,
      );

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(widget.isSmall ? 10 : 20);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: SizedBox(
            width: widget.isSmall ? 20 : 40,
            height: widget.isSmall ? 20 : 40,
            child: CircularProgressIndicator(
              strokeWidth: widget.isSmall ? 2 : 3,
            ),
          ),
        ),
      );
    }

    if (_hasError || _imageBytes == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            Icons.watch,
            size: widget.isSmall ? 30 : 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Add fade-in animation for better UX
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;

          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }
}

// Optimized watch details widget
class _WatchDetails extends StatelessWidget {
  const _WatchDetails({required this.watch});

  final Map<String, dynamic> watch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final details = [
      {'label': 'Model', 'value': watch['model']},
      {'label': 'Price', 'value': '\$${watch['price']}'},
      {'label': 'Case Material', 'value': watch['caseMaterial']},
      {'label': 'Movement', 'value': watch['movementType']},
      {'label': 'Special Feature', 'value': watch['specialFeature']},
      {'label': 'Diameter', 'value': '${watch['diameter']}mm'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          watch['name'] ?? 'Unnamed Watch',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  details.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${detail['label']}: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${detail['value']}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              final watchModel = Watch(
                id: watch['id'],
                name: watch['name'],
                price: (watch['price'] as num).toDouble(),
                category: watch['category'],
                description: watch['description'],
                imageUrl: watch['imageUrl'],
                stockCount: watch['stockCount'] as int,
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
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(watch: watchModel),
                ),
              );
              // Navigate to product details
              // Implementation depends on your navigation setup
            },
            child: Text(
              'View Details',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
