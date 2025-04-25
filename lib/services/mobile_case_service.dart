import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import '../models/mobile_case_model.dart';

class MobileCaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  
  // In-memory cache for search results
  final Map<String, List<MobileCaseModel>> _searchCache = {};
  final RxList<MobileCaseModel> _allCasesCache = <MobileCaseModel>[].obs;
  bool _isCacheInitialized = false;

  // Cache TTL (time to live) in milliseconds - 5 minutes
  static const int _cacheTTL = 5 * 60 * 1000;
  DateTime _lastCacheUpdate = DateTime.now();

  // Initialize cache
  Future<void> _initializeCache() async {
    if (!_isCacheInitialized || 
        DateTime.now().difference(_lastCacheUpdate).inMilliseconds > _cacheTTL) {
      final snapshot = await _firestore
          .collection('mobile_cases')
          .orderBy('createdAt', descending: true)
          .get();
      
      _allCasesCache.value = snapshot.docs
          .map((doc) => MobileCaseModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      _isCacheInitialized = true;
      _lastCacheUpdate = DateTime.now();
      _searchCache.clear(); // Clear previous search cache
    }
  }

  // Search mobile cases - optimized version
  Stream<List<MobileCaseModel>> searchMobileCases(String query) async* {
    query = query.toLowerCase().trim();
    
    // Return all cases for empty query
    if (query.isEmpty) {
      await _initializeCache();
      yield _allCasesCache;
      return;
    }
    
    // Check cache first
    if (_searchCache.containsKey(query)) {
      yield _searchCache[query]!;
      
      // Refresh cache in background if it's stale
      if (DateTime.now().difference(_lastCacheUpdate).inMilliseconds > _cacheTTL) {
        _refreshSearchResults(query);
      }
      return;
    }
    
    await _initializeCache();
    
    // Split query into words for better matching
    final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
    
    // Filter cases that match all query words
    final results = _allCasesCache.where((mobileCase) {
      final brand = mobileCase.brand.toLowerCase();
      final model = mobileCase.model.toLowerCase();
      final searchText = '$brand $model';
      
      // Check if all query words are found in the search text
      return queryWords.every((word) => searchText.contains(word));
    }).toList();
    
    // Sort results by relevance
    results.sort((a, b) {
      final aText = '${a.brand} ${a.model}'.toLowerCase();
      final bText = '${b.brand} ${b.model}'.toLowerCase();
      
      // Exact matches first
      final aExactMatch = aText.contains(query);
      final bExactMatch = bText.contains(query);
      if (aExactMatch != bExactMatch) {
        return aExactMatch ? -1 : 1;
      }
      
      // Then sort by how early the first match appears
      final aIndex = aText.indexOf(queryWords[0]);
      final bIndex = bText.indexOf(queryWords[0]);
      if (aIndex != bIndex) {
        return aIndex.compareTo(bIndex);
      }
      
      // Finally sort by text length (shorter = more relevant)
      return aText.length.compareTo(bText.length);
    });
    
    // Cache the results
    _searchCache[query] = results;
    yield results;
  }
  
  // Refresh search results in background
  Future<void> _refreshSearchResults(String query) async {
    query = query.toLowerCase().trim();
    
    // Initialize cache if needed
    await _initializeCache();
    
    // Split query into words for better matching
    final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
    
    // Filter cases that match all query words
    final results = _allCasesCache.where((mobileCase) {
      final brand = mobileCase.brand.toLowerCase();
      final model = mobileCase.model.toLowerCase();
      final searchText = '$brand $model';
      
      // Check if all query words are found in the search text
      return queryWords.every((word) => searchText.contains(word));
    }).toList();
    
    // Sort results by relevance
    results.sort((a, b) {
      final aText = '${a.brand} ${a.model}'.toLowerCase();
      final bText = '${b.brand} ${b.model}'.toLowerCase();
      
      // Exact matches first
      final aExactMatch = aText.contains(query);
      final bExactMatch = bText.contains(query);
      if (aExactMatch != bExactMatch) {
        return aExactMatch ? -1 : 1;
      }
      
      // Then sort by how early the first match appears
      final aIndex = aText.indexOf(queryWords[0]);
      final bIndex = bText.indexOf(queryWords[0]);
      if (aIndex != bIndex) {
        return aIndex.compareTo(bIndex);
      }
      
      // Finally sort by text length (shorter = more relevant)
      return aText.length.compareTo(bText.length);
    });
    
    // Update cache
    _searchCache[query] = results;
    _lastCacheUpdate = DateTime.now();
  }

  // Get all mobile cases
  Stream<List<MobileCaseModel>> getAllMobileCases() async* {
    await _initializeCache();
    yield _allCasesCache;
    
    // Also listen for real-time updates
    yield* _firestore
        .collection('mobile_cases')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final updatedCases = snapshot.docs
              .map((doc) => MobileCaseModel.fromJson({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();
          
          // Update cache
          _allCasesCache.value = updatedCases;
          _lastCacheUpdate = DateTime.now();
          
          return updatedCases;
        });
  }

  // Add new mobile case
  Future<MobileCaseModel> addMobileCase({
    required String brand,
    required String model,
    required int quantity,
    required double price,
    String? description,
    String? imagePath,
    required String userId,
  }) async {
    try {
      String? imageUrl;
      if (imagePath != null) {
        final ref = _storage.ref().child('cases/${_uuid.v4()}');
        await ref.putFile(Uri.file(imagePath).toFilePath() as dynamic);
        imageUrl = await ref.getDownloadURL();
      }

      final mobileCase = MobileCaseModel(
        id: _uuid.v4(),
        brand: brand,
        model: model,
        quantity: quantity,
        price: price,
        imageUrl: imageUrl,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('mobile_cases')
          .doc(mobileCase.id)
          .set(mobileCase.toJson());

      return mobileCase;
    } catch (e) {
      rethrow;
    }
  }

  // Update mobile case
  Future<void> updateMobileCase({
    required String id,
    String? brand,
    String? model,
    int? quantity,
    double? price,
    String? description,
    String? imagePath,
  }) async {
    try {
      final docRef = _firestore.collection('mobile_cases').doc(id);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Mobile case not found');
      }

      final currentCase = MobileCaseModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });

      String? imageUrl = currentCase.imageUrl;
      if (imagePath != null) {
        // Delete old image if exists
        if (imageUrl != null) {
          final oldRef = _storage.refFromURL(imageUrl);
          await oldRef.delete();
        }
        // Upload new image
        final ref = _storage.ref().child('cases/${_uuid.v4()}');
        await ref.putFile(Uri.file(imagePath).toFilePath() as dynamic);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedCase = currentCase.copyWith(
        brand: brand,
        model: model,
        quantity: quantity,
        price: price,
        description: description,
        imageUrl: imagePath != null ? imageUrl : null,
        updatedAt: DateTime.now(),
      );

      await docRef.update(updatedCase.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Delete mobile case
  Future<void> deleteMobileCase(String id) async {
    try {
      final docRef = _firestore.collection('mobile_cases').doc(id);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Mobile case not found');
      }

      final mobileCase = MobileCaseModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });

      if (mobileCase.imageUrl != null) {
        final ref = _storage.refFromURL(mobileCase.imageUrl!);
        await ref.delete();
      }

      await docRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get mobile cases by brand
  Stream<List<MobileCaseModel>> getMobileCasesByBrand(String brand) {
    return _firestore
        .collection('mobile_cases')
        .where('brand', isEqualTo: brand)
        .orderBy('model')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MobileCaseModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Get mobile case by id
  Future<MobileCaseModel?> getMobileCaseById(String id) async {
    try {
      final doc = await _firestore.collection('mobile_cases').doc(id).get();
      if (doc.exists) {
        return MobileCaseModel.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final snapshot = await _firestore.collection('mobile_cases').get();
      final cases = snapshot.docs
          .map((doc) => MobileCaseModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      final totalCases = cases.length;
      final totalQuantity = cases.fold<int>(0, (sum, item) => sum + item.quantity);
      final uniqueBrands = cases.map((e) => e.brand).toSet().length;
      final uniqueModels = cases.map((e) => e.model).toSet().length;

      return {
        'totalCases': totalCases,
        'totalQuantity': totalQuantity,
        'uniqueBrands': uniqueBrands,
        'uniqueModels': uniqueModels,
      };
    } catch (e) {
      rethrow;
    }
  }
} 