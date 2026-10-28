import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../features/address/data/models/address_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../models/coupon_model.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../features/payment/data/models/payment_method_model.dart';
import 'order_tracking_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/home/success_dialog.dart';
import '../../services/email_service.dart';
import '../../utils/card_validator.dart';
import 'package:flutter/services.dart';

class PaymentScreen extends StatefulWidget {
  final AddressModel address;
  final double totalAmount;

  const PaymentScreen({
    Key? key,
    required this.address,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String selectedPaymentMethod;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  int selectedSavedCardIndex = 0;
  bool isAddingNewCard = false;

  final List<String> paymentMethods = [
    'Cash on Delivery',
    'Credit / Debit Card',
    'Wallets',
  ];

  late Stream<QuerySnapshot> _paymentMethodsStream;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = 'Cash on Delivery';
    _nameController.addListener(() => setState(() {}));
    _cardNumberController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _cvvController.addListener(() => setState(() {}));

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _paymentMethodsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.06),
                          AppTheme.primaryColor.withOpacity(0.01),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount to Pay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${widget.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SECURE',
                                style: GoogleFonts.poppins(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: paymentMethods.map((method) {
                        final isSelected = selectedPaymentMethod == method;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? AppTheme.primaryColor.withOpacity(0.06) 
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod = method;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                          ),
                                          child: Center(
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 250),
                                              width: isSelected ? 8 : 0,
                                              height: isSelected ? 8 : 0,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? AppTheme.primaryColor.withOpacity(0.08) 
                                                : AppTheme.backgroundColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: _getPaymentIcon(method, isSelected),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          method,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (method == 'Credit / Debit Card' && isSelected) ...[
                                const Divider(height: 1, color: AppTheme.borderColor),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _paymentMethodsStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                                      );
                                    }

                                    final docs = snapshot.data?.docs ?? [];
                                    final bool hasSavedCards = docs.isNotEmpty;

                                    String cardNumberText = '';
                                    String cardHolderText = '';
                                    String cardExpiryText = '';
                                    String? cardType;

                                    if (hasSavedCards && !isAddingNewCard) {
                                      if (selectedSavedCardIndex >= docs.length) {
                                        selectedSavedCardIndex = 0;
                                      }
                                      final data = docs[selectedSavedCardIndex].data() as Map<String, dynamic>;
                                      final payment = PaymentMethodModel.fromMap(data, docs[selectedSavedCardIndex].id);
                                      
                                      cardHolderText = FirebaseAuth.instance.currentUser?.displayName?.toUpperCase() ?? 'CUSTOMER NAME';
                                      cardNumberText = _parseCardNumber(payment.title);
                                      cardExpiryText = _parseExpiry(payment.subtitle);
                                      cardType = payment.type;
                                    } else {
                                      cardHolderText = _nameController.text.isEmpty ? 'CUSTOMER NAME' : _nameController.text.toUpperCase();
                                      cardNumberText = _cardNumberController.text.isEmpty ? '**** **** **** ****' : _cardNumberController.text;
                                      cardExpiryText = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;
                                      cardType = CardValidator.detectCardType(_cardNumberController.text).value;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildCreditCardPreview(
                                            number: cardNumberText,
                                            name: cardHolderText,
                                            expiry: cardExpiryText,
                                            type: cardType,
                                          ),
                                          const SizedBox(height: 20),
                                          if (hasSavedCards) ...[
                                            const Text(
                                              'Saved Cards',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              height: 90,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: docs.length,
                                                itemBuilder: (context, index) {
                                                  final data = docs[index].data() as Map<String, dynamic>;
                                                  final payment = PaymentMethodModel.fromMap(data, docs[index].id);
                                                  final isSelectedCard = selectedSavedCardIndex == index && !isAddingNewCard;
                                                  return _buildSavedCardItem(
                                                    payment: payment,
                                                    isSelected: isSelectedCard,
                                                    onTap: () {
                                                      setState(() {
                                                        selectedSavedCardIndex = index;
                                                        isAddingNewCard = false;
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: isAddingNewCard
                                                  ? TextButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          isAddingNewCard = false;
                                                        });
                                                      },
                                                      icon: const Icon(Icons.credit_card_rounded, color: AppTheme.primaryColor, size: 18),
                                                      label: const Text(
                                                        'Use Saved Card',
                                                        style: TextStyle(
                                                          color: AppTheme.primaryColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    )
                                                  : TextButton.icon(
                                                      onPressed: () {
                                                        setState(() {
                                                          isAddingNewCard = true;
                                                        });
                                                      },
                                                      icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 18),
                                                      label: const Text(
                                                        'Use Another Card',
                                                        style: TextStyle(
                                                          color: AppTheme.primaryColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            child: (hasSavedCards && !isAddingNewCard)
                                                ? const SizedBox.shrink()
                                                : Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      const SizedBox(height: 12),
                                                      _buildAddCardForm(),
                                                    ],
                                                  ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFFFF6B9A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _processPayment(context, cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay Rs. ${widget.totalAmount.toStringAsFixed(0)} Securely',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardPreview({
    required String number,
    required String name,
    required String expiry,
    String? type,
  }) {
    return Container(
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
                          CardValidator.detectCardType(type ?? number),
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
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCardTextField(
          controller: _nameController,
          label: 'Cardholder Name',
          icon: Icons.person_outline_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        _buildCardTextField(
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
              child: _buildCardTextField(
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
              child: _buildCardTextField(
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
      ],
    );
  }

  Widget _buildCardTextField({
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

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    String cardTypeLabel = selectedPaymentMethod;

    if (selectedPaymentMethod == 'Credit / Debit Card') {
      final savedCardsSnap = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .get();

      final bool hasSavedCards = savedCardsSnap.docs.isNotEmpty;

      if (hasSavedCards && !isAddingNewCard) {
        if (selectedSavedCardIndex >= savedCardsSnap.docs.length) {
          selectedSavedCardIndex = 0;
        }
        final doc = savedCardsSnap.docs[selectedSavedCardIndex];
        final type = (doc.data()['type'] as String? ?? 'Card').toUpperCase();
        final title = doc.data()['title'] as String? ?? '';
        final last4 = _parseCardNumber(title).split(' ').last;
        cardTypeLabel = 'Saved Card ($type *$last4)';
      } else {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        final rawNumber = _cardNumberController.text.replaceAll(' ', '');
        final last4 = rawNumber.substring(rawNumber.length - 4);
        final detected = CardValidator.detectCardType(rawNumber);
        final cardName = CardValidator.getCardName(detected);
        cardTypeLabel = 'New Card ($cardName *$last4)';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    try {
      final orderId = firestore.collection('orders').doc().id;

      final orderItems = cart.items.map((item) => OrderItemModel(
        productId: item.productId,
        name: item.productName,
        qty: item.qty,
        price: item.price,
        size: item.size,
        image: item.image,
      )).toList();

      final orderNumber = 'BSH${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final addressStr = '${widget.address.name}, ${widget.address.addressLine}, ${widget.address.phone}';

      // Read applied coupon (if any)
      final couponProvider = context.read<CouponProvider>();
      final appliedCoupon = couponProvider.appliedCoupon;

      final newOrder = OrderModel(
        id: orderId,
        userId: user.uid,
        customerName: user.displayName ?? widget.address.name,
        items: orderItems,
        totalAmount: widget.totalAmount,
        status: 'pending',
        createdAt: DateTime.now(),
        statusHistory: [
          OrderStatusHistoryEntry(
            status: 'pending',
            changedAt: DateTime.now(),
            changedBy: user.uid,
          )
        ],
        shippingAddress: addressStr,
        paymentMethod: cardTypeLabel,
        paymentStatus: selectedPaymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid',
        subtotal: cart.subtotal,
        discountAmount: cart.discountAmount,
        deliveryFee: cart.deliveryFee,
        orderNumber: orderNumber,
        statusTimeline: {
          'pending': DateTime.now(),
        },
        couponCode: appliedCoupon?.code,
        discountType: appliedCoupon?.discountType.value,
        couponTitle: appliedCoupon?.title,
      );

      // Save to global orders collection
      await context.read<OrderProvider>().placeOrder(newOrder);

      // Save a placeholder success order document under users/{userId}/orders
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set({
        'orderId': orderId,
        'totalAmount': widget.totalAmount,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': cardTypeLabel,
      });

      await cart.clearCart();

      // Record coupon usage atomically after order is placed
      if (appliedCoupon != null) {
        try {
          await couponProvider.recordUsage(appliedCoupon.code, user.uid);
        } catch (e) {
          debugPrint('Coupon usage record failed: $e');
        }
      }

      // Send receipt email directly from the client using EmailService
      try {
        final email = user.email ?? 'customer@example.com';
        // Trigger the email sending asynchronously to avoid blocking the UI flow
        EmailService.sendInvoiceEmail(
          toEmail: email,
          subject: 'Thank you for your purchase! - Order #${newOrder.orderNumber}',
          htmlContent: _generateInvoiceEmailHtml(newOrder),
        );
      } catch (mailError) {
        // Log error but do not block checkout success UX
        debugPrint('Failed to send invoice email: $mailError');
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(orderId: orderId),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _getPaymentIcon(String method, bool isSelected) {
    IconData iconData;
    switch (method) {
      case 'Cash on Delivery': iconData = Icons.payments_rounded; break;
      case 'Credit / Debit Card': iconData = Icons.credit_card_rounded; break;
      case 'Wallets': iconData = Icons.account_balance_wallet_rounded; break;
      default: iconData = Icons.payment_rounded;
    }
    return Icon(
      iconData, 
      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary, 
      size: 18,
    );
  }

  Widget _buildSavedCardItem({
    required PaymentMethodModel payment,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3E404D), Color(0xFF25262E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF2C2D35), Color(0xFF1E1F24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    payment.type == 'mastercard' 
                        ? Icons.credit_card_outlined 
                        : Icons.credit_card, 
                    color: Colors.white70, 
                    size: 14,
                  ),
                  Text(
                    payment.type.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                payment.title,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                payment.subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
      return match.group(0)!;
    }
    return subtitle.replaceAll(RegExp(r'expires\s*', caseSensitive: false), '').trim();
  }

  String _generateInvoiceEmailHtml(OrderModel order) {
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt ?? DateTime.now());
    
    final addressParts = order.shippingAddress.split(', ');
    final shippingAddressHtml = addressParts.map((part) => part.trim()).join('<br/>');

    final itemsBuffer = StringBuffer();
    for (var item in order.items) {
      final hasImage = item.image.isNotEmpty;
      final imageHtml = hasImage
          ? '<img src="${item.image}" style="width: 50px; height: 50px; border-radius: 8px; object-fit: cover; background-color: #f8f9fa;" alt="${item.name}"/>'
          : '<div style="width: 50px; height: 50px; border-radius: 8px; background-color: #f8f9fa; display:inline-block; text-align:center; line-height:50px; font-size:10px; color:#cbd5e1;">No Img</div>';
      
      final sizeHtml = item.size.isNotEmpty
          ? '<p style="font-size: 12px; color: #64748b; margin: 4px 0 0 0;">Size: ${item.size}</p>'
          : '';

      itemsBuffer.write('''
        <tr>
          <td style="width: 50px; padding-right: 10px; border-bottom: 1px solid #f1f5f9; padding: 16px 12px; vertical-align: middle;">
            $imageHtml
          </td>
          <td style="border-bottom: 1px solid #f1f5f9; padding: 16px 12px; vertical-align: middle;">
            <p style="font-weight: 600; color: #1e293b; margin: 0; font-size: 14px;">${item.name}</p>
            $sizeHtml
          </td>
          <td style="text-align: center; font-weight: 600; border-bottom: 1px solid #f1f5f9; padding: 16px 12px; vertical-align: middle; font-size: 14px; color: #1e293b;">${item.qty}</td>
          <td style="text-align: right; border-bottom: 1px solid #f1f5f9; padding: 16px 12px; vertical-align: middle; font-size: 14px; color: #1e293b;">Rs. ${item.price.toStringAsFixed(0)}</td>
          <td style="text-align: right; font-weight: 600; border-bottom: 1px solid #f1f5f9; padding: 16px 12px; vertical-align: middle; font-size: 14px; color: #1e293b;">Rs. ${(item.price * item.qty).toStringAsFixed(0)}</td>
        </tr>
      ''');
    }

    String discountRowHtml = '';
    if (order.discountAmount > 0) {
      discountRowHtml = '''
        <tr style="font-size: 14px; color: #475569;">
          <td colspan="4" style="text-align: right; padding: 8px 12px; color: #10b981;">Discount</td>
          <td style="text-align: right; font-weight: 600; padding: 8px 12px; color: #10b981;">-Rs. ${order.discountAmount.toStringAsFixed(0)}</td>
        </tr>
      ''';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Your Order Receipt - ${order.orderNumber}</title>
</head>
<body style="font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8f9fa; margin: 0; padding: 0; -webkit-font-smoothing: antialiased;">
  <div style="width: 100%; background-color: #f8f9fa; padding: 30px 0;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
      <div style="background: linear-gradient(135deg, #FF4B81 0%, #FF6B9A 100%); padding: 40px 30px; text-align: center; color: #ffffff;">
        <h1 style="margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 0.5px;">The Baby Shop</h1>
        <p style="margin: 10px 0 0 0; font-size: 15px; opacity: 0.9;">Your order has been confirmed! 🎉</p>
      </div>
      <div style="padding: 30px;">
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 30px;">
          <tr>
            <td style="width: 50%; vertical-align: top;">
              <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #8c98a5; margin-bottom: 6px; font-weight: 700;">Order Details</div>
              <div style="font-size: 14px; color: #1e293b; line-height: 1.5; font-weight: 600;">Order #${order.orderNumber}</div>
              <div style="font-size: 13px; font-weight: normal; color: #64748b; margin-top: 4px;">$formattedDate</div>
              <div style="font-size: 13px; font-weight: normal; color: #64748b; margin-top: 4px;">Payment: ${order.paymentMethod}</div>
            </td>
            <td style="width: 50%; vertical-align: top; padding-left: 20px;">
              <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #8c98a5; margin-bottom: 6px; font-weight: 700;">Shipping Address</div>
              <div style="font-size: 13px; color: #475569; line-height: 1.5; font-weight: 500;">$shippingAddressHtml</div>
            </td>
          </tr>
        </table>
        
        <div style="font-weight: 700; font-size: 16px; color: #1e293b; margin-bottom: 15px; border-bottom: 2px solid #f1f5f9; padding-bottom: 8px;">
          Items Ordered
        </div>
        
        <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
          <thead>
            <tr>
              <th colspan="2" style="text-align: left; padding: 12px; border-bottom: 2px solid #f1f5f9; color: #475569; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Product</th>
              <th style="text-align: center; padding: 12px; border-bottom: 2px solid #f1f5f9; color: #475569; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Qty</th>
              <th style="text-align: right; padding: 12px; border-bottom: 2px solid #f1f5f9; color: #475569; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Price</th>
              <th style="text-align: right; padding: 12px; border-bottom: 2px solid #f1f5f9; color: #475569; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsBuffer.toString()}
          </tbody>
        </table>
        
        <table style="width: 100%; margin-top: 30px; border-collapse: collapse;">
          <tr style="font-size: 14px; color: #475569;">
            <td colspan="4" style="text-align: right; padding: 8px 12px;">Subtotal</td>
            <td style="text-align: right; font-weight: 600; padding: 8px 12px; color: #1e293b;">Rs. ${order.subtotal.toStringAsFixed(0)}</td>
          </tr>
          $discountRowHtml
          <tr style="font-size: 14px; color: #475569;">
            <td colspan="4" style="text-align: right; padding: 8px 12px;">Delivery Fee</td>
            <td style="text-align: right; font-weight: 600; padding: 8px 12px; color: #1e293b;">Rs. ${order.deliveryFee.toStringAsFixed(0)}</td>
          </tr>
          <tr>
            <td colspan="4" style="text-align: right; font-size: 16px; font-weight: 700; color: #1e293b; padding: 16px 12px; border-top: 2px solid #f1f5f9;">Grand Total</td>
            <td style="text-align: right; font-size: 20px; font-weight: 700; color: #FF4B81; padding: 16px 12px; border-top: 2px solid #f1f5f9;">Rs. ${order.totalAmount.toStringAsFixed(0)}</td>
          </tr>
        </table>
      </div>
      <div style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0;">
        <p style="margin: 0 0 10px 0; font-size: 13px; color: #64748b;">If you have any questions, please contact our support team.</p>
        <p style="margin: 0 0 10px 0; font-size: 13px; color: #64748b;">
          <a href="mailto:support@thebabyshop.com" style="color: #FF4B81; text-decoration: none; font-weight: 600;">support@thebabyshop.com</a>
        </p>
        <p style="font-size: 11px; color: #94a3b8; margin: 15px 0 0 0;">&copy; ${DateTime.now().year} The Baby Shop. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }
}
