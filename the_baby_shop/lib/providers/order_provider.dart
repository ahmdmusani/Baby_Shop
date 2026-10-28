import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();

  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  Stream<List<OrderModel>> get ordersStream => _repository.getAllOrders();

  Stream<List<OrderModel>> get filteredOrdersStream {
    return _repository.getAllOrders().map((orders) {
      if (_statusFilter == 'all') return orders;
      return orders.where((o) => o.status == _statusFilter).toList();
    });
  }

  Stream<OrderModel?> orderByIdStream(String orderId) =>
      _repository.getOrderById(orderId);

  Stream<List<OrderModel>> userOrdersStream(String userId) =>
      _repository.getOrdersByUserId(userId);

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Revenue = sum of totalAmount for delivered orders only.
  double calculateRevenue(List<OrderModel> orders) {
    return orders
        .where((o) => o.status == 'delivered')
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  Future<void> updateOrderStatus(
      String orderId, String newStatus, String adminUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateOrderStatus(orderId, newStatus, adminUid);
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

  Future<void> placeOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.placeOrder(order);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
