import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/address_model.dart';
import '../widgets/address_card.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  void _deleteAddress(String addressId) async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;
    
    try {
      await _firebaseService.deleteDocument('users/$uid/addresses', addressId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddressDialog(BuildContext context, {AddressModel? address}) {
    final isEditing = address != null;
    final titleController = TextEditingController(text: address?.title ?? '');
    final nameController = TextEditingController(text: address?.name ?? '');
    final addressLineController = TextEditingController(text: address?.addressLine ?? '');
    final phoneController = TextEditingController(text: address?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Address' : 'Add New Address', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(label: 'Title (e.g., Home, Office)', hintText: 'Enter title', controller: titleController, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Name', hintText: 'Enter contact name', controller: nameController, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Address', hintText: 'Enter full address', controller: addressLineController, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Phone', hintText: 'Enter phone number', controller: phoneController, validator: (v) => v!.isEmpty ? 'Required' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final uid = _firebaseService.currentUserId;
                  if (uid == null) return;
                  
                  final data = {
                    'title': titleController.text.trim(),
                    'name': nameController.text.trim(),
                    'addressLine': addressLineController.text.trim(),
                    'phone': phoneController.text.trim(),
                  };

                  try {
                    if (isEditing) {
                      await _firebaseService.updateDocument('users/$uid/addresses', address.id, data);
                    } else {
                      await _firebaseService.addDocument('users/$uid/addresses', data);
                    }
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error saving address: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', height: 1.2)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firebaseService.currentUserId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Addresses'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: uid == null 
                ? const Center(child: Text("Please log in first"))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebaseService.getCollectionStream('users/$uid/addresses'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text("No addresses found. Add a new one!", style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final address = AddressModel.fromMap(docs[index].data(), docs[index].id);
                          return AddressCard(
                            title: address.title,
                            name: address.name,
                            address: address.addressLine,
                            phone: address.phone,
                            onEdit: () => _showAddressDialog(context, address: address),
                            onDelete: () => _deleteAddress(address.id),
                          );
                        },
                      );
                    },
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: '+ Add New Address',
                onPressed: () => _showAddressDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
