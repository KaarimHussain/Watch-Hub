import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/watches.model.dart';

class AddWatchScreen extends StatefulWidget {
  const AddWatchScreen({super.key});

  @override
  State<AddWatchScreen> createState() => _AddWatchScreenState();
}

class _AddWatchScreenState extends State<AddWatchScreen> {
  //Image
  Uint8List? _selectedImage;
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockCountController = TextEditingController();
  // Category List
  final List<String> categoryList = <String>[
    'Classic',
    'Luxury',
    'Smart',
    'Sport',
    'Vintage',
  ];
  // Button State Management
  bool _isLoading = false;

  String dropdownValue = 'Classic';

  // Dropdown Value
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        title: const Text(
          'Add New Watch',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Fields
              // -- Image
              GestureDetector(
                onTap: _pickImage,
                child:
                    _selectedImage != null
                        ? Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        : Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Select Image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
              ),
              SizedBox(height: 15),
              // -- Name
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.watch, color: Colors.white),
                    hintText: 'Watch Name',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // -- Price
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: TextField(
                  controller: _priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.currency_rupee, color: Colors.white),
                    hintText: 'Watch Price',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 15),
              // Description
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.description, color: Colors.white),
                    hintText: 'Watch Description',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // Stock Count
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: TextField(
                  controller: _stockCountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.inventory_2, color: Colors.white),
                    hintText: 'Stock Count',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // Category
              Container(
                padding: EdgeInsets.only(
                  top: 3,
                  bottom: 3,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: dropdownValue,
                  icon: Icon(Icons.arrow_downward_rounded, color: Colors.white),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF111111),
                  menuWidth: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                  underline: Container(height: 2, color: Colors.transparent),
                  items:
                      categoryList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      dropdownValue = value!;
                    });
                  },
                ),
              ),
              SizedBox(height: 15),
              // Add Watch Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            _addProducts();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Add Watch',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pick Image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  void _addProducts() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();
    final stockText = _stockCountController.text.trim();

    // Validate empty fields
    if (_selectedImage == null ||
        name.isEmpty ||
        priceText.isEmpty ||
        description.isEmpty ||
        stockText.isEmpty) {
      showSnackBar(
        context,
        "Please fill in all fields and select an image.",
        isError: true,
      );
      return;
    }

    double? price = double.tryParse(priceText);
    int? stockCount = int.tryParse(stockText);

    if (price == null || price <= 0) {
      showSnackBar(context, "Please enter a valid price.", isError: true);
      return;
    }

    if (stockCount == null || stockCount < 0) {
      showSnackBar(context, "Please enter a valid stock count.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final productImage = base64Encode(_selectedImage!);
    final category = dropdownValue;

    final watchData = Watch(
      name: name,
      price: price,
      category: category,
      description: description,
      imageUrl: productImage,
      stockCount: stockCount,
    );

    try {
      await FirebaseFirestore.instance
          .collection('watches')
          .add(watchData.toMap());
      if (mounted) {
        showSnackBar(context, "Timepiece added successfully", isError: false);
        clearAllInputs();
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showSnackBar(
          context,
          "Failed to add timepiece! Please try again later.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void clearAllInputs() {
    setState(() {
      _isLoading = false;
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _stockCountController.clear();
      _selectedImage = null;
      dropdownValue = 'Classic';
    });
  }
}
