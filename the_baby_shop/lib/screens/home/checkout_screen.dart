import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../features/address/data/models/address_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../models/coupon_model.dart';
import '../profile/addresses_screen.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  AddressModel? selectedAddress;
  late Stream<QuerySnapshot>? _addressesStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _addressesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('addresses')
          .snapshots();
    }
  }




  Widget _buildStepsTimeline() {
    final steps = ['Cart', 'Address', 'Payment', 'Review'];
    const activeStep = 1; // Address step
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isActive = stepIndex < activeStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
            );
          } else {
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == activeStep;
            final isCompleted = stepIndex < activeStep;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isActive || isCompleted) ? AppTheme.primaryColor : AppTheme.borderColor,
                      width: isActive ? 2.5 : 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.w600,
                    color: (isActive || isCompleted) ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Checkout',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _addressesStream,
        builder: (context, snapshot) {
          Widget addressCardWidget;
          bool isButtonEnabled = false;
          AddressModel? currentAddress;

          if (snapshot.hasError) {
            isButtonEnabled = false;
            addressCardWidget = Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            addressCardWidget = const AddressShimmerLoading();
            isButtonEnabled = false;
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            isButtonEnabled = false;
            addressCardWidget = Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off_outlined,
                      size: 36,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No delivery address saved yet',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please add a delivery address to complete checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Add New Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Sort addresses: pick isDefault == true first, fallback to newest createdAt
            final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aDefault = aData['isDefault'] == true;
              final bDefault = bData['isDefault'] == true;
              if (aDefault && !bDefault) return -1;
              if (!aDefault && bDefault) return 1;

              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime != null && bTime != null) {
                return bTime.compareTo(aTime);
              } else if (aTime != null) {
                return -1;
              } else if (bTime != null) {
                return 1;
              }
              return 0;
            });

            // Map documents to address models
            final List<AddressModel> addresses = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docName = data['name'] as String? ?? '';
              final displayName = docName.isNotEmpty
                  ? docName
                  : (FirebaseAuth.instance.currentUser?.displayName ?? 'Customer');

              final docPhone = data['phone'] as String? ?? '';
              final displayPhone = docPhone.isNotEmpty
                  ? docPhone
                  : (FirebaseAuth.instance.currentUser?.phoneNumber ?? '');

              String fullAddress = '';
              if (data.containsKey('addressLine1') || data.containsKey('city') || data.containsKey('zipCode')) {
                final String addressLine1 = data['addressLine1'] as String? ?? '';
                final String city = data['city'] as String? ?? '';
                final String state = data['state'] as String? ?? '';
                final String zipCode = data['zipCode'] as String? ?? '';

                final List<String> parts = [];
                if (addressLine1.isNotEmpty) parts.add(addressLine1);
                if (city.isNotEmpty) parts.add(city);
                if (state.isNotEmpty) parts.add(state);
                if (zipCode.isNotEmpty) parts.add(zipCode);
                fullAddress = parts.join(', ');
              } else {
                fullAddress = data['addressLine'] as String? ?? '';
              }

              return AddressModel(
                id: doc.id,
                title: data['title'] as String? ?? 'Home',
                name: displayName,
                addressLine: fullAddress,
                phone: displayPhone,
              );
            }).toList();

            // Set default selection if none chosen yet or the chosen one is gone
            if (selectedAddress == null || !addresses.any((a) => a.id == selectedAddress!.id)) {
              selectedAddress = addresses.first;
            }

            // Find current selected address
            currentAddress = addresses.firstWhere((a) => a.id == selectedAddress!.id, orElse: () => addresses.first);
            isButtonEnabled = true;

            addressCardWidget = ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, idx) {
                final addr = addresses[idx];
                final isSelected = addr.id == currentAddress!.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAddress = addr;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: addr.id,
                          groupValue: currentAddress!.id,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedAddress = addr;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    addr.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      addr.title.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                addr.addressLine,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (addr.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  addr.phone,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepsTimeline(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Address',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddressesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppTheme.primaryColor),
                            label: const Text(
                              'Add/Manage',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      addressCardWidget,
                      const SizedBox(height: 24),
                      const Text(
                        'Order Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _summaryItem('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                            const SizedBox(height: 12),
                            _summaryItem(
                              'Shipping Fee',
                              cart.deliveryFee == 0 ? 'Free' : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                              valueColor: cart.deliveryFee == 0 ? Colors.green : AppTheme.textPrimary,
                            ),
                            if (cart.discountAmount > 0) ...[
                              const SizedBox(height: 12),
                              Builder(
                                builder: (ctx) {
                                  final coupon = ctx.watch<CouponProvider>().appliedCoupon;
                                  return _summaryItem(
                                    coupon != null ? 'Coupon (${coupon.code})' : 'Discount',
                                    '-Rs. ${cart.discountAmount.toStringAsFixed(0)}',
                                    valueColor: Colors.green,
                                  );
                                },
                              ),
                            ],
                            // Free shipping coupon label
                            Builder(builder: (ctx) {
                              final coupon = ctx.watch<CouponProvider>().appliedCoupon;
                              if (coupon != null &&
                                  coupon.discountType == DiscountType.freeShipping &&
                                  cart.deliveryFee == 0) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    _summaryItem('Free Shipping (${coupon.code})', 'Applied',
                                        valueColor: Colors.green),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: AppTheme.borderColor),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  'Rs. ${cart.total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ],
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
                    child: ElevatedButton(
                      onPressed: !isButtonEnabled
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    address: currentAddress!,
                                    totalAmount: cart.total,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue to Payment',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class AddressShimmerLoading extends StatefulWidget {
  const AddressShimmerLoading({Key? key}) : super(key: key);

  @override
  State<AddressShimmerLoading> createState() => _AddressShimmerLoadingState();
}

class _AddressShimmerLoadingState extends State<AddressShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
