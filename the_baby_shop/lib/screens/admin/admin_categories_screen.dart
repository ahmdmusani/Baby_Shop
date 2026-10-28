import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../theme/app_theme.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

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
        title: Text('Categories',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 20),
            tooltip: 'Seed Default Categories',
            onPressed: () => _seedCategories(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: provider.categoriesStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final categories = snap.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 64, color: Colors.black12),
                  const SizedBox(height: 12),
                  Text('No categories yet.',
                      style: GoogleFonts.poppins(color: Colors.black38)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showCategorySheet(context, null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text('Add Category',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, height: 1.2)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _seedCategories(context, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text('Seed Defaults',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, height: 1.2)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (ctx, i) => _CategoryCard(
              category: categories[i],
              onEdit: () => _showCategorySheet(context, categories[i]),
              onDelete: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Delete Category',
                  message: 'Delete "${categories[i].categoryName}"? This cannot be undone.',
                );
                if (confirmed == true && context.mounted) {
                  final err = await provider.deleteCategory(
                    categories[i].id,
                    categories[i].image,
                  );
                  if (err != null && context.mounted) {
                    showErrorDialog(
                      context,
                      title: 'Cannot Delete',
                      message: err,
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context, null),
        backgroundColor: _pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Category',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, height: 1.2)),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, CategoryModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
  }

  Future<void> _seedCategories(BuildContext context, CategoryProvider provider) async {
    final defaultCats = [
      {'name': 'Diapers', 'image': 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Feeding', 'image': 'https://images.unsplash.com/photo-1522850959013-3a90059b0f01?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Baby Food', 'image': 'https://images.unsplash.com/photo-1596263578925-c60f274a4cf4?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Clothing', 'image': 'https://images.unsplash.com/photo-1515488042361-404e9250afef?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Toys', 'image': 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Bath & Care', 'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Nursery', 'image': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=300'},
      {'name': 'Travel & Safety', 'image': 'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&q=80&w=300'},
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeding default categories...')),
    );

    int count = 0;
    try {
      for (var cat in defaultCats) {
        final name = cat['name']!;
        final query = await FirebaseFirestore.instance
            .collection('categories')
            .where('categoryName', isEqualTo: name)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          final newCat = CategoryModel(
            id: '',
            categoryName: name,
            image: cat['image']!,
          );
          await provider.addCategory(newCat);
          count++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 ? 'Successfully seeded $count new categories!' : 'All default categories already exist.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: category.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: category.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF5F6FA),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF2D3142)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Color(0xFF2196F3), size: 16),
                    onPressed: onEdit,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.red, size: 16),
                    onPressed: onDelete,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: const Center(
        child: Icon(Icons.category_rounded,
            color: AppTheme.primaryColor, size: 40),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existing;
  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  static const _pink = AppTheme.primaryColor;
  final _nameCtrl = TextEditingController();
  File? _pickedImage;
  Uint8List? _webImageBytes; 
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existing != null;
    _nameCtrl.text = widget.existing?.categoryName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    final provider = context.read<CategoryProvider>();
    provider.clearError();

    if (_isEdit) {
      final updated = CategoryModel(
        id: widget.existing!.id,
        categoryName: _nameCtrl.text.trim(),
        image: widget.existing!.image,
      );
      await provider.updateCategory(updated, imageFile: _pickedImage, webBytes: _webImageBytes);
    } else {
      final cat = CategoryModel(id: '', categoryName: _nameCtrl.text.trim(), image: '');
      await provider.addCategory(cat, imageFile: _pickedImage, webBytes: _webImageBytes);
    }
    
    if (context.mounted) {
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Category updated!' : 'Category added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isEdit ? 'Edit Category' : 'Add Category',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color(0xFF2D3142)),
          ),
          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: provider.isLoading ? null : _pickImage, 
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _pink.withOpacity(0.25), width: 1.5),
                ),
                child: kIsWeb
                    ? (_webImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
                          )
                        : widget.existing?.image.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CachedNetworkImage(
                                    imageUrl: widget.existing!.image,
                                    fit: BoxFit.cover),
                              )
                            : _buildPlaceholder())
                    : (_pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                        : widget.existing?.image.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: CachedNetworkImage(
                                    imageUrl: widget.existing!.image,
                                    fit: BoxFit.cover),
                              )
                            : _buildPlaceholder()),
              ),
            ),
          ),

          if (provider.isLoading && provider.uploadProgress > 0) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: provider.uploadProgress,
              backgroundColor: _pink.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(_pink),
              borderRadius: BorderRadius.circular(4),
            ),
          ],

          const SizedBox(height: 20),

          Text('Category Name',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF2D3142))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            enabled: !provider.isLoading, 
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Strollers',
              hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _pink, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isEdit ? 'Update Category' : 'Save Category',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_rounded, color: _pink, size: 30),
        const SizedBox(height: 4),
        Text('Image', style: GoogleFonts.poppins(color: _pink, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}