import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Generic method to add a document
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).add(data);
  }
  
  // Generic method to add a document with specific ID
  Future<void> setDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(docId).set(data, SetOptions(merge: true));
  }

  // Generic method to update a document
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(docId).update(data);
  }

  // Generic method to delete a document
  Future<void> deleteDocument(String collectionPath, String docId) async {
    await _firestore.collection(collectionPath).doc(docId).delete();
  }

  // Generic method to get a document stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDocumentStream(String collectionPath, String docId) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }

  // Generic method to get a collection stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }
}
