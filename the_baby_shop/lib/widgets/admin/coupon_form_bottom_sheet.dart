import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../theme/app_theme.dart';

class CouponFormBottomSheet extends StatefulWidget {
  final CouponModel? existingCoupon;
  const CouponFormBottomSheet({Key? key, this.existingCoupon}) : super(key: key);

  @override
  State<CouponFormBottomSheet> createState() => _CouponFormBottomSheetState();
}

class _CouponFormBottomSheetState extends State<CouponFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _codeCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _maxDiscountCtrl;
  late final TextEditingController _usageLimitCtrl;
  late final TextEditingController _perUserLimitCtrl;

  DiscountType _discountType = DiscountType.percentage;
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  bool _active = true;

  bool get _isEditing => widget.existingCoupon != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCoupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _valueCtrl = TextEditingController(
        text: c != null ? c.discountValue.toStringAsFixed(0) : '');
    _minOrderCtrl = TextEditingController(
        text: c != null ? c.minimumOrder.toStringAsFixed(0) : '0');
    _maxDiscountCtrl = TextEditingController(
        text: c != null ? c.maximumDiscount.toStringAsFixed(0) : '0');
    _usageLimitCtrl = TextEditingController(
        text: c != null ? c.usageLimit.toString() : '0');
    _perUserLimitCtrl = TextEditingController(
        text: c != null ? c.perUserLimit.toString() : '1');

    if (c != null) {
      _discountType = c.discountType;
      _startDate = c.startDate;
      _expiryDate = c.expiryDate;
      _active = c.active;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    _perUserLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _expiryDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be after start date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<CouponProvider>();
    final now = DateTime.now();

    final data = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'discountType': _discountType.value,
      'discountValue': double.tryParse(_valueCtrl.text) ?? 0.0,
      'minimumOrder': double.tryParse(_minOrderCtrl.text) ?? 0.0,
      'maximumDiscount': double.tryParse(_maxDiscountCtrl.text) ?? 0.0,
      'startDate': Timestamp.fromDate(_startDate),
      'expiryDate': Timestamp.fromDate(_expiryDate),
      'usageLimit': int.tryParse(_usageLimitCtrl.text) ?? 0,
      'perUserLimit': int.tryParse(_perUserLimitCtrl.text) ?? 1,
      'active': _active,
      'updatedAt': Timestamp.fromDate(now),
    };

    try {
      if (_isEditing) {
        await provider.updateCoupon(widget.existingCoupon!.id, data);
      } else {
        data['usedCount'] = 0;
        data['usedBy'] = [];
        data['applicableCategories'] = [];
        data['applicableProducts'] = [];
        data['createdAt'] = Timestamp.fromDate(now);
        final coupon = CouponModel(
          id: '',
          code: data['code'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          discountType: _discountType,
          discountValue: data['discountValue'] as double,
          minimumOrder: data['minimumOrder'] as double,
          maximumDiscount: data['maximumDiscount'] as double,
          startDate: _startDate,
          expiryDate: _expiryDate,
          usageLimit: data['usageLimit'] as int,
          usedCount: 0,
          perUserLimit: data['perUserLimit'] as int,
          usedBy: [],
          applicableCategories: [],
          applicableProducts: [],
          active: _active,
          createdAt: now,
          updatedAt: now,
        );
        await provider.createCoupon(coupon);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Coupon updated successfully!'
                : 'Coupon created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStyle = GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Coupon' : 'Create Coupon',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _active
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _active
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _active
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            value: _active,
                            activeColor: Colors.green,
                            onChanged: (v) => setState(() => _active = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    children: [
                      _label('Coupon Code *'),
                      _field(
                        _codeCtrl,
                        hint: 'e.g. SUMMER20',
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Code is required'
                            : null,
                      ),
                      _gap(),
                      _label('Coupon Title *'),
                      _field(_titleCtrl,
                          hint: 'e.g. Summer Sale 20% Off',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Title is required'
                              : null),
                      _gap(),
                      _label('Description'),
                      _field(_descCtrl,
                          hint: 'Short description for this coupon',
                          maxLines: 2),
                      _gap(),

                      // Discount Type
                      _label('Discount Type *'),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonFormField<DiscountType>(
                          value: _discountType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                          ),
                          items: DiscountType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_typeLabel(type),
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _discountType = v!),
                        ),
                      ),
                      _gap(),

                      if (_discountType != DiscountType.freeShipping) ...[
                        _label(_discountType == DiscountType.percentage
                            ? 'Discount Value (%) *'
                            : 'Discount Value (Rs.) *'),
                        _field(_valueCtrl,
                            hint: _discountType == DiscountType.percentage
                                ? '20'
                                : '500',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a valid value';
                          if (_discountType == DiscountType.percentage &&
                              n > 100) return 'Max 100%';
                          return null;
                        }),
                        _gap(),
                      ],

                      _label('Minimum Order Amount (Rs.)'),
                      _field(_minOrderCtrl,
                          hint: '0 = no minimum',
                          keyboardType: TextInputType.number),
                      _gap(),

                      if (_discountType != DiscountType.freeShipping) ...[
                        _label('Maximum Discount (Rs.)'),
                        _field(_maxDiscountCtrl,
                            hint: '0 = no cap',
                            keyboardType: TextInputType.number),
                        _gap(),
                      ],

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Start Date'),
                                GestureDetector(
                                  onTap: () => _pickDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 14,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                            style: dateStyle),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Expiry Date'),
                                GestureDetector(
                                  onTap: () => _pickDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_rounded,
                                            size: 14,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                            '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                                            style: dateStyle),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _gap(),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Usage Limit'),
                                _field(_usageLimitCtrl,
                                    hint: '0 = unlimited',
                                    keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Per-User Limit'),
                                _field(_perUserLimitCtrl,
                                    hint: '1 = single use per user',
                                    keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEditing ? 'Update Coupon' : 'Create Coupon',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      );

  SizedBox _gap() => const SizedBox(height: 16);

  Widget _field(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }

  String _typeLabel(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return 'Percentage (%)';
      case DiscountType.fixed:
        return 'Fixed Amount (Rs.)';
      case DiscountType.freeShipping:
        return 'Free Shipping';
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
