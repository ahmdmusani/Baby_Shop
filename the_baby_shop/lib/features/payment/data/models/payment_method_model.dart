class PaymentMethodModel {
  final String id;
  final String type; // e.g., 'upi', 'visa', 'mastercard'
  final String title;
  final String subtitle;
  final bool isDefault;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isDefault,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentMethodModel(
      id: docId,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'isDefault': isDefault,
    };
  }
}
