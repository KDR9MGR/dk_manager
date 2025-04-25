import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:dotted_border/dotted_border.dart';
import '../theme/color_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(File) onImageSelected;
  final String? currentImageUrl;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.currentImageUrl,
  });

  Future<int> _getAndroidSDKVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  Future<void> _checkAndRequestPermission(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          Get.snackbar(
            'Permission Required',
            'Camera permission is required to take photos',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          );
          return;
        }
      } else {
        // For gallery access on Android 13+
        if (Platform.isAndroid) {
          final sdkInt = await _getAndroidSDKVersion();
          if (sdkInt >= 33) {
            // Android 13 and above
            final photosStatus = await Permission.photos.request();
            if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
              Get.snackbar(
                'Permission Required',
                'Photos permission is required to pick images',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
                mainButton: TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              );
              return;
            }
          } else {
            // Below Android 13
            final storageStatus = await Permission.storage.request();
            if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
              Get.snackbar(
                'Permission Required',
                'Storage permission is required to pick images',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
                mainButton: TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              );
              return;
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to request permission: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    await _checkAndRequestPermission(source);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorTheme.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: ColorTheme.onSurface,
        strokeWidth: 2,
        dashPattern: const [8, 4],
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: currentImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    currentImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload Case Image',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to choose from gallery or camera',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
} 