import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/user/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Watch> _allWatches = [];
  List<Watch> _filteredWatches = [];
  List<String> _allBrands = ['All'];
  String _selectedBrand = 'All';

  String _selectedCategory = 'All';
  String _sortOrder = 'None';

  @override
  void initState() {
    super.initState();
    _fetchWatches();
    _searchController.addListener(_onSearchChanged);
  }

  // 🔄 Fetch from Firestore
  Future<void> _fetchWatches() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('watches').get();

    final watches =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return Watch(
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

    final brands =
        watches
            .map((w) => w.model)
            .toSet()
            .toList(); // Assuming 'model' is used as brand

    setState(() {
      _allWatches = watches;
      _allBrands = ['All', ...brands];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredWatches = []);
      return;
    }

    setState(() {
      _filteredWatches =
          _allWatches.where((watch) {
            final nameMatch = watch.name.toLowerCase().contains(query);
            final categoryMatch =
                _selectedCategory == 'All' ||
                watch.category == _selectedCategory;
            final brandMatch =
                _selectedBrand == 'All' || watch.model == _selectedBrand;
            return nameMatch && categoryMatch && brandMatch;
          }).toList();

      if (_sortOrder == 'Low to High') {
        _filteredWatches.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortOrder == 'High to Low') {
        _filteredWatches.sort((a, b) => b.price.compareTo(a.price));
      }
    });
  }

  // Show the filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the modal expandable
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Using StatefulBuilder to update the modal state independently
            return Container(
              padding: const EdgeInsets.all(20),
              // Use MediaQuery to make sure the sheet isn't too tall
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Filter options
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category filter
                          Text(
                            'Category',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildFilterChips(
                            context: context,
                            selectedValue: _selectedCategory,
                            values: [
                              'All',
                              'Classic',
                              'Luxury',
                              'Smart',
                              'Sport',
                              'Vintage',
                            ],
                            onSelected: (value) {
                              setModalState(() {
                                _selectedCategory = value;
                              });
                              setState(() {
                                _selectedCategory = value;
                                _onSearchChanged();
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Price sort filter
                          Text(
                            'Price',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          _buildFilterChips(
                            context: context,
                            selectedValue: _sortOrder,
                            values: ['None', 'Low to High', 'High to Low'],
                            onSelected: (value) {
                              setModalState(() {
                                _sortOrder = value;
                              });
                              setState(() {
                                _sortOrder = value;
                                _onSearchChanged();
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Brand filter
                          Text(
                            'Brand',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _allBrands.map((brand) {
                                  return FilterChip(
                                    label: Text(brand),
                                    selected: _selectedBrand == brand,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          _selectedBrand = brand;
                                        });
                                        setState(() {
                                          _selectedBrand = brand;
                                          _onSearchChanged();
                                        });
                                      }
                                    },
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                    selectedColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    checkmarkColor:
                                        Theme.of(context).colorScheme.primary,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _onSearchChanged();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply Filters'),
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

  // Helper method to build filter chips
  Widget _buildFilterChips({
    required BuildContext context,
    required String selectedValue,
    required List<String> values,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          values.map((value) {
            return FilterChip(
              label: Text(value),
              selected: selectedValue == value,
              onSelected: (selected) {
                if (selected) {
                  onSelected(value);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Search",
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'Cal_Sans',
                ),
              ),
              const SizedBox(height: 16),

              // 🔍 Search Box
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search watches",
                  suffixIcon: const Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 12),

              // Active filters indicator
              if (_searchController.text.isNotEmpty &&
                  (_selectedCategory != 'All' ||
                      _selectedBrand != 'All' ||
                      _sortOrder != 'None'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text('Category: $_selectedCategory'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _onSearchChanged();
                                });
                              },
                            ),
                          ),
                        if (_selectedBrand != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text('Brand: $_selectedBrand'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedBrand = 'All';
                                  _onSearchChanged();
                                });
                              },
                            ),
                          ),
                        if (_sortOrder != 'None')
                          Chip(
                            label: Text('Price: $_sortOrder'),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _sortOrder = 'None';
                                _onSearchChanged();
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

              // 📋 Results List
              Expanded(
                child:
                    _searchController.text.isEmpty
                        ? Center(
                          child: Text(
                            "Please search something",
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                        : _filteredWatches.isEmpty
                        ? Center(
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
                                  Icons.search_off,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "No watches found",
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Try different keywords or broaden your search",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _filteredWatches.length,
                          itemBuilder: (context, index) {
                            final watch = _filteredWatches[index];
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            ProductDetailsScreen(watch: watch),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: MemoryImage(
                                  base64Decode(watch.imageUrl),
                                ),
                                radius: 30,
                              ),
                              title: Text(
                                watch.name,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  // First row with model
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.watch,
                                        color: theme.iconTheme.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          watch.model,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Second row with price and stock
                                  Row(
                                    children: [
                                      // Price
                                      Icon(
                                        Icons.attach_money_rounded,
                                        color: theme.iconTheme.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        "${watch.price.toStringAsFixed(2)}",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Stock count
                                      Icon(
                                        Icons.inventory,
                                        color: theme.iconTheme.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        "Stock: ${watch.stockCount}",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: theme.iconTheme.color,
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      // Add floating action button to show filters
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterBottomSheet,
        tooltip: 'Filter',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.tune),
      ),
    );
  }
}
