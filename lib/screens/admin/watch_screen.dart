import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/edit_watch_screen.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Watch> _watches = [];

  Future<void> fetchWatches() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('watches').get();
    final watchesData =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Watch(
            id: doc.id,
            name: data['name'],
            price: data['price'].toDouble(),
            category: data['category'],
            description: data['description'],
            imageUrl: data['imageUrl'],
            stockCount: data['stockCount'],
          );
        }).toList();
    setState(() {
      _watches = watchesData;
    });
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
    final categories = _watches.map((watch) => watch.category).toSet().toList();
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

  void _deleteWatch(Watch watch) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text(
              'Delete Watch',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${watch.name}"?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('watches')
                      .doc(watch.id)
                      .delete();
                  if (mounted) {
                    setState(() {
                      fetchWatches();
                    });
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${watch.name} has been deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        title: const Text(
          'Watches Management',
          style: TextStyle(color: Colors.white),
        ),
      ),
      drawer: const AdminDrawer(selectedIndex: 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 30,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF121212),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  underline: Container(height: 2, color: Colors.white),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                  items:
                      categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                filteredWatches.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.watch_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No watches found',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredWatches.length,
                      itemBuilder: (context, index) {
                        final watch = filteredWatches[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: const Color(0xFF121212),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading:
                                watch.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(watch.imageUrl),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.watch,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                            title: Text(
                              watch.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cal_Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '\$${watch.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        watch.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color:
                                          watch.stockCount > 5
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stock: ${watch.stockCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _editWatch(watch),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteWatch(watch),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: _addNewWatch,
        child: const Icon(Icons.add),
      ),
    );
  }
}
