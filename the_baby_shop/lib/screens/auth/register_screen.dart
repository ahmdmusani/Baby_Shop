import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:the_baby_shop/screens/auth/login_screen.dart';
import 'package:the_baby_shop/screens/home/home_screen.dart';
import 'package:the_baby_shop/screens/admin/admin_main_shell.dart';
import 'package:the_baby_shop/services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:the_baby_shop/widgets/social_auth_sheets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  void _handleSocialLogin(String provider) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential;
      if (provider == 'Google') {
        try {
          if (kIsWeb) throw 'web_fallback';
          userCredential = await _authService.signInWithGoogle();
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('No implementation found') || errStr.contains('web_fallback')) {
            final result = await GoogleAuthSheet.show(context);
            if (result == null) {
              setState(() => _isLoading = false);
              return;
            }
            userCredential = await _authService.signInWithSocialProvider(
              providerName: 'Google',
              email: result['email']!,
              fullName: result['name']!,
            );
          } else {
            rethrow;
          }
        }
      } else if (provider == 'Facebook') {
        try {
          if (kIsWeb) throw 'web_fallback';
          userCredential = await _authService.signInWithFacebook();
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('No implementation found') || errStr.contains('web_fallback')) {
            final result = await FacebookAuthSheet.show(context);
            if (result == null) {
              setState(() => _isLoading = false);
              return;
            }
            userCredential = await _authService.signInWithSocialProvider(
              providerName: 'Facebook',
              email: result['email']!,
              fullName: result['name']!,
            );
          } else {
            rethrow;
          }
        }
      } else if (provider == 'Apple') {
        try {
          if (kIsWeb) throw 'web_fallback';
          userCredential = await _authService.signInWithApple();
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('No implementation found') || 
              errStr.contains('Unsupported operation') || 
              errStr.contains('web_fallback')) {
            final result = await AppleAuthSheet.show(context);
            if (result == null) {
              setState(() => _isLoading = false);
              return;
            }
            userCredential = await _authService.signInWithSocialProvider(
              providerName: 'Apple',
              email: result['email']!,
              fullName: result['name']!,
            );
          } else {
            rethrow;
          }
        }
      } else {
        throw 'Unsupported authentication provider.';
      }

      if (userCredential.user != null && mounted) {
        final String uid = userCredential.user!.uid;

        // Fetch user document to check role
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String role = data['role'] ?? 'user';

          if (role == 'admin') {
            print("⚡ Admin Access Granted for: ${userCredential.user!.email}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome Admin! Accessing Suite Dashboard...'),
                backgroundColor: Colors.deepPurple,
              ),
            );

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdminMainShell()),
              (route) => false,
            );
            return;
          }
        }

        // Default path
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Social authentication failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy Policy')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmailPassword(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ⚡ Successful Ingestion Callback Handler
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogCtx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Verify Your Email'),
              content: const Text(
                'A verification email has been sent. Please verify your email address to complete registration.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('OK', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 30),
                    
                    Text('Full Name', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    Text('Email', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Enter your email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text('Password', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text('Confirm Password', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms & Privacy Policy',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                    const SizedBox(height: 30),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialIcon(
                          icon: FontAwesomeIcons.facebook,
                          color: const Color(0xFF1877F2),
                          onTap: () => _handleSocialLogin('Facebook'),
                        ),
                        const SizedBox(width: 20),
                        _SocialIcon(
                          icon: FontAwesomeIcons.google,
                          color: const Color(0xFFDB4437),
                          onTap: () => _handleSocialLogin('Google'),
                        ),
                        const SizedBox(width: 20),
                        _SocialIcon(
                          icon: FontAwesomeIcons.apple,
                          color: Colors.black,
                          onTap: () => _handleSocialLogin('Apple'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}