import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/category_model.dart';
import '../services/cloudinary_service.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<CategoryModel> _cachedCategories = [];
  bool _hasFetched = false;
  final StreamController<List<CategoryModel>> _controller = StreamController<List<CategoryModel>>.broadcast();
  StreamSubscription? _subscription;

  /// Single shared stream with replay capability — avoids rapid listen/cancel cycles and fixes infinite loading.
  Stream<List<CategoryModel>> getCategories() {
    if (_subscription == null) {
      _subscription = _firestore
          .collection('categories')
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList())
          .listen(
            (categories) {
              _cachedCategories = categories;
              _hasFetched = true;
              _controller.add(categories);
            },
            onError: (err) {
              _controller.addError(err);
            },
          );
    }

    return Stream<List<CategoryModel>>.multi((controller) {
      if (_hasFetched) {
        controller.add(_cachedCategories);
      }

      final sub = _controller.stream.listen(
        (data) => controller.add(data),
        onError: (err) => controller.addError(err),
        onDone: () => controller.close(),
      );

      controller.onCancel = () {
        sub.cancel();
      };
    });
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final docRef = _firestore.collection('categories').doc();
      final data = category.toMap();
      data['id'] = docRef.id; // Injecting the auto-generated Firebase ID safely
      await docRef.set(data);
    } catch (e) {
      print("Repository Error writing to Firestore: $e");
      throw Exception("Firestore upload error: ${e.toString()}");
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      print("Repository Error updating Firestore: $e");
      throw Exception("Firestore update error: ${e.toString()}");
    }
  }

  Future<bool> categoryHasLinkedProducts(String categoryId) async {
    final query = await _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> deleteCategory(String id, String imageUrl) async {
    await _firestore.collection('categories').doc(id).delete();
    if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (_) {}
    }
  }

  // Cloudinary image uploading pipeline
  Future<String> uploadCategoryImage(
    File? image, {
    Uint8List? webBytes, 
    void Function(double)? onProgress,
  }) async {
    if (image == null && webBytes == null) return '';
    try {
      // Trigger a starting progress so progress indicators show activity
      if (onProgress != null) onProgress(0.3);
      
      final url = await CloudinaryService.uploadToCloudinary(
        imageFile: image,
        webImageBytes: webBytes,
      );
      
      if (onProgress != null) onProgress(1.0);
      return url;
    } catch (e) {
      print("Category Cloudinary Upload Exception: $e");
      return '';
    }
  }
}