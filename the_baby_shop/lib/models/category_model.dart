import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String categoryName;
  final String image;

  const CategoryModel({
    required this.id,
    required this.categoryName,
    required this.image,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      categoryName: data['categoryName'] ?? '',
      image: data['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'categoryName': categoryName,
        'image': image,
      };

  CategoryModel copyWith({String? categoryName, String? image}) {
    return CategoryModel(
      id: id,
      categoryName: categoryName ?? this.categoryName,
      image: image ?? this.image,
    );
  }
}
