import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/admin/admin_metric_card.dart';
import '../../widgets/admin/admin_status_chip.dart';
import '../../widgets/admin/admin_charts.dart';
import 'admin_order_details_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final adminName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Admin';
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 165,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_download_rounded, color: AppTheme.primaryColor),
                tooltip: 'Seed Products',
                onPressed: () => _handleSeed(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.04),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.baby_changing_station_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'BabyShopHub Admin',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          adminName,
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main Body with Stats & Charts ────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                );
              }

              final ordersDocs = snap.data?.docs ?? [];
              final orderModels = ordersDocs
                  .map((d) => OrderModel.fromFirestore(d))
                  .toList();
              final revenue = context
                  .read<OrderProvider>()
                  .calculateRevenue(orderModels);

              // Sort for recent orders locally
              final sortedOrders = List<OrderModel>.from(orderModels)
                ..sort((a, b) {
                  if (a.createdAt == null) return 1;
                  if (b.createdAt == null) return -1;
                  return b.createdAt!.compareTo(a.createdAt!);
                });
              final recentOrders = sortedOrders.take(5).toList();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overview',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF2D3142))),
                      const SizedBox(height: 16),

                      // First Row: Total Orders & Revenue
                      Row(
                        children: [
                          Expanded(
                            child: AdminMetricCard(
                              label: 'Total Orders',
                              value: orderModels.length.toString(),
                              icon: Icons.receipt_long_rounded,
                              color: _pink,
                              trend: '+12%',
                              trendUp: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AdminMetricCard(
                              label: 'Gross Revenue',
                              value: currency.format(revenue),
                              leadingText: 'Rs',
                              color: const Color(0xFF4CAF50),
                              trend: '+8%',
                              trendUp: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Second Row: Users & Products
                      Row(
                        children: [
                          // Users count
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(),
                              builder: (ctx, userSnap) => AdminMetricCard(
                                label: 'Total Users',
                                value: (userSnap.data?.docs.length ?? 0).toString(),
                                icon: Icons.people_rounded,
                                color: const Color(0xFF2196F3),
                                trend: '+15%',
                                trendUp: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Products count
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .snapshots(),
                              builder: (ctx, prodSnap) => AdminMetricCard(
                                label: 'Products',
                                value: (prodSnap.data?.docs.length ?? 0).toString(),
                                icon: Icons.inventory_2_rounded,
                                color: const Color(0xFF9C27B0),
                                trend: '+4%',
                                trendUp: true,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Interactive sales trend & status distribution charts
                      AdminCharts(orders: orderModels),

                      const SizedBox(height: 28),

                      // Recent Orders Header
                      Text('Recent Orders',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF2D3142))),
                      const SizedBox(height: 14),

                      if (recentOrders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text('No orders yet.',
                                style: GoogleFonts.poppins(
                                    color: Colors.black38)),
                          ),
                        )
                      else
                        Column(
                          children: recentOrders
                              .map((order) => _RecentOrderTile(order: order))
                              .toList(),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSeed(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Seed Premium Products?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will authenticate using Admin credentials and inject exactly 3 premium products for each of the 8 categories into Firestore (24 products total). Existing products will not be duplicated.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Seed Data', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, height: 1.2)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _pink),
              const SizedBox(height: 16),
              Text(
                'Seeding BabyShopHub...',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Authenticating and injecting products',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  decoration: TextDecoration.none,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final int seededCount = await seedPremiumProducts();
      // Dismiss loading
      Navigator.pop(context);

      // Show success
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text(
                'Success!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Successfully seeded $seededCount new products into Firestore.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Awesome', style: GoogleFonts.poppins(color: Colors.white, height: 1.2)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dismiss loading
      Navigator.pop(context);

      // Show error
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'Seeding Failed',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'An error occurred: $e',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  Future<int> seedPremiumProducts() async {
    // 1. Authenticate using Admin Credentials if needed
    final auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;
    
    if (currentUser == null || currentUser.email != 'ahmdmusanii@gmail.com') {
      try {
        await auth.signInWithEmailAndPassword(
          email: 'ahmdmusanii@gmail.com',
          password: 'ahmed123',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          // Attempt registration
          try {
            final cred = await auth.createUserWithEmailAndPassword(
              email: 'ahmdmusanii@gmail.com',
              password: 'ahmed123',
            );
            if (cred.user != null) {
              await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                'uid': cred.user!.uid,
                'fullName': 'Admin Musani',
                'email': 'ahmdmusanii@gmail.com',
                'role': 'admin',
                'isAdmin': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (signUpError) {
            throw Exception('Could not authenticate or create admin user: $signUpError');
          }
        } else {
          throw Exception('Auth error: ${e.message}');
        }
      }
    }

    // 2. Fetch or create categories
    final firestore = FirebaseFirestore.instance;
    final catImages = {
      'Diapers': 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&q=80&w=300',
      'Feeding': 'https://images.unsplash.com/photo-1522850959013-3a90059b0f01?auto=format&fit=crop&q=80&w=300',
      'Baby Food': 'https://images.unsplash.com/photo-1596263578925-c60f274a4cf4?auto=format&fit=crop&q=80&w=300',
      'Clothing': 'https://images.unsplash.com/photo-1515488042361-404e9250afef?auto=format&fit=crop&q=80&w=300',
      'Toys': 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?auto=format&fit=crop&q=80&w=300',
      'Bath & Care': 'https://images.unsplash.com/photo-1519689680058-324335c77ebe?auto=format&fit=crop&q=80&w=300',
      'Nursery': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=300',
      'Travel & Safety': 'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&q=80&w=300',
    };

    final Map<String, String> categoryIds = {};

    for (var catName in catImages.keys) {
      final query = await firestore
          .collection('categories')
          .where('categoryName', isEqualTo: catName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        categoryIds[catName] = query.docs.first.id;
      } else {
        final docRef = firestore.collection('categories').doc();
        await docRef.set({
          'id': docRef.id,
          'categoryName': catName,
          'image': catImages[catName]!,
          'createdAt': FieldValue.serverTimestamp(),
        });
        categoryIds[catName] = docRef.id;
      }
    }

    // 3. Products list definition
    final productsToSeed = [
      // 1. Diapers
      {
        'name': 'Pampers Premium Care Pants',
        'category': 'Diapers',
        'brand': 'Pampers',
        'price': 25.0,
        'discount': 10.0,
        'desc': 'Pamper your baby with silky soft materials and wetness channels that distribute wetness evenly for up to 12 hours of dry skin.',
        'image': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=600&auto=format&fit=crop',
        'stock': 85,
        'rating': 4.9,
      },
      {
        'name': 'Huggies Wonder Pants Extra Soft',
        'category': 'Diapers',
        'brand': 'Huggies',
        'price': 22.0,
        'discount': 5.0,
        'desc': 'Designed with a soft hug fit elastic waistband and high absorbency core to keep your active baby dry and comfortable all day long.',
        'image': 'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=600&auto=format&fit=crop',
        'stock': 90,
        'rating': 4.8,
      },
      {
        'name': 'MamyPoko Pants Extra Absorb',
        'category': 'Diapers',
        'brand': 'MamyPoko',
        'price': 19.5,
        'discount': 0.0,
        'desc': 'Features crisscross sheet that absorbs urine faster and prevents leakage, keeping the baby smiling and active.',
        'image': 'https://images.unsplash.com/photo-1519689680058-324335c77ebe?q=80&w=600&auto=format&fit=crop',
        'stock': 75,
        'rating': 4.7,
      },

      // 2. Feeding
      {
        'name': 'Avent Anti-Colic Feeding Bottle',
        'category': 'Feeding',
        'brand': 'Philips Avent',
        'price': 15.0,
        'discount': 15.0,
        'desc': 'Clinically proven to reduce colic and discomfort. Features a unique valve integrated into the nipple that flexes to let air into the bottle.',
        'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?q=80&w=600&auto=format&fit=crop',
        'stock': 60,
        'rating': 4.8,
      },
      {
        'name': 'Pigeon SofTouch Peristaltic Sipper',
        'category': 'Feeding',
        'brand': 'Pigeon',
        'price': 12.0,
        'discount': 10.0,
        'desc': 'Supports natural tongue movement. Soft and flexible nipple allows baby to transition smoothly between breastfeeding and bottle-feeding.',
        'image': 'https://images.unsplash.com/photo-1617648356976-56dfd8d46e96?q=80&w=600&auto=format&fit=crop',
        'stock': 80,
        'rating': 4.7,
      },
      {
        'name': 'Medela Harmony Manual Breast Pump',
        'category': 'Feeding',
        'brand': 'Medela',
        'price': 45.0,
        'discount': 8.0,
        'desc': 'Lightweight, portable, and quiet manual breast pump featuring 2-Phase Expression technology for efficient and comfortable milk expression.',
        'image': 'https://images.unsplash.com/photo-1522844990619-4951c40f3eda?q=80&w=600&auto=format&fit=crop',
        'stock': 55,
        'rating': 4.9,
      },

      // 3. Baby Food
      {
        'name': 'Cerelac Wheat Apple with Milk',
        'category': 'Baby Food',
        'brand': 'Nestle',
        'price': 8.5,
        'discount': 0.0,
        'desc': 'Nutritious and convenient baby cereal packed with essential iron, vitamins, and minerals to support healthy growth and development.',
        'image': 'https://images.unsplash.com/photo-1596263576925-d90d63691097?q=80&w=600&auto=format&fit=crop',
        'stock': 100,
        'rating': 4.7,
      },
      {
        'name': 'Gerber Organic Oatmeal Cereal',
        'category': 'Baby Food',
        'brand': 'Gerber',
        'price': 10.0,
        'discount': 12.0,
        'desc': 'USDA Certified Organic cereal made with high-quality ingredients, supporting healthy brain development with 11g of whole grains per serving.',
        'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?q=80&w=600&auto=format&fit=crop',
        'stock': 95,
        'rating': 4.8,
      },
      {
        'name': 'Heinz Smooth Baby Food Puree',
        'category': 'Baby Food',
        'brand': 'Heinz',
        'price': 6.0,
        'discount': 5.0,
        'desc': 'Deliciously smooth apple and pear puree made with 100% natural fruit, perfectly textured for babies starting their solid food journey.',
        'image': 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?q=80&w=600&auto=format&fit=crop',
        'stock': 100,
        'rating': 4.6,
      },

      // 4. Clothing
      {
        'name': 'Premium Organic Cotton Baby Bodysuit',
        'category': 'Clothing',
        'brand': "Carter's",
        'price': 18.0,
        'discount': 10.0,
        'desc': 'Ultra-soft organic cotton bodysuits featuring expandable shoulders and snap closures for quick and easy diaper changes.',
        'image': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?q=80&w=600&auto=format&fit=crop',
        'stock': 70,
        'rating': 4.8,
      },
      {
        'name': 'Soft Velvet Winter Hooded Jacket',
        'category': 'Clothing',
        'brand': 'Next',
        'price': 32.0,
        'discount': 15.0,
        'desc': 'Cozy, lined velvet winter jacket with adorable bear ears on the hood. Keeps your little one snug, warm, and looking cute.',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?q=80&w=600&auto=format&fit=crop',
        'stock': 50,
        'rating': 4.9,
      },
      {
        'name': 'Comfy Denim Dungaree Set',
        'category': 'Clothing',
        'brand': 'Mothercare',
        'price': 28.0,
        'discount': 8.0,
        'desc': 'Fashionable denim dungarees paired with a soft long-sleeve cotton tee. Durable, comfortable, and perfect for playtime.',
        'image': 'https://images.unsplash.com/photo-1519457431-44ccd64a579b?q=80&w=600&auto=format&fit=crop',
        'stock': 65,
        'rating': 4.7,
      },

      // 5. Toys
      {
        'name': 'Super Soft Plush Teddy Bear',
        'category': 'Toys',
        'brand': 'Hamleys',
        'price': 20.0,
        'discount': 10.0,
        'desc': 'Hug-friendly classic teddy bear crafted from high-quality, child-safe plush materials. A perfect comforting companion.',
        'image': 'https://images.unsplash.com/photo-1559251606-c623743a6d76?q=80&w=600&auto=format&fit=crop',
        'stock': 85,
        'rating': 4.9,
      },
      {
        'name': 'Educational Musical Activity Cube',
        'category': 'Toys',
        'brand': 'Fisher-Price',
        'price': 35.0,
        'discount': 20.0,
        'desc': 'Five sides of fun! Features interactive musical keys, bead maze, shape sorting, and gear spinning to develop motor and cognitive skills.',
        'image': 'https://images.unsplash.com/photo-1515488042361-404e9250afef?q=80&w=600&auto=format&fit=crop',
        'stock': 60,
        'rating': 4.8,
      },
      {
        'name': 'Wooden Stacking Rings Shape Sorter',
        'category': 'Toys',
        'brand': 'Melissa & Doug',
        'price': 15.5,
        'discount': 0.0,
        'desc': 'Classic wooden stacking toy with bright, smooth-sanded solid wood rings. Helps teach early color, shape, and size differentiation.',
        'image': 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=600&auto=format&fit=crop',
        'stock': 90,
        'rating': 4.7,
      },

      // 6. Bath & Care
      {
        'name': 'No-Tears Gentle Baby Shampoo',
        'category': 'Bath & Care',
        'brand': "Johnson's Baby",
        'price': 7.0,
        'discount': 5.0,
        'desc': 'As gentle to the eyes as pure water. Hypoallergenic, dermatologist-tested, and free of parabens, phthalates, sulfates, and dyes.',
        'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=600&auto=format&fit=crop',
        'stock': 100,
        'rating': 4.7,
      },
      {
        'name': 'Ultra-Moisturizing Cocoa Butter Lotion',
        'category': 'Bath & Care',
        'brand': 'Aveeno Baby',
        'price': 12.5,
        'discount': 10.0,
        'desc': 'Naturally nourishing lotion formulated with natural oatmeal and rich cocoa butter to soothe and protect dry, sensitive baby skin for 24 hours.',
        'image': 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=600&auto=format&fit=crop',
        'stock': 85,
        'rating': 4.8,
      },
      {
        'name': 'Hypoallergenic Calming Powder',
        'category': 'Bath & Care',
        'brand': 'Cetaphil Baby',
        'price': 9.0,
        'discount': 0.0,
        'desc': 'Soothing baby powder with organic calendula, designed to keep baby dry, soft, and smelling fresh while preventing skin friction.',
        'image': 'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?q=80&w=600&auto=format&fit=crop',
        'stock': 90,
        'rating': 4.8,
      },

      // 7. Nursery
      {
        'name': 'Convertible Wooden Luxury Crib',
        'category': 'Nursery',
        'brand': 'Chicco',
        'price': 199.0,
        'discount': 10.0,
        'desc': 'Premium solid pine wood crib that converts easily to a toddler bed. Features 3-position adjustable mattress support height.',
        'image': 'https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=600&auto=format&fit=crop',
        'stock': 50,
        'rating': 4.9,
      },
      {
        'name': 'Breathable Organic Cotton Bedding Set',
        'category': 'Nursery',
        'brand': 'Snuggle',
        'price': 45.0,
        'discount': 12.0,
        'desc': 'Hypoallergenic organic cotton bedding set including a soft fitted crib sheet, lightweight quilt, and protective bumper wraps.',
        'image': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?q=80&w=600&auto=format&fit=crop',
        'stock': 75,
        'rating': 4.8,
      },
      {
        'name': 'Ergonomic Multi-Position Baby Chair',
        'category': 'Nursery',
        'brand': 'Fisher-Price',
        'price': 60.0,
        'discount': 8.0,
        'desc': 'Adjustable reclining baby seat with calming vibrations and soft toys. Promotes comfort, rest, and tactile stimulation.',
        'image': 'https://images.unsplash.com/photo-1581579438747-1dc8d1e0ca96?q=80&w=600&auto=format&fit=crop',
        'stock': 55,
        'rating': 4.7,
      },

      // 8. Travel & Safety
      {
        'name': 'Lightweight Easy-Fold Compact Stroller',
        'category': 'Travel & Safety',
        'brand': 'Joie',
        'price': 140.0,
        'discount': 10.0,
        'desc': 'Ultra-compact one-hand folding stroller. Features multi-position reclining seat, extendable UPF 50+ canopy, and smooth suspension.',
        'image': 'https://images.unsplash.com/photo-1591938424445-8c5f3583d78d?q=80&w=600&auto=format&fit=crop',
        'stock': 55,
        'rating': 4.8,
      },
      {
        'name': 'All-Stage Convertible Safe Car Seat',
        'category': 'Travel & Safety',
        'brand': 'Graco',
        'price': 180.0,
        'discount': 15.0,
        'desc': 'Designed to protect your child from infant to toddler (4-120 lbs). Features Simply Safe Adjust Harness System and side-impact protection.',
        'image': 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?q=80&w=600&auto=format&fit=crop',
        'stock': 50,
        'rating': 4.9,
      },
      {
        'name': 'Ergonomic 4-in-1 Baby Carrier Comfort',
        'category': 'Travel & Safety',
        'brand': 'Infantino',
        'price': 38.0,
        'discount': 5.0,
        'desc': 'Versatile carrier offering 4 ways to carry your baby: facing-in narrow, facing-in wide, facing-out, and backpack style. Ergonomic seat.',
        'image': 'https://images.unsplash.com/photo-1617331140180-e8262094733a?q=80&w=600&auto=format&fit=crop',
        'stock': 65,
        'rating': 4.8,
      },
    ];

    int count = 0;
    for (var p in productsToSeed) {
      final name = p['name'] as String;
      final categoryName = p['category'] as String;
      final categoryId = categoryIds[categoryName];

      if (categoryId == null) continue;

      // Duplicate check
      final query = await firestore
          .collection('products')
          .where('productName', isEqualTo: name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        final docRef = firestore.collection('products').doc();
        final double price = p['price'] as double;
        final double discountPercent = p['discount'] as double;
        final double discountPrice = price * (1.0 - (discountPercent / 100.0));

        await docRef.set({
          'id': docRef.id,
          'productName': name,
          'category': categoryName,
          'brand': p['brand'] as String,
          'price': price,
          'discount': discountPercent,
          'description': p['desc'] as String,
          'imageUrl': p['image'] as String,
          'stockQuantity': p['stock'] as int,
          'rating': p['rating'] as double,
          
          // Additional Model specific fields
          'categoryId': categoryId,
          'image': p['image'] as String,
          'stock': p['stock'] as int,
          'discountPrice': discountPrice,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }

    return count;
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName.isNotEmpty
                        ? order.customerName
                        : '#${order.id.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(order.totalAmount),
                    style: GoogleFonts.poppins(
                        color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            AdminStatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}
