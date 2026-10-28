import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../services/cloudinary_service.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ProductModel> _cachedProducts = [];
  bool _hasFetched = false;
  final StreamController<List<ProductModel>> _controller = StreamController<List<ProductModel>>.broadcast();
  StreamSubscription? _subscription;

  /// Single shared stream with replay capability — avoids rapid listen/cancel cycles and fixes infinite loading.
  Stream<List<ProductModel>> getProducts() {
    if (_subscription == null) {
      _subscription = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList())
          .listen(
            (products) {
              _cachedProducts = products;
              _hasFetched = true;
              _controller.add(products);
            },
            onError: (err) {
              _controller.addError(err);
            },
          );
    }

    return Stream<List<ProductModel>>.multi((controller) {
      if (_hasFetched) {
        controller.add(_cachedProducts);
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

  Future<void> addProduct(ProductModel product) async {
    try {
      final docRef = _firestore.collection('products').doc();
      final data = product.toMap();
      data['id'] = docRef.id; 
      
      await docRef.set(data);
    } catch (e) {
      print("Repository Error writing product to Firestore: $e");
      throw Exception("Firestore product upload error: ${e.toString()}");
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      print("Repository Error updating product in Firestore: $e");
      throw Exception("Firestore product update error: ${e.toString()}");
    }
  }

  /// Deletes the product document AND its image (if it belongs to Firebase Storage).
  Future<void> deleteProduct(String id, String imageUrl) async {
    await _firestore.collection('products').doc(id).delete();
    if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (_) {
        // Image may already be deleted or URL invalid — safe to ignore.
      }
    }
  }

  Future<String> uploadProductImage({
    File? imageFile,
    Uint8List? webImageBytes,
    void Function(double)? onProgress,
  }) async {
    if (imageFile == null && webImageBytes == null) return '';
    
    try {
      if (onProgress != null) onProgress(0.3);
      
      final url = await CloudinaryService.uploadToCloudinary(
        imageFile: imageFile,
        webImageBytes: webImageBytes,
      );
      
      if (onProgress != null) onProgress(1.0);
      return url;
    } catch (e) {
      print("Product Cloudinary Upload Exception: $e");
      return '';
    }
  }
}