import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../address/presentation/screens/address_management_screen.dart';
import '../../../payment/presentation/screens/payment_methods_screen.dart';
import '../../../support/presentation/screens/help_support_screen.dart';
import '../../../support/presentation/screens/faq_screen.dart';

class HomePreviewScreen extends StatelessWidget {
  const HomePreviewScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Screens Preview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildMenuCard(
              context,
              title: 'Edit Profile',
              icon: Icons.person_outline,
              onTap: () => _navigateTo(context, const EditProfileScreen()),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Address Management',
              icon: Icons.location_on_outlined,
              onTap: () => _navigateTo(context, const AddressManagementScreen()),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Payment Methods',
              icon: Icons.payment_outlined,
              onTap: () => _navigateTo(context, const PaymentMethodsScreen()),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Help & Support',
              icon: Icons.support_agent_outlined,
              onTap: () => _navigateTo(context, const HelpSupportScreen()),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'FAQs',
              icon: Icons.help_outline,
              onTap: () => _navigateTo(context, const FaqScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
