import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/watches.model.dart';

class EditWatchScreen extends StatefulWidget {
  final Watch watch;

  const EditWatchScreen({super.key, required this.watch});

  @override
  State<EditWatchScreen> createState() => _EditWatchScreenState();
}

class _EditWatchScreenState extends State<EditWatchScreen> {
  Uint8List? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockCountController = TextEditingController();

  final List<String> categoryList = [
    'Classic',
    'Luxury',
    'Smart',
    'Sport',
    'Vintage',
  ];

  bool _isLoading = false;
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.watch.name;
    _priceController.text = widget.watch.price.toString();
    _descriptionController.text = widget.watch.description;
    _stockCountController.text = widget.watch.stockCount.toString();
    dropdownValue = widget.watch.category;
    _selectedImage = base64Decode(widget.watch.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        title: const Text('Edit Watch', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const SizedBox(height: 15),
            _buildTextField(_nameController, 'Watch Name', Icons.watch),
            const SizedBox(height: 15),
            _buildTextField(
              _priceController,
              'Watch Price',
              Icons.currency_rupee,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _descriptionController,
              'Description',
              Icons.description,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _stockCountController,
              'Stock Count',
              Icons.inventory_2,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                          'Update Watch',
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
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          suffixIcon: Icon(icon, color: Colors.white),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: dropdownValue,
        icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        underline: Container(height: 2, color: Colors.transparent),
        items:
            categoryList.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (String? value) {
          setState(() => dropdownValue = value!);
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  Future<void> _updateProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();
    final stockText = _stockCountController.text.trim();

    if (_selectedImage == null ||
        name.isEmpty ||
        priceText.isEmpty ||
        description.isEmpty ||
        stockText.isEmpty) {
      showSnackBar(
        context,
        "All fields and image are required!",
        isError: true,
      );
      return;
    }

    double? price = double.tryParse(priceText);
    int? stock = int.tryParse(stockText);
    if (price == null || price <= 0) {
      showSnackBar(context, "Enter a valid price.", isError: true);
      return;
    }
    if (stock == null || stock < 0) {
      showSnackBar(context, "Enter a valid stock count.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final updatedWatch = Watch(
      name: name,
      price: price,
      category: dropdownValue,
      description: description,
      imageUrl: base64Encode(_selectedImage!),
      stockCount: stock,
    );

    try {
      await FirebaseFirestore.instance
          .collection('watches')
          .doc(widget.watch.id)
          .update(updatedWatch.toMap());
      if (mounted) {
        showSnackBar(context, "Watch updated successfully!", isError: false);
        Navigator.pop(context); // Optionally go back
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showSnackBar(context, "Update failed. Try again.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
