import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class StatusHistoryTimeline extends StatelessWidget {
  final List<OrderStatusHistoryEntry> history;

  const StatusHistoryTimeline({super.key, required this.history});

  static const _statusColors = {
    'pending': Color(0xFFFF9800),
    'processing': Color(0xFF2196F3),
    'shipped': Color(0xFF3F51B5),
    'delivered': Color(0xFF4CAF50),
    'cancelled': Color(0xFFF44336),
  };

  static const _statusIcons = {
    'pending': Icons.hourglass_empty_rounded,
    'processing': Icons.settings_rounded,
    'shipped': Icons.local_shipping_rounded,
    'delivered': Icons.check_circle_rounded,
    'cancelled': Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'No status history yet.',
          style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    final sorted = List<OrderStatusHistoryEntry>.from(history)
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));

    return Column(
      children: List.generate(sorted.length, (index) {
        final entry = sorted[index];
        final isLast = index == sorted.length - 1;
        final color = _statusColors[entry.status.toLowerCase()] ?? Colors.grey;
        final icon =
            _statusIcons[entry.status.toLowerCase()] ?? Icons.circle;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, Colors.grey.shade200],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.status[0].toUpperCase() +
                              entry.status.substring(1),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy  hh:mm a')
                              .format(entry.changedAt),
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black45),
                        ),
                        if (entry.changedBy.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'by ${entry.changedBy}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.black38),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
