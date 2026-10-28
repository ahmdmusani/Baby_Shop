import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:the_baby_shop/screens/auth/login_screen.dart';
import 'package:the_baby_shop/screens/profile/my_profile_screen.dart';
import 'package:the_baby_shop/screens/profile/addresses_screen.dart';
import 'package:the_baby_shop/screens/profile/payment_methods_screen.dart';
import 'package:the_baby_shop/screens/profile/my_orders_screen.dart';
import 'package:the_baby_shop/screens/profile/my_wishlist_screen.dart';
import 'package:the_baby_shop/screens/profile/settings_screen.dart';
import 'package:the_baby_shop/screens/profile/help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Header Background Gradient
            Container(
              height: MediaQuery.of(context).size.height * 0.45, 
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFEBF0), // Clean pastel pink
                    AppTheme.backgroundColor, // Fade into soft off-white
                  ],
                ),
              ),
            ),
            
            // Main Content
            SafeArea(
              bottom: false,
              child: Column(
                children: const [
                  ProfileHeader(),
                  ProfileMenuCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName;
        final email = user?.email;
        final photoURL = user?.photoURL;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            children: [
              // Top Nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E1F24), size: 28),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF1E1F24), size: 24),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Profile Picture with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: photoURL != null && photoURL.isNotEmpty 
                          ? NetworkImage(photoURL) 
                          : null,
                      child: photoURL == null || photoURL.isEmpty
                          ? Center(
                              child: Text(
                                _getInitials(displayName ?? 'Ahmed Musani'),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                           BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // User Info
              if (isLoading)
                Container(
                  height: 28,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                Text(
                  (displayName != null && displayName.isNotEmpty) ? displayName : 'Ahmed Musani',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1F24),
                    letterSpacing: 0.1,
                  ),
                ),
              const SizedBox(height: 6),
              if (isLoading)
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Text(
                  (email != null && email.isNotEmpty) ? email : 'ahmdmusanii@gmail.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF7D8494),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfileScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Addresses',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressesScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.credit_card_outlined,
              title: 'Payment Methods',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.favorite_border_rounded,
              title: 'My Wishlist',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyWishlistScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              iconColor: const Color(0xFF1E1F24),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              },
            ),
            const MenuDivider(),
            ProfileMenuItem(
              icon: Icons.logout_outlined,
              title: 'Logout',
              iconColor: const Color(0xFFB3263B),
              isDestructive: true,
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuDivider extends StatelessWidget {
  const MenuDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFF0F1F5),
        indent: 64,
        endIndent: 8,
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? const Color(0xFFB3263B) : const Color(0xFF1E1F24);
    final bgColor = isDestructive 
        ? const Color(0xFFB3263B).withOpacity(0.08) 
        : AppTheme.primaryColor.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive ? const Color(0xFFB3263B).withOpacity(0.4) : const Color(0xFFB5B7C4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
