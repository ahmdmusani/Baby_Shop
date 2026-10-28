import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/user_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) {
      setState(() => _isFetching = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userProfile = UserProfileModel.fromMap(doc.data()!, doc.id);
        _nameController.text = userProfile.fullName;
        _emailController.text = userProfile.email;
        _phoneController.text = userProfile.phone;
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final uid = _firebaseService.currentUserId;
      if (uid != null) {
        final updatedProfile = UserProfileModel(
          uid: uid,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        try {
          await _firebaseService.setDocument('users', uid, updatedProfile.toMap());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Edit Profile'),
      body: SafeArea(
        child: _isFetching
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar Section
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryLight, width: 2),
                              image: const DecorationImage(
                                image: NetworkImage('https://i.pravatar.cc/150?img=1'), // Dummy avatar for now
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Form Fields
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your full name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      CustomTextField(
                        label: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      CustomTextField(
                        label: 'Phone Number',
                        hintText: 'Enter your phone number',
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _saveChanges,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
