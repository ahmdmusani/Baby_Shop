import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminStatusChip extends StatelessWidget {
  final String status;

  const AdminStatusChip({super.key, required this.status});

  static const _statusConfig = {
    'pending': (Color(0xFFFF9800), Color(0xFFFFF3E0), 'Pending'),
    'processing': (Color(0xFF2196F3), Color(0xFFE3F2FD), 'Processing'),
    'shipped': (Color(0xFF3F51B5), Color(0xFFE8EAF6), 'Shipped'),
    'delivered': (Color(0xFF4CAF50), Color(0xFFE8F5E9), 'Delivered'),
    'cancelled': (Color(0xFFF44336), Color(0xFFFFEBEE), 'Cancelled'),
  };

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[status.toLowerCase()];
    final textColor = config?.$1 ?? Colors.grey;
    final bgColor = config?.$2 ?? Colors.grey.shade100;
    final label = config?.$3 ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
