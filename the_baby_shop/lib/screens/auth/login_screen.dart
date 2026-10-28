import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⚡ Added for role check
import 'package:the_baby_shop/screens/auth/register_screen.dart';
import 'package:the_baby_shop/screens/home/home_screen.dart';
import 'package:the_baby_shop/screens/admin/admin_main_shell.dart'; // ⚡ Added admin core panel shell
import 'package:the_baby_shop/services/auth_service.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:the_baby_shop/forgot_password_screen.dart';
import 'package:the_baby_shop/widgets/social_auth_sheets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _loginError;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_loginError != null) {
      setState(() {
        _loginError = null;
      });
    }
  }

  // ─── ROLE-BASED LOGIN LOGIC ───────────────────────────────────────────────
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Invalid email or password';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Firebase Authentication sign-in
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      
      if (userCredential.user != null && mounted) {
        final String uid = userCredential.user!.uid;

        // 2. Cloud Firestore se live role query fetch karna
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final bool isDisabled = data['isDisabled'] ?? false;

          if (isDisabled) {
            await _authService.signOut();
            setState(() {
              _loginError = 'Your account has been deactivated. Please contact support.';
            });
            return;
          }

          final String role = data['role'] ?? 'user';

          // 3. Conditional Redirect Guard (Admin vs Customer)
          if (role == 'admin') {
            print("⚡ Admin Access Granted for: $email");
            
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
            return; // Controller execution sequence complete
          }
        }

        // Default Routing Path for standard customers
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _loginError = 'Invalid email or password';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSocialLogin(String provider) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
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
        setState(() {
          _loginError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String hintText, {Widget? suffixIcon}) {
    final hasError = _loginError != null;
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      enabledBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            )
          : null,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            )
          : null,
    );
  }

  // ─── UI VIEW INTERFACE DESIGN ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _getInputDecoration('example@mail.com'),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: _getInputDecoration(
                      '********',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  if (_loginError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _loginError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Login'),
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
                  
                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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