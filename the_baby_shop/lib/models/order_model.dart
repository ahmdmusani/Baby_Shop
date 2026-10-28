import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String name;
  final int qty;
  final double price;
  final String size;
  final String image;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
    required this.size,
    required this.image,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      qty: (map['qty'] ?? 1).toInt(),
      price: (map['price'] ?? 0).toDouble(),
      size: map['size'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'price': price,
        'size': size,
        'image': image,
      };
}

class OrderStatusHistoryEntry {
  final String status;
  final DateTime changedAt;
  final String changedBy;

  const OrderStatusHistoryEntry({
    required this.status,
    required this.changedAt,
    required this.changedBy,
  });

  factory OrderStatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return OrderStatusHistoryEntry(
      status: map['status'] ?? '',
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changedBy: map['changedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
        'changedAt': Timestamp.fromDate(changedAt),
        'changedBy': changedBy,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final List<OrderStatusHistoryEntry> statusHistory;
  final String shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final String orderNumber;
  final Map<String, DateTime> statusTimeline;
  final String? couponCode;
  final String? discountType;
  final String? couponTitle;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.statusHistory = const [],
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.orderNumber,
    required this.statusTimeline,
    this.couponCode,
    this.discountType,
    this.couponTitle,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
    final historyList = (data['statusHistory'] as List<dynamic>? ?? [])
        .map((e) => OrderStatusHistoryEntry.fromMap(e as Map<String, dynamic>))
        .toList();

    // Map timeline mapping
    final timelineMapRaw = data['statusTimeline'] as Map<String, dynamic>? ?? {};
    final Map<String, DateTime> timeline = {};
    timelineMapRaw.forEach((key, value) {
      if (value is Timestamp) {
        timeline[key] = value.toDate();
      } else if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) timeline[key] = parsed;
      }
    });

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      items: itemsList,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      statusHistory: historyList,
      shippingAddress: data['shippingAddress'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      orderNumber: data['orderNumber'] ?? '',
      statusTimeline: timeline,
      couponCode: data['couponCode'] as String?,
      discountType: data['discountType'] as String?,
      couponTitle: data['couponTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'deliveryFee': deliveryFee,
        'orderNumber': orderNumber,
        'statusTimeline': statusTimeline.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
        if (couponCode != null) 'couponCode': couponCode,
        if (discountType != null) 'discountType': discountType,
        if (couponTitle != null) 'couponTitle': couponTitle,
      };
}
