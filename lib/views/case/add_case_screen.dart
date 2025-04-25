import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../controllers/mobile_case_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../constants/brand_constants.dart';
import '../../theme/color_theme.dart';
import '../home_screen.dart';

class AddCaseScreen extends StatefulWidget {
  const AddCaseScreen({super.key});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCaseController = Get.find<MobileCaseController>();
  final _authController = Get.find<AuthController>();
  final _pageController = PageController();
  
  String? _selectedBrand;
  final _modelController = TextEditingController();
  File? _selectedImage;
  File? _compressedImage;
  
  final _priceController = TextEditingController(text: '150.00');
  final _quantityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  
  // For model search suggestions
  List<String> _modelSuggestions = [];
  Timer? _debounceTimer;
  final RxInt _currentStep = 0.obs;
  final RxBool _isStep1Valid = false.obs;
  
  int get _quantity => int.tryParse(_quantityController.text) ?? 1;

  @override
  void initState() {
    super.initState();
    _modelController.addListener(_onModelSearchChanged);
    _modelController.addListener(_validateStep1);
  }

  void _validateStep1() {
    _isStep1Valid.value = _selectedBrand != null && 
                         _modelController.text.isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep.value < 1) {
      _currentStep.value++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep.value > 0) {
      _currentStep.value--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onModelSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_modelController.text.isNotEmpty && _selectedBrand != null) {
        _searchModels(_modelController.text);
      } else {
        setState(() => _modelSuggestions = []);
      }
    });
  }

  void _searchModels(String query) {
    if (query.isEmpty) {
      setState(() => _modelSuggestions = []);
      return;
    }

    // Get all cases from controller (works offline as it uses local state)
    final allCases = _mobileCaseController.cases;
    
    // Filter cases by selected brand and search query
    final suggestions = allCases
        .where((mobileCase) => 
          mobileCase.brand.toLowerCase() == _selectedBrand?.toLowerCase() &&
          mobileCase.model.toLowerCase().contains(query.toLowerCase()))
        .map((mobileCase) => mobileCase.model)
        .toSet() // Remove duplicates
        .toList();

    setState(() => _modelSuggestions = suggestions);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_compressedImage != null && _compressedImage?.path != _selectedImage?.path) {
          try {
            await _compressedImage?.delete();
          } catch (e) {
            print('Error deleting temporary file: $e');
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: ColorTheme.background,
        appBar: AppBar(
          title: const Text('Add New Case'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ColorTheme.primaryGradient,
            ),
          ),
          foregroundColor: ColorTheme.onPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () {
              if (_currentStep.value == 0) {
                Get.back();
              } else {
                _previousStep();
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Step Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Basic Info'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: ColorTheme.surfaceVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Obx(() => AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        alignment: _currentStep.value == 0 
                            ? Alignment.centerLeft 
                            : Alignment.centerRight,
                        child: Container(
                          width: 40,
                          height: 2,
                          color: ColorTheme.primary,
                        ),
                      )),
                    ),
                  ),
                  _buildStepIndicator(1, 'Optional Details'),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    return Obx(() {
      final isActive = _currentStep.value == step;
      final isCompleted = _currentStep.value > step;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted 
                  ? ColorTheme.primary 
                  : ColorTheme.surfaceVariant,
            ),
            child: Center(
              child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : ColorTheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? ColorTheme.primary 
                  : ColorTheme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand Selection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorTheme.onBackground.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: ColorTheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: ColorTheme.surfaceVariant,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Select Brand',
                    style: TextStyle(
                      color: ColorTheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                value: _selectedBrand,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Iconsax.arrow_down_1, color: ColorTheme.primary),
                ),
                items: BrandConstants.mobileBrands.map((brand) {
                  return DropdownMenuItem(
                    value: brand,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        brand,
                        style: const TextStyle(
                          color: ColorTheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                    _validateStep1();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Model Name',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorTheme.onBackground.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            style: const TextStyle(
              fontSize: 16,
              color: ColorTheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Enter model name',
              hintStyle: TextStyle(
                color: ColorTheme.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: ColorTheme.surfaceVariant.withOpacity(0.5),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: ColorTheme.primary.withOpacity(0.5),
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: ColorTheme.primary.withOpacity(0.5),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: ColorTheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          if (_modelSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorTheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Similar models found:',
                    style: TextStyle(
                      color: ColorTheme.onBackground.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _modelSuggestions.length,
                    (index) => InkWell(
                      onTap: () {
                        _modelController.text = _modelSuggestions[index];
                        setState(() => _modelSuggestions = []);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.warning_2,
                              color: ColorTheme.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _modelSuggestions[index],
                                style: const TextStyle(
                                  color: ColorTheme.onBackground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStep1Valid.value 
                    ? ColorTheme.primary 
                    : ColorTheme.surfaceVariant,
                foregroundColor: _isStep1Valid.value 
                    ? ColorTheme.onPrimary 
                    : ColorTheme.onSurface.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isStep1Valid.value ? 2 : 0,
              ),
              onPressed: _isStep1Valid.value ? _nextStep : () {
                // Show a hint message when button is disabled
                Get.snackbar(
                  'Required Fields',
                  'Please select a brand and enter a model name to continue',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorTheme.warning.withOpacity(0.8),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Upload Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorTheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorTheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorTheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.image,
                        color: ColorTheme.primary.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Case Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorTheme.onBackground.withOpacity(0.9),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedImage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ColorTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: ColorTheme.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Added',
                                style: TextStyle(
                                  color: ColorTheme.success.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _compressedImage = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ColorTheme.error.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ImagePickerWidget(
                        onImageSelected: (File file) async {
                          final compressedFile = await _compressImage(file);
                          setState(() {
                            _selectedImage = file;
                            _compressedImage = compressedFile;
                          });
                          _showCompressionInfo(file, compressedFile);
                        },
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description Section
          Container(
            decoration: BoxDecoration(
              color: ColorTheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorTheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorTheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.document_text,
                        color: ColorTheme.primary.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorTheme.onBackground.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 15,
                      color: ColorTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add description (optional)',
                      hintStyle: TextStyle(
                        color: ColorTheme.onSurface.withOpacity(0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Price Section
          Container(
            decoration: BoxDecoration(
              color: ColorTheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorTheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorTheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.money,
                        color: ColorTheme.primary.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorTheme.onBackground.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 15,
                      color: ColorTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter price',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        color: ColorTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      hintStyle: TextStyle(
                        color: ColorTheme.onSurface.withOpacity(0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Iconsax.arrow_left,
                      size: 18,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: ColorTheme.primary.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _previousStep,
                    label: const Text('Back'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: Obx(() => ElevatedButton.icon(
                    icon: _mobileCaseController.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: ColorTheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Iconsax.tick_circle,
                            size: 18,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTheme.primary,
                      foregroundColor: ColorTheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _mobileCaseController.isLoading.value 
                        ? null 
                        : _handleSubmit,
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (_selectedBrand == null) {
      Get.snackbar(
        'Error',
        'Please select a brand',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorTheme.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      _mobileCaseController.isLoading.value = true;
      
      // Handle image file - only pass it if one was selected and exists
      File? imageFile;
      if (_compressedImage != null || _selectedImage != null) {
        imageFile = _compressedImage ?? _selectedImage;
        // Verify file exists
        if (!await imageFile!.exists()) {
          print('Selected image file does not exist');
          imageFile = null;
        }
      }
      
      await _mobileCaseController.addMobileCase(
        brand: _selectedBrand!,
        model: _modelController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        description: _descriptionController.text,
        image: imageFile, // Pass the image file only if it exists
      );

      // Clean up temporary files if they exist
      if (_compressedImage != null && 
          _selectedImage != null && 
          _compressedImage?.path != _selectedImage?.path) {
        try {
          await _compressedImage?.delete();
        } catch (e) {
          print('Error deleting temporary file: $e');
        }
      }

      Get.snackbar(
        'Success',
        'Case added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorTheme.success.withOpacity(0.8),
        colorText: Colors.white,
      );

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      print('Error adding case: $e');
      Get.snackbar(
        'Error',
        'Failed to add case: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorTheme.error.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      _mobileCaseController.isLoading.value = false;
    }
  }

  // Show compression information
  void _showCompressionInfo(File original, File? compressed) {
    if (compressed == null) return;
    
    try {
      final originalSize = original.lengthSync();
      final compressedSize = compressed.lengthSync();
      
      // Only show if compression actually reduced the size
      if (compressedSize < originalSize) {
        final savedPercent = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(0);
        final originalKb = (originalSize / 1024).toStringAsFixed(0);
        final compressedKb = (compressedSize / 1024).toStringAsFixed(0);
        
        Get.snackbar(
          'Image Compressed',
          'Reduced from ${originalKb}KB to ${compressedKb}KB ($savedPercent% smaller)',
          snackPosition: SnackPosition.TOP,
          backgroundColor: ColorTheme.success.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Silently handle any errors during size calculation
      print('Error calculating image sizes: $e');
    }
  }

  // Image compression method
  Future<File?> _compressImage(File file) async {
    try {
      // Verify source file exists
      if (!await file.exists()) {
        print('Source file does not exist: ${file.path}');
        return null;
      }

      // Create temporary directory to store compressed image
      final dir = await getTemporaryDirectory();
      
      // Ensure directory exists and is writable
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        // Test if directory is writable
        final testFile = File('${dir.path}/test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        print('Directory not writable: ${dir.path}');
        print('Error: $e');
        return file;
      }

      final targetPath = path.join(
        dir.path, 
        'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}'
      );
      
      // Check original file size
      final originalSize = await file.length();
      
      // Skip compression for small files
      if (originalSize < 300 * 1024) { // < 300KB
        return file;
      }
      
      // Determine quality based on original size
      int quality = 85; // Default quality
      if (originalSize > 5 * 1024 * 1024) { // > 5MB
        quality = 50;
      } else if (originalSize > 2 * 1024 * 1024) { // > 2MB
        quality = 60;
      } else if (originalSize > 1 * 1024 * 1024) { // > 1MB
        quality = 70;
      }

      print('Compressing image: ${file.path}');
      print('Target path: $targetPath');
      print('Original size: ${originalSize / 1024}KB');
      print('Compression quality: $quality');
      
      // Compress and save the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1200,
        minHeight: 1200,
      );
      
      if (result != null) {
        final compressedSize = await File(result.path).length();
        print('Compressed size: ${compressedSize / 1024}KB');
        return File(result.path);
      }
      
      print('Compression failed, returning original file');
      return file;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  @override
  void dispose() {
    _modelController.removeListener(_onModelSearchChanged);
    _modelController.removeListener(_validateStep1);
    _debounceTimer?.cancel();
    _pageController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 