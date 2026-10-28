import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/support_option_model.dart';
import 'faq_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  void _handleOptionTap(BuildContext context, SupportOptionModel option) {
    if (option.actionType == 'faq') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FaqScreen()),
      );
    } else {
      // Handle other support actions (e.g. open chat, email, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action: ${option.title}'), backgroundColor: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Help & Support'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firebaseService.getCollectionStream('support_options'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading options: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No support options available.', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
                  }

                  List<SupportOptionModel> options = docs.map((doc) => SupportOptionModel.fromMap(doc.data(), doc.id)).toList();
                  options.sort((a, b) => a.order.compareTo(b.order));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    itemCount: options.length + 1, // +1 for the header text
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 30.0),
                          child: Text(
                            'How can we help you?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }
                      
                      final option = options[index - 1];
                      return _buildOptionTile(
                        context,
                        icon: option.getIcon(),
                        title: option.title,
                        onTap: () => _handleOptionTap(context, option),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Support Illustration/Icon Section at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.headset_mic_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
