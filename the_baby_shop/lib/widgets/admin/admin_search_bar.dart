import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const AdminSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF4071)),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.black38, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onEditingComplete: () => setState(() {}),
      ),
    );
  }
}
