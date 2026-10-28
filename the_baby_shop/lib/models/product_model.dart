import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String productName;
  final String description;
  final double price;
  final double discountPrice;
  final String categoryId;
  final String image;
  final int stock;
  final DateTime? createdAt;

  // Clothing-specific attributes (conditional)
  final List<String>? sizes;
  final List<String>? colors;
  final String? sizeChart;
  final String? fabric;
  final String? detailedDescription;

  String? get sizeChartUrl => sizeChart;

  const ProductModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.categoryId,
    required this.image,
    required this.stock,
    this.createdAt,
    this.sizes,
    this.colors,
    this.sizeChart,
    this.fabric,
    this.detailedDescription,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      image: data['image'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sizes: data['sizes'] != null ? List<String>.from(data['sizes']) : null,
      colors: data['colors'] != null ? List<String>.from(data['colors']) : null,
      sizeChart: data['sizeChart'],
      fabric: data['fabric'],
      detailedDescription: data['detailedDescription'],
    );
  }

  Map<String, dynamic> toMap() => {
        'productName': productName,
        'description': description,
        'price': price,
        'discountPrice': discountPrice,
        'categoryId': categoryId,
        'image': image,
        'stock': stock,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        if (sizes != null) 'sizes': sizes,
        if (colors != null) 'colors': colors,
        if (sizeChart != null) 'sizeChart': sizeChart,
        if (fabric != null) 'fabric': fabric,
        if (detailedDescription != null) 'detailedDescription': detailedDescription,
      };

  ProductModel copyWith({
    String? productName,
    String? description,
    double? price,
    double? discountPrice,
    String? categoryId,
    String? image,
    int? stock,
    List<String>? sizes,
    List<String>? colors,
    String? sizeChart,
    String? fabric,
    String? detailedDescription,
  }) {
    return ProductModel(
      id: id,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      categoryId: categoryId ?? this.categoryId,
      image: image ?? this.image,
      stock: stock ?? this.stock,
      createdAt: createdAt,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      sizeChart: sizeChart ?? this.sizeChart,
      fabric: fabric ?? this.fabric,
      detailedDescription: detailedDescription ?? this.detailedDescription,
    );
  }
}
