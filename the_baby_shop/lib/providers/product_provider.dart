import 'dart:io';
import 'dart:typed_data'; // Uint8List ke liye important hai
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  late final Stream<List<ProductModel>> productsStream = _productRepo.getProducts();
  late final Stream<List<CategoryModel>> categoriesStream =
      _categoryRepo.getCategories();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  double _uploadProgress = 0;
  String? _error;
  String _searchQuery = '';
  String _selectedCategoryId = '';

  List<ProductModel> get products => _filteredProducts;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String get selectedCategoryId => _selectedCategoryId;

  void updateProductList(List<ProductModel> products) {
    _products = products;
    _applyFilter();
    notifyListeners();
  }

  void updateCategoryList(List<CategoryModel> categories) {
    _categories = categories;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setCategoryFilter(String categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var list = List<ProductModel>.from(_products);
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) => p.productName.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_selectedCategoryId.isNotEmpty) {
      list =
          list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    _filteredProducts = list;
  }

  // Updated: imageFile ke sath webImageBytes parameter add kiya hai
  Future<void> addProduct(
    ProductModel product, {
    File? imageFile,
    Uint8List? webImageBytes,
  }) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null; // Purane errors clear karne ke liye
    notifyListeners();
    try {
      String imageUrl = product.image;
      
      // Agar dono me se koi ek cheez bhi selected hai toh upload trigger hoga
      if (imageFile != null || webImageBytes != null) {
        imageUrl = await _productRepo.uploadProductImage(
          imageFile: imageFile,
          webImageBytes: webImageBytes,
          onProgress: (p) {
            _uploadProgress = p;
            notifyListeners();
          },
        );
      }
      final updated = product.copyWith(image: imageUrl);
      await _productRepo.addProduct(updated);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // Updated: imageFile ke sath webImageBytes parameter add kiya hai
  Future<void> updateProduct(
    ProductModel product, {
    File? imageFile,
    Uint8List? webImageBytes,
  }) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();
    try {
      String imageUrl = product.image;
      
      if (imageFile != null || webImageBytes != null) {
        imageUrl = await _productRepo.uploadProductImage(
          imageFile: imageFile,
          webImageBytes: webImageBytes,
          onProgress: (p) {
            _uploadProgress = p;
            notifyListeners();
          },
        );
      }
      final updated = product.copyWith(image: imageUrl);
      await _productRepo.updateProduct(updated);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id, String imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _productRepo.deleteProduct(id, imageUrl);
    } catch (e) {
      _error = e.toString();
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