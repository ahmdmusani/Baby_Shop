import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class AdminCharts extends StatefulWidget {
  final List<OrderModel> orders;

  const AdminCharts({super.key, required this.orders});

  @override
  State<AdminCharts> createState() => _AdminChartsState();
}

class _AdminChartsState extends State<AdminCharts> {
  int _selectedChartIndex = 0; // 0 for Sales Trend, 1 for Status Distribution
  static const _pink = Color(0xFFFF4071);
  static const _blue = Color(0xFF2196F3);

  // Helper to get past 7 days (including today)
  List<DateTime> _getLast7Days() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });
  }

  // Calculate daily revenue for the past 7 days
  List<FlSpot> _getSalesSpots(List<DateTime> days) {
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      double dailyRevenue = 0;
      for (final order in widget.orders) {
        if (order.createdAt != null &&
            order.status == 'delivered' &&
            _isSameDay(order.createdAt!, day)) {
          dailyRevenue += order.totalAmount;
        }
      }
      spots.add(FlSpot(i.toDouble(), dailyRevenue));
    }
    return spots;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Calculate status counts
  Map<String, int> _getStatusCounts() {
    final counts = <String, int>{};
    for (final order in widget.orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getLast7Days();
    final spots = _getSalesSpots(days);
    final statusCounts = _getStatusCounts();

    // Find max Y for Sales Trend scaling
    double maxY = 1000;
    for (final spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
    // Round to next 500/1000 increment for aesthetic padding
    maxY = (maxY / 500).ceil() * 500.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF2D3142),
                ),
              ),
              // Segmented toggles
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleButton(0, 'Sales Trend'),
                    _buildToggleButton(1, 'Statuses'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _selectedChartIndex == 0
                ? _buildLineChart(days, spots, maxY)
                : _buildPieChart(statusCounts),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(int index, String label) {
    final isSelected = _selectedChartIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? _pink : Colors.black45,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<DateTime> days, List<FlSpot> spots, double maxY) {
    final currency = NumberFormat.compactCurrency(symbol: 'Rs. ', decimalDigits: 0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withOpacity(0.04),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox.shrink();
                return Text(
                  currency.format(value),
                  style: GoogleFonts.poppins(color: Colors.black38, fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('E').format(days[idx]), // e.g., Mon, Tue
                    style: GoogleFonts.poppins(color: Colors.black45, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _pink,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: _pink,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _pink.withOpacity(0.25),
                  _pink.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> counts) {
    if (counts.isEmpty) {
      return Center(
        child: Text(
          'No order data available',
          style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    final total = counts.values.fold(0, (sum, val) => sum + val);

    final statusColors = {
      'pending': const Color(0xFFFF9800),
      'processing': _blue,
      'shipped': const Color(0xFF9C27B0),
      'delivered': const Color(0xFF4CAF50),
      'cancelled': Colors.red,
    };

    final sections = counts.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final color = statusColors[entry.key.toLowerCase()] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 34,
        titleStyle: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 28,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: counts.entries.map((entry) {
                final color = statusColors[entry.key.toLowerCase()] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.key[0].toUpperCase()}${entry.key.substring(1)} (${entry.value})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF2D3142),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
