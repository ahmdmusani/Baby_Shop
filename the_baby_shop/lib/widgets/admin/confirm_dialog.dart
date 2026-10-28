import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
  bool isDestructive = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Text(
        message,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            cancelText,
            style: GoogleFonts.poppins(
                color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDestructive ? Colors.red.shade400 : const Color(0xFFFF4071),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            confirmText,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4071),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('OK', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}
