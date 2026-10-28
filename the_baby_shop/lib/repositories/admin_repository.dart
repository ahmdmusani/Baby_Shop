import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AdminUserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AdminUserModel.fromFirestore(doc)).toList());
  }

  Future<AdminUserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AdminUserModel.fromFirestore(doc);
  }

  Future<void> updateUserStatus(String uid, bool isDisabled) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'isDisabled': isDisabled});
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update(data);
  }
}
