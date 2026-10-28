import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  bool _isLoading = false;
  double _uploadProgress = 0;
  String? _error;

  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  Stream<List<CategoryModel>> get categoriesStream =>
      _repository.getCategories();

  Future<void> addCategory(CategoryModel category, {File? imageFile, Uint8List? webBytes}) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();
    try {
      String imageUrl = category.image;
      if (imageFile != null || webBytes != null) {
        imageUrl = await _repository.uploadCategoryImage(
          imageFile,
          webBytes: webBytes, 
          onProgress: (p) {
            _uploadProgress = p;
            notifyListeners();
          },
        );
      }
      
      // Passing model with updated network image url path
      final finalCategory = CategoryModel(
        id: category.id,
        categoryName: category.categoryName,
        image: imageUrl,
      );
      
      await _repository.addCategory(finalCategory);
    } catch (e) {
      _error = e.toString();
      print("Provider Add Category Error: $e");
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  Future<void> updateCategory(CategoryModel category, {File? imageFile, Uint8List? webBytes}) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();
    try {
      String imageUrl = category.image;
      if (imageFile != null || webBytes != null) {
        imageUrl = await _repository.uploadCategoryImage(
          imageFile,
          webBytes: webBytes, 
          onProgress: (p) {
            _uploadProgress = p;
            notifyListeners();
          },
        );
      }

      final finalCategory = CategoryModel(
        id: category.id,
        categoryName: category.categoryName,
        image: imageUrl,
      );

      await _repository.updateCategory(finalCategory);
    } catch (e) {
      _error = e.toString();
      print("Provider Update Category Error: $e");
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  Future<String?> deleteCategory(String id, String imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final hasLinked = await _repository.categoryHasLinkedProducts(id);
      if (hasLinked) {
        return 'This category has linked products. Reassign or delete them first.';
      }
      await _repository.deleteCategory(id, imageUrl);
      return null;
    } catch (e) {
      _error = e.toString();
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}