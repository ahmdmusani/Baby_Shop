import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/payment_method_model.dart';
import '../widgets/payment_method_card.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  void _setDefaultPayment(String docId) async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;
    
    try {
      // First, set all to false
      final snapshot = await FirebaseFirestore.instance.collection('users/$uid/payment_methods').get();
      for (var doc in snapshot.docs) {
        if (doc.data()['isDefault'] == true) {
          await _firebaseService.updateDocument('users/$uid/payment_methods', doc.id, {'isDefault': false});
        }
      }
      // Set the selected one to true
      await _firebaseService.updateDocument('users/$uid/payment_methods', docId, {'isDefault': true});
    } catch (e) {
      debugPrint("Error setting default payment: $e");
    }
  }

  void _deletePaymentMethod(String docId) async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method?'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firebaseService.deleteDocument('users/$uid/payment_methods', docId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedType = 'visa';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Payment Method', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'visa', child: Text('Visa')),
                        DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Title', hintText: 'e.g. Visa ending in 4342', controller: titleController),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Subtitle', hintText: 'e.g. Expires 12/26', controller: subtitleController),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final uid = _firebaseService.currentUserId;
                      if (uid != null) {
                        await _firebaseService.addDocument('users/$uid/payment_methods', {
                          'type': selectedType,
                          'title': titleController.text.trim(),
                          'subtitle': subtitleController.text.trim(),
                          'isDefault': false,
                        });
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Add', style: TextStyle(color: Colors.white, height: 1.2)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firebaseService.currentUserId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Payment Methods'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: uid == null 
                ? const Center(child: Text("Please log in first"))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebaseService.getCollectionStream('users/$uid/payment_methods'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text("No payment methods found.", style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final payment = PaymentMethodModel.fromMap(docs[index].data(), docs[index].id);
                          Widget iconWidget;
                          if (payment.type == 'upi') iconWidget = _buildUPIIcon();
                          else if (payment.type == 'mastercard') iconWidget = _buildMastercardIcon();
                          else iconWidget = _buildVisaIcon();

                          return PaymentMethodCard(
                            title: payment.title,
                            subtitle: payment.subtitle,
                            icon: iconWidget,
                            isSelected: payment.isDefault,
                            onTap: () => _setDefaultPayment(payment.id),
                            onLongPress: () => _deletePaymentMethod(payment.id),
                          );
                        },
                      );
                    },
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: '+ Add New Payment Method',
                onPressed: () => _showAddDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 8, height: 16, decoration: const BoxDecoration(color: Colors.green, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))),
        Container(width: 8, height: 16, decoration: const BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)))),
        const SizedBox(width: 2),
        Container(width: 8, height: 16, color: Colors.orange),
      ],
    );
  }

  Widget _buildVisaIcon() {
    return const Text('VISA', style: TextStyle(color: Color(0xFF1A1F71), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 16));
  }

  Widget _buildMastercardIcon() {
    return Stack(
      children: [
        Positioned(left: 0, child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.8)))),
        Positioned(left: 12, child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.8)))),
      ],
    );
  }
}
