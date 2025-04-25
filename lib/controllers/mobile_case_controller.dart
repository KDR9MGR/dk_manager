import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mobile_case_model.dart';
import '../services/mobile_case_service.dart';
import '../services/cloudflare_r2_service.dart';
import '../controllers/auth_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../services/firebase_service.dart';

class MobileCaseController extends GetxController {
  final MobileCaseService _mobileCaseService = MobileCaseService();
  final RxList<MobileCaseModel> _cases = <MobileCaseModel>[].obs;
  final RxList<MobileCaseModel> _searchResults = <MobileCaseModel>[].obs;
  final RxList<String> brands = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> stats = <String, dynamic>{}.obs;
  final RxString _searchQuery = ''.obs;
  final ImagePicker _imagePicker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _authController = Get.find<AuthController>();
  final CloudflareR2Service _r2Service = CloudflareR2Service();
  final _caseBox = Hive.box<MobileCaseModel>('cases');
  
  List<MobileCaseModel> get cases => _searchResults.isEmpty && _searchQuery.isEmpty 
    ? _cases 
    : _searchResults;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() async {
    super.onInit();
    await loadLocalCases();
    await _loadStats(); // Load initial stats
    ever(_searchQuery, (_) => _filterCases());
  }

  @override
  void onClose() {
    _r2Service.dispose();
    _caseBox.close();
    super.onClose();
  }

  Future<void> loadLocalCases() async {
    try {
      final localCases = _caseBox.values.toList();
      if (localCases.isNotEmpty) {
        _cases.assignAll(localCases);
        _updateBrandsAndStats();
      }
    } catch (e) {
      print('Error loading local cases: $e');
    }
  }

  Future<void> loadCases() async {
    try {
      isLoading.value = true;
      
      // Load from local storage first
      final localCases = _caseBox.values.toList();
      if (localCases.isNotEmpty) {
        _cases.assignAll(localCases);
        // Update UI immediately with local data
        _updateBrandsAndStats();
      }
      
      // Then fetch from server and update local storage
      final QuerySnapshot snapshot = await _firestore
          .collection('mobile_cases')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final serverCases = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Handle Timestamp fields carefully
          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];
          
          return MobileCaseModel.fromJson({
            'id': doc.id,
            'brand': data['brand'] ?? '',
            'model': data['model'] ?? '',
            'price': (data['price'] ?? 0.0).toDouble(),
            'quantity': data['quantity'] ?? 0,
            'description': data['description'],
            'imageUrl': data['imageUrl'],
            // Only pass Timestamp objects or create new ones
            'createdAt': createdAt is Timestamp ? createdAt : Timestamp.now(),
            'updatedAt': updatedAt is Timestamp ? updatedAt : Timestamp.now(),
          });
        }).toList();

        _cases.assignAll(serverCases);
        
        // Update local storage
        await _caseBox.clear();
        await _caseBox.addAll(serverCases);
        
        // Update UI with server data
        _updateBrandsAndStats();
      }
    } catch (e, stackTrace) {
      print('Error loading cases: $e\n$stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load cases: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateBrandsAndStats() {
    // Update brands list
    brands.value = _cases.map((e) => e.brand).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Update stats
    stats.value = {
      'totalCases': _cases.length,
      'totalQuantity': _cases.fold<int>(0, (sum, item) => sum + item.quantity),
      'uniqueBrands': _cases.map((e) => e.brand).toSet().length,
      'uniqueModels': _cases.map((e) => e.model).toSet().length,
    };
  }

  Future<void> _loadStats() async {
    try {
      stats.value = await _mobileCaseService.getInventoryStats();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> addCase({
    required String brand,
    required String model,
    required int quantity,
    required double price,
    String? description,
    required String userId,
  }) async {
    try {
      isLoading.value = true;
      String? imagePath;
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        imagePath = image.path;
      }

      await _mobileCaseService.addMobileCase(
        brand: brand,
        model: model,
        quantity: quantity,
        price: price,
        description: description,
        imagePath: imagePath,
        userId: userId,
      );

      Get.snackbar(
        'Success',
        'Mobile case added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await _loadStats();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCase({
    required String id,
    String? brand,
    String? model,
    int? quantity,
    double? price,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      String? imagePath;
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        imagePath = image.path;
      }

      await _mobileCaseService.updateMobileCase(
        id: id,
        brand: brand,
        model: model,
        quantity: quantity,
        price: price,
        description: description,
        imagePath: imagePath,
      );

      Get.snackbar(
        'Success',
        'Mobile case updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await _loadStats();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCase(String id) async {
    try {
      isLoading.value = true;
      
      // Get the case document to retrieve the image key
      final caseDoc = await _firestore.collection('mobile_cases').doc(id).get();
      final caseData = caseDoc.data();
      
      // Delete the document from Firestore
      await _firestore.collection('mobile_cases').doc(id).delete();
      
      // If there's an image key, delete the image from R2
      if (caseData != null && caseData.containsKey('imageKey')) {
        final imageKey = caseData['imageKey'] as String;
        await _r2Service.deleteFile(imageKey);
      }
      
      await loadCases(); // Refresh the cases list
      
      Get.snackbar(
        'Success',
        'Case deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete case: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    _searchQuery.value = '';
    _searchResults.clear();
    loadCases();
  }

  void searchCases(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    _filterCases();
  }

  void filterByBrand(String brand) {
    _mobileCaseService.getMobileCasesByBrand(brand).listen(
      (List<MobileCaseModel> caseList) {
        _cases.value = caseList;
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Future<void> addMobileCase({
    required String brand,
    required String model,
    required double price,
    required int quantity,
    required String description,
    File? image,
  }) async {
    try {
      isLoading.value = true;

      String? imageUrl;
      String? key;
      
      // Only upload image if one was provided
      if (image != null) {
        // Upload image to Cloudflare R2 instead of Firebase Storage
        key = await _r2Service.uploadFile(image, 'case_images');
        // Get the public URL for the uploaded file
        imageUrl = CloudflareR2Service.getPublicUrl(key);
      }

      // Create mobile case document
      final caseData = {
        'brand': brand,
        'model': model,
        'price': price,
        'quantity': quantity,
        'description': description,
        'imageUrl': imageUrl,
        'imageKey': key, // Store the key for later deletion if needed
        'userId': _authController.userModel!.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('mobile_cases').add(caseData);
      await loadCases(); // Refresh the cases list
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('mobile_cases')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final serverCases = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Handle Timestamp fields carefully
          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];
          
          return MobileCaseModel.fromJson({
            'id': doc.id,
            'brand': data['brand'] ?? '',
            'model': data['model'] ?? '',
            'price': (data['price'] ?? 0.0).toDouble(),
            'quantity': data['quantity'] ?? 0,
            'description': data['description'],
            'imageUrl': data['imageUrl'],
            // Only pass Timestamp objects or create new ones
            'createdAt': createdAt is Timestamp ? createdAt : Timestamp.now(),
            'updatedAt': updatedAt is Timestamp ? updatedAt : Timestamp.now(),
          });
        }).toList();

        _cases.assignAll(serverCases);
        
        // Update local storage
        await _caseBox.clear();
        await _caseBox.addAll(serverCases);
        
        // Update UI
        _updateBrandsAndStats();
      }
      _filterCases(); // Re-apply any active filters
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh cases: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void _filterCases() {
    if (_searchQuery.isEmpty) {
      _searchResults.clear();
      return;
    }

    final query = _searchQuery.value.toLowerCase();
    _searchResults.value = _cases.where((mobileCase) {
      final brand = mobileCase.brand.toLowerCase();
      final model = mobileCase.model.toLowerCase();
      return brand.contains(query) || model.contains(query);
    }).toList();
  }

  Future<List<String>> searchModels(String brand, String query) async {
    if (query.isEmpty) return [];
    
    // Search in local storage first
    final localResults = _cases
        .where((c) => c.brand.toLowerCase() == brand.toLowerCase())
        .map((c) => c.model)
        .where((model) => model.toLowerCase().contains(query.toLowerCase()))
        .toSet()
        .toList();
        
    if (localResults.isNotEmpty) {
      return localResults;
    }
    
    // If no local results, fetch from server
    try {
      final serverCases = await FirebaseService.searchCases(brand, query);
      // Update local storage with new data
      await _caseBox.addAll(serverCases);
      return serverCases.map((c) => c.model).toSet().toList();
    } catch (e) {
      print('Error searching models: $e');
      return [];
    }
  }

  Future<List<MobileCaseModel>> searchCasesOnline(String query) async {
    try {
      final snapshot = await _firestore
          .collection('mobile_cases')
          .where('brand', isGreaterThanOrEqualTo: query)
          .where('brand', isLessThan: '${query}z')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];
        
        return MobileCaseModel.fromJson({
          'id': doc.id,
          'brand': data['brand'] ?? '',
          'model': data['model'] ?? '',
          'price': (data['price'] ?? 0.0).toDouble(),
          'quantity': data['quantity'] ?? 0,
          'description': data['description'],
          'imageUrl': data['imageUrl'],
          'createdAt': createdAt is Timestamp ? createdAt : Timestamp.now(),
          'updatedAt': updatedAt is Timestamp ? updatedAt : Timestamp.now(),
        });
      }).toList();
    } catch (e) {
      print('Error searching cases online: $e');
      return [];
    }
  }

  Future<void> cacheSearchResults(List<MobileCaseModel> results) async {
    try {
      // Add new cases to local storage if they don't exist
      for (var mobileCase in results) {
        if (!_caseBox.containsKey(mobileCase.id)) {
          await _caseBox.put(mobileCase.id, mobileCase);
        }
      }
      
      // Update the cases list with new data
      final allCases = _caseBox.values.toList();
      _cases.assignAll(allCases);
      _updateBrandsAndStats();
    } catch (e) {
      print('Error caching search results: $e');
    }
  }
} 