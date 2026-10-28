import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../theme/app_theme.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({Key? key}) : super(key: key);

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text(
          'Promotional Banners',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('banners').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _pink));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_in_picture_rounded, size: 64, color: Colors.black12),
                  const SizedBox(height: 12),
                  Text('No banners created yet.', style: GoogleFonts.poppins(color: Colors.black38)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showBannerSheet(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text('Add Banner', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, height: 1.2)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final String title = data['title'] ?? '';
              final String subtitle = data['subtitle'] ?? '';
              final String buttonLabel = data['buttonLabel'] ?? 'Shop';
              final String imageUrl = data['imageUrl'] ?? '';
              final bool isActive = data['isActive'] ?? true;
              final String gradientStart = data['gradientStart'] ?? '#E8E4FF';
              final String gradientEnd = data['gradientEnd'] ?? '#D6CCFF';

              final Color startColor = _parseHexColor(gradientStart);
              final Color endColor = _parseHexColor(gradientEnd);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.02)),
                ),
                child: Column(
                  children: [
                    // Mock card layout
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [startColor, endColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Stack(
                        children: [
                          if (imageUrl.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (_, __, ___) => const Icon(Icons.error_outline),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: imageUrl.isNotEmpty ? Colors.white : const Color(0xFF1E1F24),
                                    shadows: imageUrl.isNotEmpty ? [const Shadow(color: Colors.black45, blurRadius: 4)] : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: imageUrl.isNotEmpty ? Colors.white.withOpacity(0.9) : Colors.black54,
                                    shadows: imageUrl.isNotEmpty ? [const Shadow(color: Colors.black45, blurRadius: 4)] : null,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _pink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    buttonLabel,
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Active Status',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3142)),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: isActive,
                                activeColor: _pink,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance.collection('banners').doc(id).update({
                                    'isActive': value,
                                  });
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                onPressed: () => _showBannerSheet(context, doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showConfirmDialog(
                                    context,
                                    title: 'Delete Banner',
                                    message: 'Are you sure you want to delete this promotional banner?',
                                  );
                                  if (confirmed == true) {
                                    await FirebaseFirestore.instance.collection('banners').doc(id).delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerSheet(context, null),
        backgroundColor: _pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Banner', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showBannerSheet(BuildContext context, DocumentSnapshot? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerFormSheet(existing: existing),
    );
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey.shade200;
    }
  }
}

class _BannerFormSheet extends StatefulWidget {
  final DocumentSnapshot? existing;
  const _BannerFormSheet({this.existing});

  @override
  State<_BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends State<_BannerFormSheet> {
  static const _pink = AppTheme.primaryColor;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _btnLabelCtrl = TextEditingController();
  final _gradStartCtrl = TextEditingController(text: '#E8E4FF');
  final _gradEndCtrl = TextEditingController(text: '#D6CCFF');
  final _iconColorCtrl = TextEditingController(text: '#7C6AE8');
  
  bool _isActive = true;
  bool _isImageBanner = false;
  File? _pickedImage;
  Uint8List? _webImageBytes;
  String _imageUrl = '';
  bool _isLoading = false;
  int _iconCodePoint = Icons.local_offer_rounded.codePoint;

  final List<Map<String, dynamic>> _iconPresets = [
    {'icon': Icons.local_offer_rounded, 'name': 'Offer Tag'},
    {'icon': Icons.child_care_rounded, 'name': 'Baby Care'},
    {'icon': Icons.delivery_dining_rounded, 'name': 'Delivery'},
    {'icon': Icons.favorite_rounded, 'name': 'Heart'},
    {'icon': Icons.star_rounded, 'name': 'Star'},
    {'icon': Icons.baby_changing_station_rounded, 'name': 'Nursery'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final data = widget.existing!.data() as Map<String, dynamic>;
      _titleCtrl.text = data['title'] ?? '';
      _subtitleCtrl.text = data['subtitle'] ?? '';
      _btnLabelCtrl.text = data['buttonLabel'] ?? '';
      _gradStartCtrl.text = data['gradientStart'] ?? '#E8E4FF';
      _gradEndCtrl.text = data['gradientEnd'] ?? '#D6CCFF';
      _iconColorCtrl.text = data['iconColor'] ?? '#7C6AE8';
      _isActive = data['isActive'] ?? true;
      _imageUrl = data['imageUrl'] ?? '';
      _iconCodePoint = data['iconCodePoint'] ?? Icons.local_offer_rounded.codePoint;
      _isImageBanner = _imageUrl.isNotEmpty;
    } else {
      _btnLabelCtrl.text = 'Shop Now';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _btnLabelCtrl.dispose();
    _gradStartCtrl.dispose();
    _gradEndCtrl.dispose();
    _iconColorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _pickedImage = File(picked.path);
        });
      } else {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _imageUrl;
      
      // Upload image if selected
      if (_isImageBanner && (_pickedImage != null || _webImageBytes != null)) {
        finalImageUrl = await CloudinaryService.uploadToCloudinary(
          imageFile: _pickedImage,
          webImageBytes: _webImageBytes,
        );
      } else if (!_isImageBanner) {
        finalImageUrl = ''; // Clear image url if gradient banner selected
      }

      final data = {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'buttonLabel': _btnLabelCtrl.text.trim(),
        'imageUrl': finalImageUrl,
        'gradientStart': _gradStartCtrl.text.trim(),
        'gradientEnd': _gradEndCtrl.text.trim(),
        'iconColor': _iconColorCtrl.text.trim(),
        'iconCodePoint': _iconCodePoint,
        'isActive': _isActive,
        'createdAt': Timestamp.now(),
      };

      if (widget.existing != null) {
        await FirebaseFirestore.instance.collection('banners').doc(widget.existing!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('banners').add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existing != null ? 'Banner updated!' : 'Banner added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save banner: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing != null ? 'Edit Promo Banner' : 'Add Promo Banner',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2D3142)),
              ),
              const SizedBox(height: 16),
              
              // Banner Type Selector
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: _isImageBanner,
                      activeColor: _pink,
                      title: Text('Gradient/Icon', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      onChanged: (val) => setState(() => _isImageBanner = val ?? false),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: _isImageBanner,
                      activeColor: _pink,
                      title: Text('Full Image', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      onChanged: (val) => setState(() => _isImageBanner = val ?? true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image Picker Section (if image banner type selected)
              if (_isImageBanner) ...[
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _pink.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: kIsWeb && _webImageBytes != null
                                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                  : Image.file(_pickedImage!, fit: BoxFit.cover),
                            )
                          : (_imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: CachedNetworkImage(imageUrl: _imageUrl, fit: BoxFit.cover),
                                )
                              : _buildImagePlaceholder()),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Standard inputs
              _buildLabel('Banner Title'),
              _buildTextField(_titleCtrl, 'e.g. Super Sale', (val) => val == null || val.trim().isEmpty ? 'Title is required' : null),
              const SizedBox(height: 12),

              _buildLabel('Banner Subtitle'),
              _buildTextField(_subtitleCtrl, 'e.g. Up to 40% Off', (val) => val == null || val.trim().isEmpty ? 'Subtitle is required' : null),
              const SizedBox(height: 12),

              _buildLabel('Button Label'),
              _buildTextField(_btnLabelCtrl, 'e.g. Shop Now', (val) => val == null || val.trim().isEmpty ? 'Button label is required' : null),
              const SizedBox(height: 12),

              // Gradient color configuration inputs
              if (!_isImageBanner) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Gradient Start Hex'),
                          _buildTextField(_gradStartCtrl, 'e.g. #E8E4FF', null),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Gradient End Hex'),
                          _buildTextField(_gradEndCtrl, 'e.g. #D6CCFF', null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Icon Color Hex'),
                          _buildTextField(_iconColorCtrl, 'e.g. #7C6AE8', null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('Select Background Icon'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconPresets.length,
                    itemBuilder: (context, idx) {
                      final item = _iconPresets[idx];
                      final IconData icon = item['icon'];
                      final isSelected = _iconCodePoint == icon.codePoint;

                      return GestureDetector(
                        onTap: () => setState(() => _iconCodePoint = icon.codePoint),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? _pink.withOpacity(0.12) : const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? _pink : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(icon, color: isSelected ? _pink : Colors.black54),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Active switch
              Row(
                children: [
                  Text('Active Status', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3142))),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    activeColor: _pink,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Banner', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF2D3142))),
      );

  Widget _buildTextField(TextEditingController ctrl, String hint, FormFieldValidator<String>? validator) => TextFormField(
        controller: ctrl,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _pink, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
      );

  Widget _buildImagePlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_rounded, color: _pink, size: 32),
          const SizedBox(height: 4),
          Text('Choose Banner Image', style: GoogleFonts.poppins(color: _pink, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );
}
