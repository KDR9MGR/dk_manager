import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'mobile_case_model.g.dart';

@HiveType(typeId: 0)
class MobileCaseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String brand;

  @HiveField(2)
  final String model;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final int quantity;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final String? description;

  MobileCaseModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  factory MobileCaseModel.fromJson(Map<String, dynamic> json) {
    final createdAtData = json['createdAt'];
    final updatedAtData = json['updatedAt'];
    
    DateTime createdAt;
    DateTime updatedAt;
    
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else {
      createdAt = DateTime.now();
    }
    
    if (updatedAtData is Timestamp) {
      updatedAt = updatedAtData.toDate();
    } else {
      updatedAt = DateTime.now();
    }
    
    return MobileCaseModel(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MobileCaseModel copyWith({
    String? id,
    String? brand,
    String? model,
    double? price,
    int? quantity,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MobileCaseModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 