import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/email_service.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  Stream<List<OrderModel>> getOrdersByUserId(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return list;
    });
  }

  Stream<OrderModel?> getOrderById(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  /// Updates order status and appends a history entry atomically, and sends email notifications.
  Future<void> updateOrderStatus(
      String orderId, String newStatus, String adminUid) async {
    final historyEntry = OrderStatusHistoryEntry(
      status: newStatus,
      changedAt: DateTime.now(),
      changedBy: adminUid,
    );
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // Fire email trigger asynchronously
    _triggerStatusUpdateEmail(orderId, newStatus);
  }

  void _triggerStatusUpdateEmail(String orderId, String status) async {
    try {
      if (status != 'delivered' && status != 'cancelled') return;

      // 1. Fetch Order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final String userId = orderData['userId'] ?? '';
      final String customerName = orderData['customerName'] ?? 'Customer';
      final String orderNumber = orderData['orderNumber'] ?? orderId.substring(0, 8).toUpperCase();

      if (userId.isEmpty) return;

      // 2. Query customer's email from users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final String toEmail = userData['email'] ?? '';

      if (toEmail.isEmpty) return;

      // 3. Trigger email depending on status
      if (status == 'delivered') {
        await EmailService.sendOrderDeliveredEmail(
          toEmail: toEmail,
          customerName: customerName,
          orderId: orderId,
          orderNumber: orderNumber,
        );
      } else if (status == 'cancelled') {
        await EmailService.sendOrderCancelledEmail(
          toEmail: toEmail,
          customerName: customerName,
          orderNumber: orderNumber,
        );
      }
    } catch (e) {
      // Log exception silently in background
      print('Error in _triggerStatusUpdateEmail: $e');
    }
  }

  Future<void> placeOrder(OrderModel order) async {
    final batch = _firestore.batch();
    
    // Save order document
    batch.set(_firestore.collection('orders').doc(order.id), order.toMap());
    
    // Decrement stock for each item in the order
    for (var item in order.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      batch.update(productRef, {
        'stock': FieldValue.increment(-item.qty),
      });
    }
    
    await batch.commit();
  }
}
