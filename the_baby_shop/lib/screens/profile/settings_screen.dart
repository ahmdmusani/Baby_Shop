import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../splash_screen.dart';
import 'my_profile_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailPromo = false;
  bool _biometricLogin = false;
  String _selectedLanguage = 'English';
  double _cacheSizeMB = 18.4;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailPromo = prefs.getBool('email_promo') ?? false;
        _biometricLogin = prefs.getBool('biometric_login') ?? false;
        _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }

  void _clearCache() async {
    if (_cacheSizeMB == 0.0) return;
    setState(() {
      _isClearingCache = true;
    });
    // Mock clearing cache delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _cacheSizeMB = 0.0;
      _isClearingCache = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRatingDialog() {
    double selectedStars = 5.0;
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Rate Our App ⭐️'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How is your shopping experience with us? Please rate and leave feedback!'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedStars = starValue.toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Leave feedback comments...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final user = FirebaseAuth.instance.currentUser;
                    try {
                      await FirebaseFirestore.instance.collection('app_ratings').doc().set({
                        'userId': user?.uid ?? 'anonymous',
                        'email': user?.email ?? 'anonymous',
                        'rating': selectedStars,
                        'feedback': feedbackCtrl.text.trim(),
                        'createdAt': Timestamp.now(),
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for rating our app!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Account'),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action is irreversible and all your order history and details will be lost.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  );
                  try {
                    // Delete from Firestore
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                    // Delete user from Firebase Auth
                    await user.delete();
                    // Sign out
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop(); // dismiss loader
                    // Fallback to sign out if delete fails due to recent login required
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out. Please login again and immediately request deletion to verify credentials.'),
                          backgroundColor: Colors.orangeAccent,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('English'),
              _buildLanguageOption('Urdu (اردو)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language || (_selectedLanguage == 'Urdu' && language.startsWith('Urdu'));
    return ListTile(
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language.startsWith('Urdu') ? 'Urdu' : language;
        });
        _savePreference('selected_language', _selectedLanguage);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Section: Profile Quick Settings
          _buildSectionHeader('Account'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Profile Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Edit profile, name, phone number', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfileScreen())),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Manage Addresses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Billing and shipping addresses', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen())),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.payment, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Linked cards and payment options', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: General Preferences
          _buildSectionHeader('Preferences'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive notifications for deals and order updates', style: TextStyle(fontSize: 12)),
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                    _savePreference('push_notifications', val);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                SwitchListTile(
                  title: const Text('Email Promotions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Get weekly discounts and newsletters in email', style: TextStyle(fontSize: 12)),
                  value: _emailPromo,
                  onChanged: (val) {
                    setState(() => _emailPromo = val);
                    _savePreference('email_promo', val);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Toggle between dark and light themes', style: TextStyle(fontSize: 12)),
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(val),
                      activeColor: AppTheme.primaryColor,
                    );
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                ListTile(
                  title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Select application display language', style: TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedLanguage, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    ],
                  ),
                  onTap: _showLanguageSelector,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Security & Privacy
          _buildSectionHeader('Security & Privacy'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Secure login via fingerprint or Face ID', style: TextStyle(fontSize: 12)),
                  value: _biometricLogin,
                  onChanged: (val) {
                    setState(() => _biometricLogin = val);
                    _savePreference('biometric_login', val);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                ListTile(
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Read our data and privacy statement', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Your privacy is important to us. At The Baby Shop, we do not sell or share your personal information with third parties. All data collected is strictly used for order fulfillment, account authentication, and improving user shopping experience.\n\nWe encrypt sensitive checkout transaction details via secure gateways.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Storage & Maintenance
          _buildSectionHeader('Storage & Maintenance'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    _cacheSizeMB > 0 ? 'Free up storage space (Size: ${_cacheSizeMB.toStringAsFixed(1)} MB)' : 'Storage is optimized (Size: 0.0 MB)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: _isClearingCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                        )
                      : TextButton(
                          onPressed: _cacheSizeMB > 0 ? _clearCache : null,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: App Version & Info
          _buildSectionHeader('Info'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                const ListTile(
                  title: Text('App Version', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Text('1.0.4', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                ListTile(
                  title: const Text('Rate Application', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 24),
                  onTap: _showRatingDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Danger Zone / Destructive Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton.icon(
              onPressed: _showDeleteAccountDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 8.0, top: 12.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
