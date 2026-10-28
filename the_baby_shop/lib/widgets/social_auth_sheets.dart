import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:the_baby_shop/theme/app_theme.dart';

/// Shows a custom bottom sheet matching Google's account chooser UI.
class GoogleAuthSheet extends StatefulWidget {
  const GoogleAuthSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoogleAuthSheet(),
    );
  }

  @override
  State<GoogleAuthSheet> createState() => _GoogleAuthSheetState();
}

class _GoogleAuthSheetState extends State<GoogleAuthSheet> {
  bool _isAddingAccount = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _mockAccounts = [
    {'name': 'Ahmed Raza', 'email': 'ahmed.raza@gmail.com'},
    {'name': 'Sarah Khan', 'email': 'sarah.k@gmail.com'},
    {'name': 'Guest Customer', 'email': 'guest.babyshop@gmail.com'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _selectAccount(String name, String email) {
    Navigator.of(context).pop({'name': name, 'email': email});
  }

  void _submitNewAccount() {
    if (_formKey.currentState!.validate()) {
      _selectAccount(_nameController.text.trim(), _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 24),
              const SizedBox(width: 8),
              Text(
                'Google',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isAddingAccount ? 'Add an account' : 'Choose an account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'to continue to BabyShopHub (Web Simulation Mode)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          if (!_isAddingAccount) ...[
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockAccounts.length,
                separatorBuilder: (_, __) => Divider(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final acc = _mockAccounts[index];
                  final initials = acc['name']!.split(' ').map((e) => e[0]).take(2).join();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _selectAccount(acc['name']!, acc['email']!),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      acc['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      acc['email']!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
            Divider(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => setState(() => _isAddingAccount = true),
              leading: CircleAvatar(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                child: Icon(Icons.person_add_alt_1, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              title: Text(
                'Use another account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Gmail Address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter an email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isAddingAccount = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitNewAccount,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
          Text(
            'To continue, Google will share your name, email address, language preference, and profile picture with BabyShopHub.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a Facebook permissions confirmation flow bottom sheet.
class FacebookAuthSheet extends StatefulWidget {
  const FacebookAuthSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FacebookAuthSheet(),
    );
  }

  @override
  State<FacebookAuthSheet> createState() => _FacebookAuthSheetState();
}

class _FacebookAuthSheetState extends State<FacebookAuthSheet> {
  bool _isCustomLogin = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit(String name, String email) {
    Navigator.of(context).pop({'name': name, 'email': email});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2), size: 24),
              const SizedBox(width: 8),
              Text(
                'facebook',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1877F2),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (!_isCustomLogin) ...[
            Text(
              'Log in with Facebook (Simulation Mode)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackgroundColor : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BabyShopHub is requesting access to:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Name and profile picture', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Email address', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _submit('Alex Mercer', 'alex.mercer@facebook.com'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continue as Alex'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isCustomLogin = true),
              child: const Text(
                'Log in with another account',
                style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Facebook Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter an email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isCustomLogin = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _submit(_nameController.text.trim(), _emailController.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Log In'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Shows an iOS style Apple ID login sheet with automated Face ID animation.
class AppleAuthSheet extends StatefulWidget {
  const AppleAuthSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AppleAuthSheet(),
    );
  }

  @override
  State<AppleAuthSheet> createState() => _AppleAuthSheetState();
}

class _AppleAuthSheetState extends State<AppleAuthSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _authStep = 'confirm'; // confirm, scanning, success, form
  final _emailController = TextEditingController(text: 'm.hassan@icloud.com');
  final _nameController = TextEditingController(text: 'Muhammad Hassan');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startFaceIDScan() {
    setState(() {
      _authStep = 'scanning';
    });
    _animationController.repeat();

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _authStep = 'success';
        });
        _animationController.stop();

        Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final sheetBg = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    final textTheme = isDark ? Colors.white : Colors.black;
    final subTextTheme = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 30 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_authStep == 'confirm') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apple ID',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textTheme,
                  ),
                ),
                Icon(FontAwesomeIcons.apple, color: textTheme, size: 28),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Sign in to BabyShopHub with Apple ID (Simulation Mode).',
              style: TextStyle(fontSize: 15, color: subTextTheme),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textTheme,
                          ),
                        ),
                        Text(
                          _emailController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextTheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _authStep = 'form'),
                    child: const Text('Change', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startFaceIDScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face, size: 20),
                  SizedBox(width: 10),
                  Text('Continue with Face ID', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ] else if (_authStep == 'scanning') ...[
            const SizedBox(height: 30),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: RotationTransition(
                      turns: _animationController,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.face,
                    color: Colors.blueAccent,
                    size: 50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning Face ID...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textTheme,
              ),
            ),
            const SizedBox(height: 30),
          ] else if (_authStep == 'success') ...[
            const SizedBox(height: 30),
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textTheme,
              ),
            ),
            const SizedBox(height: 30),
          ] else if (_authStep == 'form') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Apple ID',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textTheme,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _authStep = 'confirm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      filled: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Apple ID Email',
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      filled: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter an email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _authStep = 'confirm';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
