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
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _movementTypeController = TextEditingController();
  final TextEditingController _caseMaterialController = TextEditingController();
  final TextEditingController _diameterController = TextEditingController();
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _bandMaterialController = TextEditingController();
  final TextEditingController _bandWidthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _warrantyController = TextEditingController();
  final TextEditingController _specialFeatureController =
      TextEditingController();
  bool _isWaterResistant = false;

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
    _modelController.text = widget.watch.model;
    _movementTypeController.text = widget.watch.movementType;
    _caseMaterialController.text = widget.watch.caseMaterial;
    _diameterController.text = widget.watch.diameter.toString();
    _thicknessController.text = widget.watch.thickness.toString();
    _bandMaterialController.text = widget.watch.bandMaterial;
    _bandWidthController.text = widget.watch.bandWidth.toString();
    _weightController.text = widget.watch.weight.toString();
    _warrantyController.text = widget.watch.warranty.toString();
    _specialFeatureController.text = widget.watch.specialFeature;
    _isWaterResistant = widget.watch.waterResistant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Watch')),
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
                          border: Border.all(color: theme.dividerColor),
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
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Select Image',
                            style: theme.textTheme.bodyMedium,
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
              maxLines: 3,
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
            _buildTextField(_modelController, 'Model', Icons.model_training),
            const SizedBox(height: 15),
            _buildTextField(
              _movementTypeController,
              'Movement Type',
              Icons.settings,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _caseMaterialController,
              'Case Material',
              Icons.category,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _diameterController,
              'Diameter (mm)',
              Icons.straighten,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _thicknessController,
              'Thickness (mm)',
              Icons.compress,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _bandMaterialController,
              'Band Material',
              Icons.format_paint,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _bandWidthController,
              'Band Width (mm)',
              Icons.swap_horiz,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _weightController,
              'Weight (g)',
              Icons.line_weight,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _warrantyController,
              'Warranty (months)',
              Icons.verified_user,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _specialFeatureController,
              'Special Features',
              Icons.star,
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text("Water Resistant", style: theme.textTheme.bodyMedium),
                Switch(
                  value: _isWaterResistant,
                  onChanged: (value) {
                    setState(() => _isWaterResistant = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(suffixIcon: Icon(icon), hintText: hint),
    );
  }

  Widget _buildDropdown() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: dropdownValue,
        icon: Icon(Icons.arrow_downward_rounded),
        iconSize: 24,
        elevation: 16,
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
    final model = _modelController.text.trim();
    final movementType = _movementTypeController.text.trim();
    final caseMaterial = _caseMaterialController.text.trim();
    final diameter = double.tryParse(_diameterController.text.trim()) ?? 0;
    final thickness = double.tryParse(_thicknessController.text.trim()) ?? 0;
    final bandMaterial = _bandMaterialController.text.trim();
    final bandWidth = double.tryParse(_bandWidthController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final warranty = int.tryParse(_warrantyController.text.trim()) ?? 0;
    final specialFeature = _specialFeatureController.text.trim();

    if (_selectedImage == null ||
        name.isEmpty ||
        priceText.isEmpty ||
        description.isEmpty ||
        stockText.isEmpty ||
        model.isEmpty ||
        movementType.isEmpty ||
        caseMaterial.isEmpty ||
        diameter == 0 ||
        thickness == 0 ||
        bandMaterial.isEmpty ||
        bandWidth == 0 ||
        weight == 0 ||
        warranty == 0 ||
        specialFeature.isEmpty) {
      showSnackBar(
        context,
        "All fields and image are required!",
        type: SnackBarType.error,
      );
      return;
    }

    double? price = double.tryParse(priceText);
    int? stock = int.tryParse(stockText);
    if (price == null || price <= 0) {
      showSnackBar(context, "Enter a valid price.", type: SnackBarType.error);
      return;
    }
    if (stock == null || stock < 0) {
      showSnackBar(
        context,
        "Enter a valid stock count.",
        type: SnackBarType.error,
      );
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
      model: model,
      movementType: movementType,
      caseMaterial: caseMaterial,
      diameter: diameter,
      thickness: thickness,
      bandMaterial: bandMaterial,
      bandWidth: bandWidth,
      weight: weight,
      warranty: warranty,
      specialFeature: specialFeature,
      waterResistant: _isWaterResistant,
    );

    try {
      await FirebaseFirestore.instance
          .collection('watches')
          .doc(widget.watch.id)
          .update(updatedWatch.toMap());
      if (mounted) {
        showSnackBar(
          context,
          "Watch updated successfully!",
          type: SnackBarType.success,
        );
        Navigator.pop(context); // Optionally go back
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showSnackBar(
          context,
          "Update failed. Try again.",
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
