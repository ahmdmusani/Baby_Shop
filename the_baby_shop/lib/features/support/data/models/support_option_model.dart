import 'package:flutter/material.dart';

class SupportOptionModel {
  final String id;
  final String title;
  final String actionType; // 'faq', 'contact', 'track', 'return', 'issue'
  final int order;

  SupportOptionModel({
    required this.id,
    required this.title,
    required this.actionType,
    required this.order,
  });

  factory SupportOptionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SupportOptionModel(
      id: docId,
      title: map['title'] ?? '',
      actionType: map['actionType'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  IconData getIcon() {
    switch (actionType) {
      case 'faq':
        return Icons.help_outline;
      case 'contact':
        return Icons.headphones_outlined;
      case 'track':
        return Icons.local_shipping_outlined;
      case 'return':
        return Icons.refresh_outlined;
      case 'issue':
        return Icons.report_problem_outlined;
      default:
        return Icons.support_agent_outlined;
    }
  }
}
