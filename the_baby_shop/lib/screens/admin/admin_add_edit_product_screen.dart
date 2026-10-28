import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Web check ke liye
import 'dart:typed_data'; // Uint8List ke liye
import 'dart:async'; // StreamSubscription ke liye
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/category_utils.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';

class AdminAddEditProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AdminAddEditProductScreen({super.key, this.product});

  @override
  State<AdminAddEditProductScreen> createState() =>
      _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState
    extends State<AdminAddEditProductScreen> {
  static const _pink = AppTheme.primaryColor;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _stockCtrl;

  String _selectedCategoryId = '';
  File? _pickedImage;
  Uint8List? _webImageBytes; // Web par image preview dikhane ke liye bytes
  String _existingImageUrl = '';
  bool _isEdit = false;

  // Categories state
  List<CategoryModel> _categories = [];
  StreamSubscription<List<CategoryModel>>? _categorySub;

  // Clothing-specific fields state
  final List<String> _availableSizes = const ['0-3M', '3-6M', '6-12M', 'S', 'M', 'L'];
  final List<Map<String, dynamic>> _availableColors = const [
    {'name': 'Pink', 'hex': '#FF4071', 'color': Color(0xFFFF4071)},
    {'name': 'Soft Blue', 'hex': '#ADD8E6', 'color': Color(0xFFADD8E6)},
    {'name': 'Mint Green', 'hex': '#A8E6CF', 'color': Color(0xFFA8E6CF)},
    {'name': 'Pastel Yellow', 'hex': '#FFD3B6', 'color': Color(0xFFFFD3B6)},
    {'name': 'Lavender', 'hex': '#DED2F9', 'color': Color(0xFFDED2F9)},
    {'name': 'White', 'hex': '#FFFFFF', 'color': Color(0xFFFFFFFF)},
    {'name': 'Charcoal', 'hex': '#333333', 'color': Color(0xFF333333)},
  ];

  final List<String> _selectedSizes = [];
  final List<String> _selectedColors = []; // Hex codes
  File? _pickedSizeChartImage;
  Uint8List? _webSizeChartBytes;
  String _existingSizeChartUrl = '';
  late final TextEditingController _fabricCtrl;
  late final TextEditingController _clothingDescCtrl;
  bool _isSizeChartUploading = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.product != null;
    _nameCtrl =
        TextEditingController(text: widget.product?.productName ?? '');
    _descCtrl =
        TextEditingController(text: widget.product?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.product?.price.toString() ?? '');
    _discountCtrl = TextEditingController(
        text: widget.product?.discountPrice.toString() ?? '');
    _stockCtrl = TextEditingController(
        text: widget.product?.stock.toString() ?? '');
    _selectedCategoryId = widget.product?.categoryId ?? '';
    _existingImageUrl = widget.product?.image ?? '';

    // Initialize categories list from provider cache and set up subscription
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    _categories = productProvider.categories;
    _categorySub = productProvider.categoriesStream.listen((list) {
      if (mounted) {
        setState(() {
          _categories = list;
        });
      }
    });

    // Initialize clothing-specific fields
    _fabricCtrl = TextEditingController(text: widget.product?.fabric ?? '');
    _clothingDescCtrl = TextEditingController(text: widget.product?.detailedDescription ?? '');
    if (widget.product?.sizes != null) {
      _selectedSizes.addAll(widget.product!.sizes!);
    }
    if (widget.product?.colors != null) {
      _selectedColors.addAll(widget.product!.colors!);
    }
    _existingSizeChartUrl = widget.product?.sizeChart ?? '';
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _stockCtrl.dispose();
    _fabricCtrl.dispose();
    _clothingDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 75);
          
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _pickedImage = null; // Web par File objects completely block raheinge
          });
          print("✅ DEBUG UI: Web image bytes successfully assigned to state!");
        } else {
          setState(() {
            _pickedImage = File(picked.path);
            _webImageBytes = null;
          });
          print("✅ DEBUG UI: Mobile image path registered successfully!");
        }
      }
    } catch (e) {
      print("❌ ERROR in _pickImage: $e");
    }
  }

  Future<void> _pickSizeChartImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 75);
          
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _webSizeChartBytes = bytes;
            _pickedSizeChartImage = null;
          });
          print("✅ DEBUG UI: Web size chart bytes successfully assigned!");
        } else {
          setState(() {
            _pickedSizeChartImage = File(picked.path);
            _webSizeChartBytes = null;
          });
          print("✅ DEBUG UI: Mobile size chart path registered successfully!");
        }
      }
    } catch (e) {
      print("❌ ERROR in _pickSizeChartImage: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // Agar na image upload hui hai aur na pehle se koi link mojood hai
    if (!kIsWeb && _pickedImage == null && _existingImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }
    if (kIsWeb && _webImageBytes == null && _existingImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }

    final provider = context.read<ProductProvider>();
    final isClothing = CategoryUtils.isClothingProduct(_selectedCategoryId, _categories);

    // Size Chart Upload Logic
    String sizeChartUrl = _existingSizeChartUrl;
    if (isClothing) {
      if (_pickedSizeChartImage != null || _webSizeChartBytes != null) {
        setState(() {
          _isSizeChartUploading = true;
        });
        try {
          sizeChartUrl = await CloudinaryService.uploadToCloudinary(
            imageFile: _pickedSizeChartImage,
            webImageBytes: _webSizeChartBytes,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload size chart image: $e')),
          );
          setState(() {
            _isSizeChartUploading = false;
          });
          return;
        }
        setState(() {
          _isSizeChartUploading = false;
        });
      }
    }

    final product = ProductModel(
      id: widget.product?.id ?? '',
      productName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      discountPrice: double.tryParse(_discountCtrl.text) ?? 0,
      categoryId: _selectedCategoryId,
      image: _existingImageUrl,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      sizes: isClothing ? _selectedSizes : null,
      colors: isClothing ? _selectedColors : null,
      sizeChart: isClothing ? sizeChartUrl : null,
      fabric: isClothing ? _fabricCtrl.text.trim() : null,
      detailedDescription: isClothing ? _clothingDescCtrl.text.trim() : null,
    );

    // ✅ FIXED: Ab webImageBytes successfully provider tak jayenge binary stream me!
    if (_isEdit) {
      await provider.updateProduct(
        product, 
        imageFile: _pickedImage,
        webImageBytes: _webImageBytes,
      );
    } else {
      await provider.addProduct(
        product, 
        imageFile: _pickedImage,
        webImageBytes: _webImageBytes,
      );
    }

    if (context.mounted && provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Product updated successfully!'
              : 'Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final bool hasNewImage = kIsWeb ? (_webImageBytes != null) : (_pickedImage != null);
    final isClothing = CategoryUtils.isClothingProduct(_selectedCategoryId, _categories);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text(
          _isEdit ? 'Edit Product' : 'Add Product',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              _formCard(
                title: 'Basic Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: _pink.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: _pink.withOpacity(0.25), width: 1.5),
                          ),
                          child: hasNewImage
                              ? Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: kIsWeb
                                        ? Image.memory(_webImageBytes!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover)
                                        : Image.file(_pickedImage!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pickedImage = null;
                                          _webImageBytes = null;
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ])
                              : _existingImageUrl.isNotEmpty
                                  ? Stack(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: CachedNetworkImage(
                                          imageUrl: _existingImageUrl,
                                          width: 130,
                                          height: 130,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(color: _pink),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: _pink,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.edit,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ])
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_photo_alternate_rounded,
                                            color: _pink, size: 32),
                                        const SizedBox(height: 6),
                                        Text('Upload Image',
                                            style: GoogleFonts.poppins(
                                                color: _pink,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    if (provider.isLoading && provider.uploadProgress > 0) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: provider.uploadProgress,
                        backgroundColor: _pink.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(_pink),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${(provider.uploadProgress * 100).toInt()}% uploaded',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.black45),
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 16),
                    _buildLabel('Product Name'),
                    _buildTextField(_nameCtrl, 'e.g. Pampers Diapers',
                        validator: (v) =>
                            v!.isEmpty ? 'Product name is required' : null),
                    _buildLabel('Description'),
                    _buildTextField(_descCtrl, 'Product description...',
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'Description is required' : null),
                    _buildLabel('Category'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId.isEmpty
                              ? null
                              : _selectedCategoryId,
                          hint: Text('Select category',
                              style: GoogleFonts.poppins(
                                  color: Colors.black38, fontSize: 14)),
                          isExpanded: true,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.categoryName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v ?? ''),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pricing & Inventory Card
              _formCard(
                title: 'Pricing & Inventory',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Price (Rs.)'),
                              _buildTextField(_priceCtrl, '0',
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final d = double.tryParse(v);
                                    if (d == null) return 'Invalid number';
                                    if (d <= 0) return 'Must be positive';
                                    return null;
                                  }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Discounted Price (Rs.)'),
                              _buildTextField(_discountCtrl, '0',
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return null;
                                    final d = double.tryParse(v);
                                    if (d == null) return 'Invalid number';
                                    if (d < 0) return 'Cannot be negative';
                                    final p = double.tryParse(_priceCtrl.text) ?? 0;
                                    if (d > p) return 'Cannot exceed Price';
                                    return null;
                                  }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _buildLabel('Stock Quantity'),
                    _buildTextField(_stockCtrl, '0',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = int.tryParse(v);
                          if (n == null) return 'Invalid integer';
                          if (n < 0) return 'Cannot be negative';
                          return null;
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clothing Card (Conditional)
              if (isClothing) ...[
                _formCard(
                  title: 'Clothing Attributes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Sizes'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSizes.map((size) {
                          final isSelected = _selectedSizes.contains(size);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(size,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected ? _pink : Colors.black87)),
                            selectedColor: _pink.withOpacity(0.12),
                            checkmarkColor: _pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? _pink : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSizes.add(size);
                                } else {
                                  _selectedSizes.remove(size);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      _buildLabel('Colors'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableColors.map((colorMap) {
                          final hex = colorMap['hex'] as String;
                          final color = colorMap['color'] as Color;
                          final isSelected = _selectedColors.contains(hex);
                          final isWhite = hex == '#FFFFFF';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedColors.remove(hex);
                                } else {
                                  _selectedColors.add(hex);
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _pink
                                      : (isWhite ? Colors.black26 : Colors.transparent),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: isWhite ? Colors.black : Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      _buildLabel('Size Chart Image'),
                      GestureDetector(
                        onTap: _pickSizeChartImage,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: _pink.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _pink.withOpacity(0.15), width: 1.5),
                          ),
                          child: _isSizeChartUploading
                              ? const Center(
                                  child: CircularProgressIndicator(color: _pink),
                                )
                              : (_webSizeChartBytes != null || _pickedSizeChartImage != null)
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: kIsWeb
                                              ? Image.memory(_webSizeChartBytes!,
                                                  width: double.infinity,
                                                  height: 150,
                                                  fit: BoxFit.contain)
                                              : Image.file(_pickedSizeChartImage!,
                                                  width: double.infinity,
                                                  height: 150,
                                                  fit: BoxFit.contain),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _pickedSizeChartImage = null;
                                                _webSizeChartBytes = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white, size: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : _existingSizeChartUrl.isNotEmpty
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: CachedNetworkImage(
                                                imageUrl: _existingSizeChartUrl,
                                                width: double.infinity,
                                                height: 150,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                color: _pink)),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(Icons.error_outline,
                                                        color: Colors.red),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: _pickSizeChartImage,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: const BoxDecoration(
                                                    color: _pink,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.edit,
                                                      color: Colors.white, size: 14),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add_photo_alternate_outlined,
                                                color: _pink, size: 32),
                                            const SizedBox(height: 6),
                                            Text('Upload Size Chart Image',
                                                style: GoogleFonts.poppins(
                                                    color: _pink,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                        ),
                      ),
                      _buildLabel('Fabric / Material'),
                      _buildTextField(_fabricCtrl, 'e.g. 100% Cotton'),
                      _buildLabel('Detailed Description (Care/Fit)'),
                      _buildTextField(_clothingDescCtrl, 'e.g. Machine wash cold. True to size.', maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (provider.isLoading || _isSizeChartUploading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: (provider.isLoading || _isSizeChartUploading)
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isEdit ? 'Update Product' : 'Save Product',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF2D3142),
            ),
          ),
          const Divider(height: 20, thickness: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF2D3142))),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
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
          borderSide:
              const BorderSide(color: Color(0xFFFF4071), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}