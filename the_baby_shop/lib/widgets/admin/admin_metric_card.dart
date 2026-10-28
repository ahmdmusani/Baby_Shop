import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? leadingText;
  final Color color;
  final String? trend;
  final bool trendUp;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.leadingText,
    required this.color,
    this.trend,
    this.trendUp = true,
  });

  @override
  State<AdminMetricCard> createState() => _AdminMetricCardState();
}

class _AdminMetricCardState extends State<AdminMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.color.withOpacity(0.12), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.icon != null || widget.leadingText != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: widget.icon != null
                          ? Icon(widget.icon!, color: widget.color, size: 22)
                          : SizedBox(
                              width: 22,
                              height: 22,
                              child: Center(
                                child: Text(
                                  widget.leadingText!,
                                  style: GoogleFonts.poppins(
                                    color: widget.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.trendUp
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.trendUp
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 12,
                            color:
                                widget.trendUp ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.trend!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.trendUp
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
