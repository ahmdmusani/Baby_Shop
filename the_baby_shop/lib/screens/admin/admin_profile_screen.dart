import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../screens/splash_screen.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../theme/app_theme.dart';
import 'admin_banners_screen.dart';
import 'admin_support_screen.dart';
import 'admin_reviews_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _pink = AppTheme.primaryColor;

  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoadingProfile = false;
  bool _isLoadingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  io.File? _pickedFile;
  Uint8List? _webImageBytes;
  String _profileImageUrl = '';

  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (doc.exists && mounted) {
      final data = doc.data() ?? {};
      setState(() {
        _nameCtrl.text = data['fullName'] ?? '';
        _profileImageUrl = data['profileImage'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _pickedFile = null;
        });
      } else {
        setState(() {
          _pickedFile = io.File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoadingProfile = true);
    try {
      String imageUrl = _profileImageUrl;
      if (_webImageBytes != null || _pickedFile != null) {
        final ref = _storage.ref().child(
            'profiles/$_uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (kIsWeb) {
          await ref.putData(_webImageBytes!);
        } else {
          await ref.putFile(_pickedFile!);
        }
        imageUrl = await ref.getDownloadURL();
      }
      await _firestore.collection('users').doc(_uid).update({
        'fullName': _nameCtrl.text.trim(),
        'profileImage': imageUrl,
      });
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameCtrl.text.trim());
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _pickedFile = null;
          _webImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoadingPassword = true);
    try {
      await _authService.updatePassword(
          _currentPassCtrl.text, _newPassCtrl.text);
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPassword = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: false,
    );
    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text('Admin Profile',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _pink.withOpacity(0.2), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: _pink.withOpacity(0.12),
                      backgroundImage: _webImageBytes != null
                          ? MemoryImage(_webImageBytes!) as ImageProvider
                          : (_pickedFile != null
                              ? FileImage(_pickedFile!) as ImageProvider
                              : (_profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      _profileImageUrl)
                                  : null)),
                      child: _webImageBytes == null &&
                              _pickedFile == null &&
                              _profileImageUrl.isEmpty
                          ? Text(
                              _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _pink),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pink,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: GoogleFonts.poppins(
                    color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 28),

            // ── Profile Info Card ─────────────────────────────────────────
            _sectionTitle('Profile Information'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _fieldLabel('Full Name'),
                  _textField(_nameCtrl, 'Your name'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isLoadingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoadingProfile
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Save Profile',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, height: 1.2)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Change Password Card ───────────────────────────────────────
            _sectionTitle('Change Password'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _fieldLabel('Current Password'),
                  _passwordField(
                    _currentPassCtrl,
                    'Enter current password',
                    _obscureCurrent,
                    () => setState(
                        () => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('New Password'),
                  _passwordField(
                    _newPassCtrl,
                    'Enter new password',
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Confirm New Password'),
                  _passwordField(
                    _confirmPassCtrl,
                    'Confirm new password',
                    _obscureConfirm,
                    () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isLoadingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoadingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Update Password',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, height: 1.2)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Store Management Tools ────────────────────────────────────
            _sectionTitle('Store Management Tools'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _managementTile(
                    icon: Icons.picture_in_picture_rounded,
                    title: 'Banner Management',
                    subtitle: 'Create & manage dynamic homepage banners',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminBannersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 20),
                  _managementTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Customer Support Tickets',
                    subtitle: 'View & reply to customer complaints',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
                      );
                    },
                  ),
                  const Divider(height: 20),
                  _managementTile(
                    icon: Icons.rate_review_rounded,
                    title: 'Reviews Management',
                    subtitle: 'Monitor and delete product reviews',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminReviewsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Logout ────────────────────────────────────────────────────
            _card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.15), width: 1),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 22),
                ),
                title: Text('Logout',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.red)),
                subtitle: Text('Sign out of admin panel',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black38)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.red),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF2D3142)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF2D3142))),
        ),
      );

  Widget _textField(TextEditingController ctrl, String hint) =>
      TextField(
        controller: ctrl,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _pink, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  Widget _passwordField(
    TextEditingController ctrl,
    String hint,
    bool obscure,
    VoidCallback toggle,
  ) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.black38,
                size: 20),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _pink, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pink.withOpacity(0.15), width: 1),
        ),
        child: Icon(icon, color: _pink, size: 22),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF2D3142))),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.black38)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: _pink),
      onTap: onTap,
    );
  }
}
