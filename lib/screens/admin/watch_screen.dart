import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/models/recent_activity.model.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/edit_watch_screen.dart';
import 'package:watch_hub/services/recent_activity_service.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  // Service
  final RecentActivityService _recentActivityService = RecentActivityService();
  // Controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Watch> _watches = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Responsive layout variables
  // bool get _isSmallScreen => MediaQuery.of(context).size.width < 600;
  bool get _isMediumScreen =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  bool get _isLargeScreen => MediaQuery.of(context).size.width >= 900;

  Future<void> fetchWatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('watches').get();
      final watchesData =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Watch(
              id: doc.id,
              name: data['name'],
              price: (data['price'] as num).toDouble(),
              category: data['category'],
              description: data['description'],
              imageUrl: data['imageUrl'],
              stockCount: data['stockCount'],
              model: data['model'],
              movementType: data['movementType'],
              caseMaterial: data['caseMaterial'],
              diameter: (data['diameter'] as num).toDouble(),
              thickness: (data['thickness'] as num).toDouble(),
              bandMaterial: data['bandMaterial'],
              bandWidth: (data['bandWidth'] as num).toDouble(),
              weight: (data['weight'] as num).toDouble(),
              warranty: data['warranty'],
              specialFeature: data['specialFeature'],
              waterResistant: data['waterResistant'],
            );
          }).toList();

      setState(() {
        _watches = watchesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load watches: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWatches();
  }

  List<Watch> get filteredWatches {
    return _watches.where((watch) {
      final matchesSearch =
          watch.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          watch.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || watch.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get categories {
    final categories = _watches.map((w) => w.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addNewWatch() {
    Navigator.pushNamed(
      context,
      '/admin_add_watch',
    ).then((_) => fetchWatches());
  }

  void _editWatch(Watch watch) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditWatchScreen(watch: watch),
          ),
        )
        .then((_) => fetchWatches());
  }

  Future<void> _deleteWatch(Watch watch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Watch'),
            content: Text('Are you sure you want to delete "${watch.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      _showLoadingDialog('Deleting watch...');

      // Delete the watch document
      await FirebaseFirestore.instance
          .collection('watches')
          .doc(watch.id)
          .delete();

      // Query and delete all reviews related to the watch
      final reviewSnapshots =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('watchId', isEqualTo: watch.id)
              .get();

      for (var doc in reviewSnapshots.docs) {
        await doc.reference.delete();
      }

      // Add to recent activity
      await _recentActivityService.addRecentActivity(
        RecentActivity(
          type: 'Delete_Watch',
          title: "Deleted Watch",
          description: "Delete a watch named ${watch.name.toUpperCase()}",
          timestamp: DateTime.now(),
        ),
      );

      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      // Refresh watches list
      if (mounted) fetchWatches();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${watch.name} has been deleted')),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ${watch.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void _showWatchDetails(Watch watch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (watch.imageUrl.isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(watch.imageUrl),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        watch.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${watch.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(label: Text(watch.category)),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 10,
                            color:
                                watch.stockCount > 10
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text('Stock: ${watch.stockCount}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _detailRow('Model', watch.model),
                      _detailRow('Movement Type', watch.movementType),
                      _detailRow('Case Material', watch.caseMaterial),
                      _detailRow('Diameter', '${watch.diameter} mm'),
                      _detailRow('Thickness', '${watch.thickness} mm'),
                      _detailRow('Band Material', watch.bandMaterial),
                      _detailRow('Band Width', '${watch.bandWidth} mm'),
                      _detailRow('Weight', '${watch.weight} g'),
                      _detailRow('Warranty', watch.warranty.toString()),
                      _detailRow(
                        'Water Resistant',
                        watch.waterResistant ? 'Yes' : 'No',
                      ),
                      _detailRow('Special Feature', watch.specialFeature),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(watch.description),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editWatch(watch);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteWatch(watch);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search watches",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                labelText: 'Category',
              ),
              value: _selectedCategory,
              isExpanded: true,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedCategory = newValue);
                }
              },
              items:
                  categories
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchCard(Watch watch) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWatchDetails(watch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Watch image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        watch.imageUrl.isNotEmpty
                            ? Image.memory(
                              base64Decode(watch.imageUrl),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.watch, size: 40),
                            ),
                  ),
                  const SizedBox(width: 16),
                  // Watch details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          watch.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${watch.price.toStringAsFixed(2)}',
                          style: textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                watch.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color:
                                  watch.stockCount > 10
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: ${watch.stockCount}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editWatch(watch),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteWatch(watch),
                    icon: Icon(
                      Icons.delete,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchGrid(Watch watch) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWatchDetails(watch),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child:
                  watch.imageUrl.isNotEmpty
                      ? Image.memory(
                        base64Decode(watch.imageUrl),
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: double.infinity,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.watch, size: 40),
                      ),
            ),
            // Watch details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watch.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${watch.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          watch.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color:
                            watch.stockCount > 10 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${watch.stockCount}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _editWatch(watch),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _deleteWatch(watch),
                    icon: Icon(Icons.delete, color: theme.colorScheme.error),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: fetchWatches, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (filteredWatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_off, size: 64),
            const SizedBox(height: 16),
            Text(
              'No watches found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'All';
                  });
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    // Grid view for larger screens, list view for smaller screens
    if (_isMediumScreen || _isLargeScreen) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isLargeScreen ? 3 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredWatches.length,
        itemBuilder: (context, index) {
          return _buildWatchGrid(filteredWatches[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: filteredWatches.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(filteredWatches[index].id.toString()),
            background: Container(
              color: Colors.blue,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return _deleteWatch(filteredWatches[index]).then((_) => false);
              } else if (direction == DismissDirection.startToEnd) {
                _editWatch(filteredWatches[index]);
                return false;
              }
              return false;
            },
            child: _buildWatchCard(filteredWatches[index]),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watches Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchWatches,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AdminDrawer(selectedIndex: 1),
      body: Column(
        children: [
          _buildSearchFilterBar(),
          Expanded(child: _buildWatchesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewWatch,
        icon: const Icon(Icons.add),
        label: const Text('Add Watch'),
      ),
    );
  }
}
