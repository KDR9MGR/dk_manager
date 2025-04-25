import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mobile_case_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _casesCollection = _firestore.collection('mobile_cases');

  static Future<List<MobileCaseModel>> getCases() async {
    try {
      final snapshot = await _casesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return MobileCaseModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error fetching cases: $e');
      return [];
    }
  }

  static Future<List<MobileCaseModel>> searchCases(String brand, String query) async {
    try {
      final snapshot = await _casesCollection
          .where('brand', isEqualTo: brand)
          .where('model', isGreaterThanOrEqualTo: query)
          .where('model', isLessThan: '${query}z')
          .get();

      return snapshot.docs.map((doc) {
        return MobileCaseModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error searching cases: $e');
      return [];
    }
  }

  static Future<void> addCase(MobileCaseModel mobileCase) async {
    try {
      await _casesCollection.doc(mobileCase.id).set(mobileCase.toJson());
    } catch (e) {
      print('Error adding case: $e');
      rethrow;
    }
  }

  static Future<void> updateCase(MobileCaseModel mobileCase) async {
    try {
      await _casesCollection.doc(mobileCase.id).update(mobileCase.toJson());
    } catch (e) {
      print('Error updating case: $e');
      rethrow;
    }
  }

  static Future<void> deleteCase(String id) async {
    try {
      await _casesCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting case: $e');
      rethrow;
    }
  }
} 