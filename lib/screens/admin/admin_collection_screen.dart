import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:image_picker/image_picker.dart';

class AdminCollectionScreen extends StatefulWidget {
  const AdminCollectionScreen({super.key});

  @override
  State<AdminCollectionScreen> createState() => _AdminCollectionScreenState();
}

class _AdminCollectionScreenState extends State<AdminCollectionScreen> {
  File? _collectionCoverImage;
  String? _coverImageBase64;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _collectionNameController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> filteredCollections = [];
  bool _isLoading = true;
  String _sortBy = 'newest';

  // State management for add/edit operations
  bool _isCreatingCollection = false;
  bool _isUpdatingCollection = false;
  List<Watch> _selectedWatches = [];

  // Theme colors from your app
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkGray = Color(0xFF343A40);
  static const Color mediumGray = Color(0xFF6C757D);
  static const Color lightGray = Color(0xFFCED4DA);
  static const Color accentGray = Color(0xFFADB5BD);

  @override
  void initState() {
    super.initState();
    _fetchCollections();
    _searchController.addListener(_filterCollections);
  }

  void _filterCollections() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredCollections = List.from(collections);
        _applySorting();
      });
      return;
    }

    setState(() {
      filteredCollections =
          collections.where((collection) {
            final name = collection['name'].toString().toLowerCase();
            final description =
                collection['description'].toString().toLowerCase();
            return name.contains(query) || description.contains(query);
          }).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'newest':
        filteredCollections.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp;
          final bTime = b['createdAt'] as Timestamp;
          return bTime.compareTo(aTime);
        });
        break;
      case 'oldest':
        filteredCollections.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp;
          final bTime = b['createdAt'] as Timestamp;
          return aTime.compareTo(bTime);
        });
        break;
      case 'name':
        filteredCollections.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'watches':
        filteredCollections.sort(
          (a, b) => (b['watchCount'] ?? 0).compareTo(a['watchCount'] ?? 0),
        );
        break;
    }
  }

  Future<void> _fetchCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('perfect_collection')
              .get();

      final fetchedCollections =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'description': data['description'] ?? '',
              'coverImage': data['coverImage'] ?? '',
              'watchIds': data['watchIds'] ?? [],
              'watchCount': data['watchCount'] ?? 0,
              'createdAt': data['createdAt'] ?? Timestamp.now(),
            };
          }).toList();

      setState(() {
        collections = fetchedCollections;
        filteredCollections = fetchedCollections;
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching collections: $e')));
    }
  }

  void _showAddCollectionDialog() {
    _collectionNameController.clear();
    _descriptionController.clear();
    _coverImageBase64 = null;
    _selectedWatches.clear();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: darkGray.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.collections_bookmark,
                                  color: darkGray,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Create New Collection',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Cover Image Section
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lightGray),
                            ),
                            child:
                                _coverImageBase64 != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        base64Decode(_coverImageBase64!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: accentGray,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Collection Cover Image',
                                          style: TextStyle(
                                            color: mediumGray,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap to select an image',
                                          style: TextStyle(
                                            color: accentGray,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final XFile? pickedFile = await _picker
                                    .pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1024,
                                      maxHeight: 1024,
                                      imageQuality: 85,
                                    );
                                if (pickedFile != null) {
                                  String base64Image;
                                  if (kIsWeb) {
                                    final bytes =
                                        await pickedFile.readAsBytes();
                                    base64Image = base64Encode(bytes);
                                  } else {
                                    final file = File(pickedFile.path);
                                    final bytes = await file.readAsBytes();
                                    base64Image = base64Encode(bytes);
                                  }
                                  setDialogState(() {
                                    _coverImageBase64 = base64Image;
                                  });
                                }
                              },
                              icon: Icon(
                                _coverImageBase64 == null
                                    ? Icons.add_photo_alternate
                                    : Icons.edit,
                              ),
                              label: Text(
                                _coverImageBase64 == null
                                    ? "Select Cover Image"
                                    : "Change Cover",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightBackground,
                                foregroundColor: darkGray,
                                elevation: 0,
                                side: const BorderSide(color: lightGray),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Collection Name
                          TextField(
                            controller: _collectionNameController,
                            decoration: InputDecoration(
                              labelText: 'Collection Name',
                              hintText: 'Enter collection name',
                              prefixIcon: const Icon(
                                Icons.title,
                                color: mediumGray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: lightGray),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter collection description',
                              prefixIcon: const Icon(
                                Icons.description,
                                color: mediumGray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: lightGray),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(color: lightGray),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: mediumGray),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showWatchSelectionModal();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkGray,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Select Watches'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showEditCollectionDialog(Map<String, dynamic> collection) {
    _collectionNameController.text = collection['name'];
    _descriptionController.text = collection['description'] ?? '';
    _coverImageBase64 =
        collection['coverImage']?.isNotEmpty == true
            ? collection['coverImage']
            : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mediumGray.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: mediumGray,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Edit Collection',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Cover Image Section
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lightGray),
                            ),
                            child:
                                _coverImageBase64 != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        base64Decode(_coverImageBase64!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: accentGray,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No Cover Image',
                                          style: TextStyle(
                                            color: mediumGray,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final XFile? pickedFile = await _picker
                                    .pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1024,
                                      maxHeight: 1024,
                                      imageQuality: 85,
                                    );
                                if (pickedFile != null) {
                                  String base64Image;
                                  if (kIsWeb) {
                                    final bytes =
                                        await pickedFile.readAsBytes();
                                    base64Image = base64Encode(bytes);
                                  } else {
                                    final file = File(pickedFile.path);
                                    final bytes = await file.readAsBytes();
                                    base64Image = base64Encode(bytes);
                                  }
                                  setDialogState(() {
                                    _coverImageBase64 = base64Image;
                                  });
                                }
                              },
                              icon: Icon(
                                _coverImageBase64 == null
                                    ? Icons.add_photo_alternate
                                    : Icons.edit,
                              ),
                              label: Text(
                                _coverImageBase64 == null
                                    ? "Add Cover Image"
                                    : "Change Cover",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightBackground,
                                foregroundColor: mediumGray,
                                elevation: 0,
                                side: const BorderSide(color: lightGray),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller: _collectionNameController,
                            decoration: InputDecoration(
                              labelText: 'Collection Name',
                              hintText: 'Enter collection name',
                              prefixIcon: const Icon(
                                Icons.title,
                                color: mediumGray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: lightGray),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter collection description',
                              prefixIcon: const Icon(
                                Icons.description,
                                color: mediumGray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: lightGray),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(color: lightGray),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: mediumGray),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isUpdatingCollection
                                          ? null
                                          : () => _updateCollectionDetails(
                                            collection['id'],
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mediumGray,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      _isUpdatingCollection
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text('Update'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditWatchSelectionModal(collection);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkGray,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Edit Watches'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _updateCollectionDetails(String collectionId) async {
    if (_collectionNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isUpdatingCollection = true;
    });

    try {
      final updates = <String, dynamic>{
        'name': _collectionNameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      if (_coverImageBase64 != null) {
        updates['coverImage'] = _coverImageBase64;
      }

      await FirebaseFirestore.instance
          .collection('perfect_collection')
          .doc(collectionId)
          .update(updates);

      Navigator.pop(context);
      _fetchCollections();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating collection: $e')));
    } finally {
      setState(() {
        _isUpdatingCollection = false;
      });
    }
  }

  void _showWatchSelectionModal() {
    _selectedWatches.clear();
    final TextEditingController modalSearchController = TextEditingController();

    List<Watch> allWatches = [];
    List<Watch> filteredWatches = [];
    List<String> allBrands = ['All'];
    String selectedBrand = 'All';
    String selectedCategory = 'All';
    String sortOrder = 'None';
    bool isLoading = true;

    // Fetch watches from Firestore
    Future<void> fetchWatches() async {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('watches').get();

        final watches =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return Watch(
                id: doc.id,
                name: data['name'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                stockCount: (data['stockCount'] ?? 0) as int,
                category: data['category'] ?? '',
                price: (data['price'] as num).toDouble(),
                description: data['description'] ?? '',
                model: data['model'] ?? '',
                movementType: data['movementType'] ?? '',
                caseMaterial: data['caseMaterial'] ?? '',
                diameter: (data['diameter'] as num).toDouble(),
                thickness: (data['thickness'] as num).toDouble(),
                bandMaterial: data['bandMaterial'] ?? '',
                bandWidth: (data['bandWidth'] as num).toDouble(),
                weight: (data['weight'] as num).toDouble(),
                warranty: data['warranty'] ?? '',
                specialFeature: data['specialFeature'] ?? '',
                waterResistant: data['waterResistant'] ?? '',
              );
            }).toList();

        final brands = watches.map((w) => w.model).toSet().toList();

        allWatches = watches;
        filteredWatches = watches;
        allBrands = ['All', ...brands];
        isLoading = false;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching watches: $e')));
        isLoading = false;
      }
    }

    // Filter watches based on search and filters
    void filterWatches() {
      final query = modalSearchController.text.toLowerCase();

      filteredWatches =
          allWatches.where((watch) {
            final nameMatch = watch.name.toLowerCase().contains(query);
            final categoryMatch =
                selectedCategory == 'All' || watch.category == selectedCategory;
            final brandMatch =
                selectedBrand == 'All' || watch.model == selectedBrand;
            return (query.isEmpty || nameMatch) && categoryMatch && brandMatch;
          }).toList();

      if (sortOrder == 'Low to High') {
        filteredWatches.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortOrder == 'High to Low') {
        filteredWatches.sort((a, b) => b.price.compareTo(a.price));
      }
    }

    // Create collection with selected watches
    Future<void> createCollection() async {
      if (_collectionNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection name cannot be empty')),
        );
        return;
      }

      if (_selectedWatches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one watch')),
        );
        return;
      }

      setState(() {
        _isCreatingCollection = true;
      });

      try {
        final watchIds = _selectedWatches.map((watch) => watch.id).toList();

        await FirebaseFirestore.instance.collection('perfect_collection').add({
          'name': _collectionNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'watchIds': watchIds,
          'watchCount': _selectedWatches.length,
          'createdAt': Timestamp.now(),
          'coverImage': _coverImageBase64 ?? '',
        });

        _fetchCollections();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection created successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating collection: $e')),
        );
      } finally {
        setState(() {
          _isCreatingCollection = false;
        });
      }
    }

    // Show the watch selection modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            // Initialize data on first build
            if (isLoading) {
              fetchWatches().then((_) {
                modalSetState(() {});
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Watches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: modalSearchController,
                    decoration: InputDecoration(
                      hintText: "Search watches",
                      suffixIcon: const Icon(Icons.search, color: mediumGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: lightGray),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      modalSetState(() {
                        filterWatches();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Filter button and count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Watches (${filteredWatches.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Selected watches count
                  if (_selectedWatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: darkGray.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Selected: ${_selectedWatches.length} watches',
                          style: const TextStyle(
                            color: darkGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Watches list
                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(color: darkGray),
                            )
                            : filteredWatches.isEmpty
                            ? const Center(
                              child: Text(
                                "No watches found.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: mediumGray,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredWatches.length,
                              itemBuilder: (context, index) {
                                final watch = filteredWatches[index];
                                final isSelected = _selectedWatches.any(
                                  (w) => w.id == watch.id,
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      modalSetState(() {
                                        if (value == true) {
                                          _selectedWatches.add(watch);
                                        } else {
                                          _selectedWatches.removeWhere(
                                            (w) => w.id == watch.id,
                                          );
                                        }
                                      });
                                    },
                                    title: Text(
                                      watch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGray,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          watch.model,
                                          style: const TextStyle(
                                            color: mediumGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.attach_money_rounded,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            Text(
                                              'PKR ${watch.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: darkGray,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.category,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              watch.category,
                                              style: const TextStyle(
                                                color: mediumGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundImage: MemoryImage(
                                        base64Decode(watch.imageUrl),
                                      ),
                                      radius: 25,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  // Create collection button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedWatches.isEmpty || _isCreatingCollection
                              ? null
                              : createCollection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGray,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isCreatingCollection
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Create Collection (${_selectedWatches.length} watches)',
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditWatchSelectionModal(Map<String, dynamic> collection) {
    final List<String> initialWatchIds = List<String>.from(
      collection['watchIds'],
    );
    final List<String> selectedWatchIds = List<String>.from(
      collection['watchIds'],
    );
    final TextEditingController modalSearchController = TextEditingController();

    List<Watch> allWatches = [];
    List<Watch> filteredWatches = [];
    bool isLoading = true;
    bool isUpdating = false;

    // Fetch watches from Firestore
    Future<void> fetchWatches() async {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('watches').get();

        final watches =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return Watch(
                id: doc.id,
                name: data['name'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                stockCount: (data['stockCount'] ?? 0) as int,
                category: data['category'] ?? '',
                price: (data['price'] as num).toDouble(),
                description: data['description'] ?? '',
                model: data['model'] ?? '',
                movementType: data['movementType'] ?? '',
                caseMaterial: data['caseMaterial'] ?? '',
                diameter: (data['diameter'] as num).toDouble(),
                thickness: (data['thickness'] as num).toDouble(),
                bandMaterial: data['bandMaterial'] ?? '',
                bandWidth: (data['bandWidth'] as num).toDouble(),
                weight: (data['weight'] as num).toDouble(),
                warranty: data['warranty'] ?? '',
                specialFeature: data['specialFeature'] ?? '',
                waterResistant: data['waterResistant'] ?? '',
              );
            }).toList();

        allWatches = watches;
        filteredWatches = watches;
        isLoading = false;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching watches: $e')));
        isLoading = false;
      }
    }

    // Filter watches based on search
    void filterWatches() {
      final query = modalSearchController.text.toLowerCase();
      filteredWatches =
          allWatches.where((watch) {
            final nameMatch = watch.name.toLowerCase().contains(query);
            return query.isEmpty || nameMatch;
          }).toList();
    }

    // Update collection with selected watches
    Future<void> updateCollection() async {
      if (selectedWatchIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one watch')),
        );
        return;
      }

      // Check if anything changed
      if (initialWatchIds.length == selectedWatchIds.length &&
          initialWatchIds.every((id) => selectedWatchIds.contains(id))) {
        Navigator.pop(context);
        return;
      }

      isUpdating = true;

      try {
        await FirebaseFirestore.instance
            .collection('perfect_collection')
            .doc(collection['id'])
            .update({
              'watchIds': selectedWatchIds,
              'watchCount': selectedWatchIds.length,
            });

        _fetchCollections();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection updated successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating collection: $e')),
        );
      } finally {
        isUpdating = false;
      }
    }

    // Show the watch selection modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            // Initialize data on first build
            if (isLoading) {
              fetchWatches().then((_) {
                modalSetState(() {});
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Collection Watches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: modalSearchController,
                    decoration: InputDecoration(
                      hintText: "Search watches",
                      suffixIcon: const Icon(Icons.search, color: mediumGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: lightGray),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      modalSetState(() {
                        filterWatches();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Filter button and count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Watches (${filteredWatches.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Selected watches count
                  if (selectedWatchIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: darkGray.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Selected: ${selectedWatchIds.length} watches',
                          style: const TextStyle(
                            color: darkGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Watches list
                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(color: darkGray),
                            )
                            : filteredWatches.isEmpty
                            ? const Center(
                              child: Text(
                                "No watches found.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: mediumGray,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredWatches.length,
                              itemBuilder: (context, index) {
                                final watch = filteredWatches[index];
                                final isSelected = selectedWatchIds.contains(
                                  watch.id,
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      modalSetState(() {
                                        if (value == true) {
                                          if (!selectedWatchIds.contains(
                                            watch.id,
                                          )) {
                                            selectedWatchIds.add(watch.id!);
                                          }
                                        } else {
                                          selectedWatchIds.remove(watch.id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      watch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGray,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          watch.model,
                                          style: const TextStyle(
                                            color: mediumGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.attach_money_rounded,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            Text(
                                              'PKR ${watch.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: darkGray,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.category,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              watch.category,
                                              style: const TextStyle(
                                                color: mediumGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundImage: MemoryImage(
                                        base64Decode(watch.imageUrl),
                                      ),
                                      radius: 25,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  // Update collection button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : updateCollection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGray,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isUpdating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Update Collection (${selectedWatchIds.length} watches)',
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCollection(String id) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Collection'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this collection? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: mediumGray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('perfect_collection')
            .doc(id)
            .delete();
        _fetchCollections();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting collection: $e')),
        );
      }
    }
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    final watchCount = collection['watchCount'] ?? 0;
    final coverImage = collection['coverImage'] as String?;
    final hasImage = coverImage != null && coverImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showCollectionDetails(collection),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Section
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: lightBackground,
                ),
                child:
                    hasImage
                        ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.memory(
                            base64Decode(coverImage),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                lightGray.withOpacity(0.3),
                                accentGray.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.collections_bookmark_outlined,
                                  size: 48,
                                  color: accentGray,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No Cover Image',
                                  style: TextStyle(
                                    color: mediumGray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkGray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: darkGray.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.watch,
                                      size: 16,
                                      color: darkGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$watchCount ${watchCount == 1 ? 'watch' : 'watches'}',
                                      style: const TextStyle(
                                        color: darkGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: lightBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: lightGray),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: mediumGray,
                                  size: 20,
                                ),
                                onPressed:
                                    () => _showEditCollectionDialog(collection),
                                tooltip: 'Edit Collection',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                onPressed:
                                    () => _deleteCollection(collection['id']),
                                tooltip: 'Delete Collection',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Description
                    if (collection['description'] != null &&
                        collection['description'].isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        collection['description'],
                        style: const TextStyle(
                          color: mediumGray,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Footer Info
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: accentGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created ${_formatTimestamp(collection['createdAt'])}',
                          style: const TextStyle(
                            color: accentGray,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: accentGray,
                        ),
                      ],
                    ),

                    // Watch Preview (if any)
                    if (watchCount > 0) ...[
                      const SizedBox(height: 16),
                      FutureBuilder<List<String>>(
                        future: _fetchWatchPreviewImages(
                          collection['watchIds'],
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 50,
                              child: Row(
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: lightBackground,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: darkGray,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox();
                          }

                          final previewImages = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Watch Preview',
                                style: TextStyle(
                                  color: mediumGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 50,
                                child: Row(
                                  children: [
                                    ...previewImages
                                        .take(4)
                                        .map(
                                          (imageUrl) => Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: lightGray,
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode(imageUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    if (watchCount > 4)
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: lightBackground,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: lightGray,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '+${watchCount - 4}',
                                            style: const TextStyle(
                                              color: mediumGray,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollectionDetails(Map<String, dynamic> collection) {
    List<Watch> watches = [];
    bool isLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch watch data for the IDs
            void fetchWatchData() async {
              try {
                final watchIds = List<String>.from(collection['watchIds']);
                if (watchIds.isEmpty) {
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }

                final List<Watch> fetchedWatches = [];

                // Process in batches of 10
                for (int i = 0; i < watchIds.length; i += 10) {
                  final end =
                      (i + 10 < watchIds.length) ? i + 10 : watchIds.length;
                  final batch = watchIds.sublist(i, end);

                  final snapshot =
                      await FirebaseFirestore.instance
                          .collection('watches')
                          .where(FieldPath.documentId, whereIn: batch)
                          .get();

                  final batchWatches =
                      snapshot.docs.map((doc) {
                        final data = doc.data();
                        return Watch(
                          id: doc.id,
                          name: data['name'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          stockCount: (data['stockCount'] ?? 0) as int,
                          category: data['category'] ?? '',
                          price: (data['price'] as num).toDouble(),
                          description: data['description'] ?? '',
                          model: data['model'] ?? '',
                          movementType: data['movementType'] ?? '',
                          caseMaterial: data['caseMaterial'] ?? '',
                          diameter: (data['diameter'] as num).toDouble(),
                          thickness: (data['thickness'] as num).toDouble(),
                          bandMaterial: data['bandMaterial'] ?? '',
                          bandWidth: (data['bandWidth'] as num).toDouble(),
                          weight: (data['weight'] as num).toDouble(),
                          warranty: data['warranty'] ?? '',
                          specialFeature: data['specialFeature'] ?? '',
                          waterResistant: data['waterResistant'] ?? '',
                        );
                      }).toList();

                  fetchedWatches.addAll(batchWatches);
                }

                setState(() {
                  watches = fetchedWatches;
                  isLoading = false;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error fetching watch details: $e')),
                );
              }
            }

            // Call fetchWatchData only once when the modal is first built
            if (isLoading && watches.isEmpty) {
              fetchWatchData();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        collection['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  if (collection['description'] != null &&
                      collection['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        collection['description'],
                        style: const TextStyle(color: mediumGray),
                      ),
                    ),

                  Text(
                    'Watches (${collection['watchCount']})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child:
                        isLoading
                            ? const Center(
                              child: CircularProgressIndicator(color: darkGray),
                            )
                            : watches.isEmpty
                            ? const Center(
                              child: Text(
                                "No watches in this collection.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: mediumGray,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: watches.length,
                              itemBuilder: (context, index) {
                                final watch = watches[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: MemoryImage(
                                        base64Decode(watch.imageUrl),
                                      ),
                                      radius: 25,
                                    ),
                                    title: Text(
                                      watch.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGray,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          watch.model,
                                          style: const TextStyle(
                                            color: mediumGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.attach_money_rounded,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            Text(
                                              'PKR ${watch.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: darkGray,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.category,
                                              size: 16,
                                              color: mediumGray,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              watch.category,
                                              style: const TextStyle(
                                                color: mediumGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Collections',
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGray),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCollections,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AdminDrawer(selectedIndex: 4),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: darkGray))
              : Column(
                children: [
                  // Header Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Search and Add Button
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: lightBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: lightGray),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search collections...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: mediumGray,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddCollectionDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Collection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkGray,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stats and Sort
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: darkGray.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredCollections.length} ${filteredCollections.length == 1 ? 'collection' : 'collections'}',
                                style: const TextStyle(
                                  color: darkGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: lightBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: lightGray),
                              ),
                              child: DropdownButton<String>(
                                value: _sortBy,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.sort,
                                  size: 18,
                                  color: mediumGray,
                                ),
                                style: const TextStyle(
                                  color: mediumGray,
                                  fontSize: 14,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'newest',
                                    child: Text('Newest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'oldest',
                                    child: Text('Oldest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text('Name A-Z'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'watches',
                                    child: Text('Most Watches'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _sortBy = newValue;
                                    });
                                    _applySorting();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Collections List
                  Expanded(
                    child:
                        filteredCollections.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: lightBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.collections_bookmark_outlined,
                                      size: 64,
                                      color: accentGray,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No collections found'
                                        : 'No collections yet',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: darkGray,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Try adjusting your search terms'
                                        : 'Create your first collection to get started',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: mediumGray,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _searchController.text.isNotEmpty
                                            ? () {
                                              _searchController.clear();
                                              _filterCollections();
                                            }
                                            : _showAddCollectionDialog,
                                    icon: Icon(
                                      _searchController.text.isNotEmpty
                                          ? Icons.clear
                                          : Icons.add,
                                    ),
                                    label: Text(
                                      _searchController.text.isNotEmpty
                                          ? 'Clear Search'
                                          : 'Create Collection',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkGray,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredCollections.length,
                              itemBuilder: (context, index) {
                                final collection = filteredCollections[index];
                                return _buildCollectionCard(collection);
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCollectionDialog,
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<String>> _fetchWatchPreviewImages(List<dynamic> watchIds) async {
    if (watchIds.isEmpty) return [];

    try {
      final previewIds =
          watchIds.length > 5 ? watchIds.sublist(0, 5) : watchIds;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('watches')
              .where(FieldPath.documentId, whereIn: previewIds)
              .get();

      return snapshot.docs
          .map((doc) => doc.data()['imageUrl'] as String)
          .toList();
    } catch (e) {
      print('Error fetching watch preview images: $e');
      return [];
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _collectionNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
