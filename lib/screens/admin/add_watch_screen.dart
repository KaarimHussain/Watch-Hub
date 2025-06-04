import 'dart:convert';
// import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/recent_activity.model.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/services/recent_activity_service.dart';

class AddWatchScreen extends StatefulWidget {
  const AddWatchScreen({super.key});

  @override
  State<AddWatchScreen> createState() => _AddWatchScreenState();
}

class _AddWatchScreenState extends State<AddWatchScreen> {
  // Service
  final RecentActivityService _recentActivityService = RecentActivityService();
  //Image
  Uint8List? _selectedImage;
  // Controllers
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Add New Watch')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                            color: theme.cardTheme.color,
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
                            color: theme.cardTheme.color,
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
              _customInput(
                _nameController,
                'Watch Name',
                Icons.watch,
                isNumber: false,
              ),
              const SizedBox(height: 15),
              _customInput(
                _priceController,
                'Watch Price',
                Icons.watch,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _descriptionController,
                'Watch Description',
                Icons.watch,
                maxLines: 3,
                isNumber: false,
              ),
              const SizedBox(height: 15),
              _customInput(
                _stockCountController,
                'Watch Stock Count',
                Icons.watch,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              // Category
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
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
              const SizedBox(height: 15),
              _customInput(_modelController, 'Model', Icons.model_training),
              const SizedBox(height: 15),
              _customInput(
                _movementTypeController,
                'Movement Type',
                Icons.settings,
              ),
              const SizedBox(height: 15),
              _customInput(
                _caseMaterialController,
                'Case Material',
                Icons.crop_square,
              ),
              const SizedBox(height: 15),
              _customInput(
                _diameterController,
                'Diameter (mm)',
                Icons.circle,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _thicknessController,
                'Thickness (mm)',
                Icons.compress,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _bandMaterialController,
                'Band Material',
                Icons.watch,
              ),
              const SizedBox(height: 15),
              _customInput(
                _bandWidthController,
                'Band Width (mm)',
                Icons.width_normal,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _weightController,
                'Weight (g)',
                Icons.fitness_center,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _warrantyController,
                'Warranty (years)',
                Icons.verified,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _customInput(
                _specialFeatureController,
                'Special Feature',
                Icons.star,
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // Water Resistant Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isWaterResistant,
                    onChanged: (value) {
                      setState(() {
                        _isWaterResistant = value!;
                      });
                    },
                  ),
                  Text('Water Resistant', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 15),
              // Add Watch Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _addProducts(),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
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
      final originalBytes = await pickedFile.readAsBytes();
      print(
        "Original image size: ${(originalBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
      );

      Uint8List compressedBytes = originalBytes; // fallback

      if (!kIsWeb) {
        // 📱 Mobile Compression
        final compressed = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );
        // compressedBytes = Uint8List.fromList(compressed ?? originalBytes);
        compressedBytes = Uint8List.fromList(compressed);
        print(
          "Compressed image size (Mobile): ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
        );
      } else {
        // 🌐 Web Compression
        img.Image? image = img.decodeImage(originalBytes);
        if (image != null) {
          print("Original Dimensions: ${image.width}x${image.height}");

          // Sirf badi images resize karo
          if (image.width > 800 || image.height > 800) {
            img.Image resized = img.copyResize(
              image,
              width: image.width > image.height ? 800 : null,
              height: image.height >= image.width ? 800 : null,
            );

            compressedBytes = Uint8List.fromList(
              img.encodeJpg(resized, quality: 70),
            );
            print(
              "Image resized and compressed (Web): ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
            );
          } else {
            // Already optimized
            compressedBytes = Uint8List.fromList(
              img.encodeJpg(image, quality: 70),
            );
            print(
              "Image quality compressed (Web): ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
            );
          }
        } else {
          print("⚠️ Image decoding failed — no compression applied.");
        }
      }

      // Save image to variable (or database, etc.)
      setState(() {
        _selectedImage = compressedBytes;
      });

      // Optional: Print final result
      print(
        "✅ Final Image Size: ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
      );
    }
  }

  void _addProducts() async {
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

    // Validate empty fields
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
        "Please fill in all fields and select an image.",
        type: SnackBarType.error,
      );
      return;
    }

    double? price = double.tryParse(priceText);
    int? stockCount = int.tryParse(stockText);

    if (price == null || price <= 0) {
      showSnackBar(
        context,
        "Please enter a valid price.",
        type: SnackBarType.error,
      );
      return;
    }

    if (stockCount == null || stockCount < 0) {
      showSnackBar(
        context,
        "Please enter a valid stock count.",
        type: SnackBarType.error,
      );
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
          .add(watchData.toMap());
      if (mounted) {
        showSnackBar(
          context,
          "Timepiece added successfully",
          type: SnackBarType.success,
        );
        clearAllInputs();
        // Adding Activity
        RecentActivity addWatchActivity = RecentActivity(
          type: "Add_Watch",
          title: "Added New Timepiece",
          description:
              "New timepiece called ${name.toUpperCase()} has been added",
          timestamp: DateTime.now(),
        );
        _recentActivityService.addRecentActivity(addWatchActivity);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showSnackBar(
          context,
          "Failed to add timepiece! Please try again later.",
          type: SnackBarType.error,
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
      _modelController.clear();
      _movementTypeController.clear();
      _caseMaterialController.clear();
      _diameterController.clear();
      _thicknessController.clear();
      _bandMaterialController.clear();
      _bandWidthController.clear();
      _weightController.clear();
      _warrantyController.clear();
      _specialFeatureController.clear();
      _isWaterResistant = false;
    });
  }

  Widget _customInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(suffixIcon: Icon(icon), hintText: hint),
    );
  }
}
