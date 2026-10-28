import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_baby_shop/firebase_options.dart';
import 'package:the_baby_shop/providers/admin_provider.dart';
import 'package:the_baby_shop/providers/theme_provider.dart';
import 'package:the_baby_shop/providers/category_provider.dart';
import 'package:the_baby_shop/providers/order_provider.dart';
import 'package:the_baby_shop/providers/product_provider.dart';
import 'package:the_baby_shop/providers/cart_provider.dart';
import 'package:the_baby_shop/providers/wishlist_provider.dart';
import 'package:the_baby_shop/providers/review_provider.dart';
import 'package:the_baby_shop/providers/coupon_provider.dart';
import 'package:the_baby_shop/providers/offers_provider.dart';
import 'package:the_baby_shop/screens/admin/admin_main_shell.dart';
import 'package:the_baby_shop/screens/home/home_screen.dart';
import 'package:the_baby_shop/screens/splash_screen.dart';
import 'package:the_baby_shop/screens/home/order_detail_screen.dart';
import 'package:the_baby_shop/screens/home/order_tracking_screen.dart';
import 'package:the_baby_shop/screens/home/reviews_screen.dart';
import 'package:the_baby_shop/services/auth_service.dart';
import 'package:the_baby_shop/theme/app_theme.dart';

bool _isFirebaseInitialized = false;
String _firebaseInitError = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool initialDarkMode = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    initialDarkMode = prefs.getBool('is_dark_mode') ?? false;
  } catch (e) {
    debugPrint('Failed to load initial theme: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
    _isFirebaseInitialized = true;
  } catch (e) {
    _firebaseInitError = e.toString();
    debugPrint('Firebase init error: $e');
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(initialDarkMode: initialDarkMode)),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => CouponProvider()),
          ChangeNotifierProvider(create: (_) => OffersProvider()),
          ChangeNotifierProxyProvider<CouponProvider, CartProvider>(
            create: (ctx) => CartProvider(ctx.read<CouponProvider>()),
            update: (ctx, coupon, prev) => prev ?? CartProvider(coupon),
          ),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'BabyShopHub',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/orderDetail': (context) => const OrderDetailScreen(orderId: ''),
        '/orderTracking': (context) => const OrderTrackingScreen(orderId: ''),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/reviews')) {
          final uri = Uri.parse(settings.name!);
          String orderId = uri.queryParameters['orderId'] ?? '';
          if (orderId.isEmpty) {
            final segments = uri.pathSegments;
            if (segments.length > 1) {
              orderId = segments[1];
            }
          }
          return MaterialPageRoute(
            builder: (context) => DeepLinkReviewWrapper(orderId: orderId),
          );
        }
        return null;
      },
      home: _isFirebaseInitialized
          ? const AuthWrapper()
          : Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Firebase Not Configured',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Run: flutterfire configure',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_firebaseInitError',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) return const SplashScreen();

        // User is logged in — fetch Firestore doc for role & disabled status.
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              );
            }

            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              // Document doesn't exist yet — show loading briefly then home.
              return const HomeScreen();
            }

            final data =
                docSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final bool isDisabled = data['isDisabled'] ?? false;
            final String role = data['role'] ?? 'user';

            if (isDisabled) {
              // Sign out and inform user.
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await AuthService().signOut();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Account Disabled'),
                      content: const Text(
                          'Your account has been disabled. Please contact support.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              });
              return const SplashScreen(showLoadingOnly: true);
            }

            if (role == 'admin') return const AdminMainShell();
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class DeepLinkReviewWrapper extends StatefulWidget {
  final String orderId;
  const DeepLinkReviewWrapper({Key? key, required this.orderId}) : super(key: key);

  @override
  State<DeepLinkReviewWrapper> createState() => _DeepLinkReviewWrapperState();
}

class _DeepLinkReviewWrapperState extends State<DeepLinkReviewWrapper> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderAndRedirect();
  }

  void _loadOrderAndRedirect() async {
    if (widget.orderId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid Order ID';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _error = 'Order not found';
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No items found in this order to review';
        });
        return;
      }

      // Extract the first item's product ID and name
      final firstItem = items.first as Map<String, dynamic>;
      final productId = firstItem['productId'] ?? '';
      final productName = firstItem['name'] ?? 'Product';

      if (productId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Product details missing';
        });
        return;
      }

      if (mounted) {
        // Redirect to ReviewsScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ReviewsScreen(
              productId: productId,
              productName: productName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load order details';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redirecting to Review'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Loading order details...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _error ?? 'An unknown error occurred.',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}