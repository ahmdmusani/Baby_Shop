import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:the_baby_shop/features/payment/data/models/payment_method_model.dart';
import 'package:the_baby_shop/utils/card_validator.dart';
import 'package:flutter/services.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  late Stream<QuerySnapshot> _paymentMethodsStream;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _cardNumberController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _paymentMethodsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save payment methods')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final cardNumber = _cardNumberController.text.trim();
      final expiry = _expiryController.text.trim();
      
      final detectedType = CardValidator.detectCardType(cardNumber);
      final cardType = detectedType.value.toLowerCase();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
        'title': cardNumber,
        'subtitle': 'Expires $expiry',
        'type': cardType,
        'isDefault': false,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method added successfully')),
      );
      
      _nameController.clear();
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding card: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(id)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing card: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildCreditCardPreview(),
            const SizedBox(height: 32),
            _buildAddCardForm(),
            const SizedBox(height: 32),
            if (userId != null) _buildSavedCardsSection(userId),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardPreview() {
    final name = _nameController.text.isEmpty ? 'CUSTOMER NAME' : _nameController.text.toUpperCase();
    final number = _cardNumberController.text.isEmpty ? '**** **** **** ****' : _cardNumberController.text;
    final expiry = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1F24), Color(0xFF2C2D35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background design circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PREMIUM CARD',
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.white.withOpacity(0.6), size: 18),
                        const SizedBox(width: 8),
                        CardValidator.getCardIconWidget(
                          CardValidator.detectCardType(_cardNumberController.text),
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARD HOLDER',
                            style: TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRES',
                          style: TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiry,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String input) {
    input = input.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < input.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += input[i];
    }
    return formatted;
  }

  Widget _buildAddCardForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Cardholder Name',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _cardNumberController,
              label: 'Card Number',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CardNumberInputFormatter(),
              ],
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CardValidator.getCardIconWidget(
                  CardValidator.detectCardType(_cardNumberController.text),
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!CardValidator.isValidCardNumber(v)) return 'Invalid card number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'Expiry (MM/YY)',
                    icon: Icons.calendar_today_rounded,
                    inputFormatters: [
                      CardExpiryInputFormatter(),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!CardValidator.isValidExpiry(v)) {
                        return 'Invalid expiry date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    maxLength: CardValidator.detectCardType(_cardNumberController.text) == CardType.amex ? 4 : 3,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final type = CardValidator.detectCardType(_cardNumberController.text);
                      if (!CardValidator.isValidCVV(v, type)) {
                        final expected = type == CardType.amex ? 4 : 3;
                        return 'Must be $expected digits';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Save Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildSavedCardsSection(String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved Cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _paymentMethodsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card_off_outlined,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No saved cards found',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final payment = PaymentMethodModel.fromMap(data, docs[index].id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            payment.type == 'visa' ? Icons.credit_card : Icons.credit_card_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _parseCardNumber(payment.title),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _parseExpiry(payment.subtitle),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D4D)),
                          onPressed: () => _deleteCard(docs[index].id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _parseCardNumber(String title) {
    final regex = RegExp(r'\d{4}');
    final match = regex.firstMatch(title);
    if (match != null) {
      return '**** **** **** ${match.group(0)}';
    }
    return title;
  }

  String _parseExpiry(String subtitle) {
    final regex = RegExp(r'\d{2}/\d{2}');
    final match = regex.firstMatch(subtitle);
    if (match != null) {
      return 'Expires ${match.group(0)!}';
    }
    return subtitle;
  }
}
