import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/app_constants.dart';
import '../../controllers/mobile_case_controller.dart';
import '../../models/mobile_case_model.dart';
import '../../theme/color_theme.dart';

class EditCaseScreen extends StatefulWidget {
  const EditCaseScreen({super.key});

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caseController = Get.find<MobileCaseController>();
  late final MobileCaseModel _mobileCase;
  final RxBool _isFormValid = false.obs;
  final RxInt _quantity = 0.obs;

  @override
  void initState() {
    super.initState();
    _mobileCase = Get.arguments as MobileCaseModel;
    _initializeControllers();
    // Add listeners to all controllers to check form validity
    _addControllerListeners();
  }

  void _addControllerListeners() {
    void checkFormValidity() {
      _isFormValid.value = _formKey.currentState?.validate() ?? false;
    }

    _brandController.addListener(checkFormValidity);
    _modelController.addListener(checkFormValidity);
    _priceController.addListener(checkFormValidity);
    // Don't need to add listener for quantity as it's handled by our custom controls
  }

  void _initializeControllers() {
    _brandController.text = _mobileCase.brand;
    _modelController.text = _mobileCase.model;
    _quantity.value = _mobileCase.quantity;
    _quantityController.text = _mobileCase.quantity.toString();
    _priceController.text = _mobileCase.price.toString();
    _descriptionController.text = _mobileCase.description ?? '';
  }

  void _incrementQuantity() {
    _quantity.value++;
    _quantityController.text = _quantity.value.toString();
    _formKey.currentState?.validate();
  }

  void _decrementQuantity() {
    if (_quantity.value > 0) {
      _quantity.value--;
      _quantityController.text = _quantity.value.toString();
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleEditCase() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _caseController.updateCase(
          id: _mobileCase.id,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          quantity: _quantity.value,
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
        );
        Get.back();
        Get.snackbar(
          'Success',
          'Case updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorTheme.success.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to update case: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorTheme.error.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    }
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            color: ColorTheme.onBackground,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorTheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: _decrementQuantity,
                isEnabled: _quantity.value > 0,
              ),
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: ColorTheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Obx(() => Text(
                      _quantity.value.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorTheme.onSurface,
                      ),
                    )),
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: _incrementQuantity,
                isEnabled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled ? ColorTheme.primary : ColorTheme.primary.withOpacity(0.3),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: ColorTheme.onBackground,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: ColorTheme.onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: ColorTheme.onBackground.withOpacity(0.4),
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: ColorTheme.primary, size: 20)
                : null,
            filled: true,
            fillColor: ColorTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ColorTheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ColorTheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ColorTheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ColorTheme.error,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTheme.background,
      appBar: AppBar(
        title: const Text('Edit Case'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ColorTheme.primaryGradient,
          ),
        ),
        foregroundColor: ColorTheme.onPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_mobileCase.imageUrl != null)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _mobileCase.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: ColorTheme.surfaceVariant,
                            child: const Icon(
                              Iconsax.image,
                              size: 64,
                              color: ColorTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  _buildTextField(
                    controller: _brandController,
                    labelText: 'Brand',
                    hintText: 'Enter brand name',
                    prefixIcon: Iconsax.mobile,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter brand name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _modelController,
                    labelText: 'Model',
                    hintText: 'Enter model name',
                    prefixIcon: Iconsax.code,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter model name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildQuantityField(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceController,
                    labelText: 'Price',
                    hintText: 'Enter price',
                    prefixIcon: Iconsax.money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'Description (Optional)',
                    hintText: 'Enter description',
                    prefixIcon: Iconsax.document_text,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Obx(() {
                final bool isEnabled = _isFormValid.value && !_caseController.isLoading.value;
                return SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled ? ColorTheme.primary : ColorTheme.surfaceVariant,
                      foregroundColor: isEnabled ? ColorTheme.onPrimary : ColorTheme.onSurface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isEnabled ? _handleEditCase : null,
                    child: _caseController.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: ColorTheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
} 