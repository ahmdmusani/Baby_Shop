import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:the_baby_shop/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;
  int _currentPage = 0;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Page Controller Listener for real-time progress calculations (parallax & swirls)
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      }
    });

    // Unified animation controller for the floating/breathing vector elements
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Defining the content data for the three screens
    final List<OnboardingItemData> onboardingItems = [
      OnboardingItemData(
        title: 'Find Everything\nfor Your Baby',
        subtitle: 'Top quality products for your little one',
        illustrationBuilder: (progress, floatingVal) => _buildStrollerIllustration(progress, floatingVal),
      ),
      OnboardingItemData(
        title: 'Secure & Safe\nProducts',
        subtitle: 'Rest easy with certified safety standards',
        illustrationBuilder: (progress, floatingVal) => _buildCarSeatIllustration(progress, floatingVal),
      ),
      OnboardingItemData(
        title: 'Curated for\nComfort',
        subtitle: 'Creation exquisitely greater soft cashmere baby clothes',
        illustrationBuilder: (progress, floatingVal) => _buildCuratedClothesIllustration(progress, floatingVal),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Fluid Swirl Background
          Positioned.fill(
            child: FluidSwirlBackground(pageOffset: _pageOffset),
          ),

          // 2. Main Onboarding Content (PageView with parallax)
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: onboardingItems.length,
                        itemBuilder: (context, index) {
                          final item = onboardingItems[index];
                          // Compute horizontal progress offset for this card:
                          // 0.0 is active center, negative is swiped left, positive is swiped right
                          double progress = index - _pageOffset;

                          return _buildPageCard(item, progress, _floatingAnimation.value);
                        },
                      );
                    },
                  ),
                ),

                // 3. Custom Bottom Navigation Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip Button
                      TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Centered custom pill-shape page indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          onboardingItems.length,
                          (index) => _buildDot(index),
                        ),
                      ),

                      // Right rounded premium button (Next/Done)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == onboardingItems.length - 1) {
                              _navigateToLogin();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.horizontal,
                                child: child,
                              ),
                            ),
                            child: Text(
                              _currentPage == onboardingItems.length - 1 ? 'Done' : 'Next',
                              key: ValueKey<int>(_currentPage),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual Page Card Layout Builder
  Widget _buildPageCard(OnboardingItemData item, double progress, double floatingVal) {
    // Parallax transition values
    final double textParallax = progress * 100.0;
    final double opacity = (1.0 - progress.abs().clamp(0.0, 1.0));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // 3D-styled graphic container with parallax tilt
        Expanded(
          flex: 5,
          child: Center(
            child: IllustrationCard(
              progress: progress,
              child: item.illustrationBuilder(progress, floatingVal),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Headline & Subtitle block
        Expanded(
          flex: 3,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(textParallax, 0.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        item.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Smooth indicator dot
  Widget _buildDot(int index) {
    double selectedPercent = (1.0 - (index - _pageOffset).abs()).clamp(0.0, 1.0);
    double width = 8.0 + (selectedPercent * 16.0); // Active: 24px, Inactive: 8px
    Color color = Color.lerp(
      AppTheme.primaryColor.withOpacity(0.25),
      AppTheme.primaryColor,
      selectedPercent,
    )!;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // GRAPHIC 1: STROLLER
  Widget _buildStrollerIllustration(double progress, double floatingVal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Glow Circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFF4071).withOpacity(0.15),
                const Color(0xFFFF4071).withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Floating baby mobile toy (top right)
        Positioned(
          top: 20 + floatingVal,
          right: 30,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.star, color: Colors.amber, size: 24),
            label: "Toy",
          ),
        ),
        // Floating safety pin / rattle (left)
        Positioned(
          bottom: 40 - floatingVal,
          left: 20,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.child_care, color: Colors.pinkAccent, size: 24),
          ),
        ),
        // Floating baby bottle (bottom right)
        Positioned(
          bottom: 20 + floatingVal,
          right: 20,
          child: _buildSmallFloatCard(
            child: const FaIcon(FontAwesomeIcons.bottleWater, color: Colors.blueAccent, size: 20),
          ),
        ),
        // Central Pink Velvet Stroller
        Transform.translate(
          offset: Offset(0.0, floatingVal * 0.5),
          child: Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                children: [
                  // Gold Chassis Lines
                  Positioned(
                    bottom: 30,
                    left: 45,
                    right: 45,
                    child: CustomPaint(
                      size: const Size(80, 40),
                      painter: StrollerChassisPainter(),
                    ),
                  ),
                  // Wheels
                  Positioned(
                    bottom: 10,
                    left: 35,
                    child: _buildStrollerWheel(),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 35,
                    child: _buildStrollerWheel(),
                  ),
                  // Stroller Basket (pink velvet structure)
                  Positioned(
                    top: 50,
                    left: 28,
                    child: Container(
                      width: 114,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFF699B), Color(0xFFFF4071)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(57),
                          bottomRight: Radius.circular(57),
                          topRight: Radius.circular(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Stroller Canopy (folded cover)
                  Positioned(
                    top: 15,
                    left: 28,
                    child: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(80),
                          topRight: Radius.circular(10),
                        ),
                        border: Border.all(color: const Color(0xFFFFBCC9), width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              width: 50,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE3E8),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Leather Handle
                  Positioned(
                    top: 30,
                    right: 12,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 12,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5E3C), Color(0xFF5C3E25)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrollerWheel() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFD700), width: 3), // Brass-gold rim
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4071),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // GRAPHIC 2: CAR SEAT
  Widget _buildCarSeatIllustration(double progress, double floatingVal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow radial background
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFE0D5).withOpacity(0.2),
                const Color(0xFFFFE0D5).withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Floating high-tech baby monitor (top right)
        Positioned(
          top: 25 + floatingVal,
          right: 25,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.videocam_rounded, color: Colors.teal, size: 22),
          ),
        ),
        // Floating safety shield / lock (left)
        Positioned(
          top: 60 - floatingVal,
          left: 20,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 24),
          ),
        ),
        // Floating pacifier (bottom left)
        Positioned(
          bottom: 25 + floatingVal,
          left: 30,
          child: _buildSmallFloatCard(
            child: const FaIcon(FontAwesomeIcons.circleQuestion, color: Colors.orangeAccent, size: 18),
          ),
        ),
        // Central Baby Car Seat (drawn via containers)
        Transform.translate(
          offset: Offset(0.0, -floatingVal * 0.4),
          child: Center(
            child: Container(
              width: 130,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer shell border/rim (Peach)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7E9F), Color(0xFFFF5C85)],
                        ),
                        borderRadius: BorderRadius.circular(34),
                      ),
                    ),
                  ),
                  // Inner Cushion (Plush grey)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Headrest
                          Positioned(
                            top: 10,
                            child: Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFD4DF), width: 1.5),
                              ),
                            ),
                          ),
                          // Cute Star icon inside (simulating baby details)
                          const Positioned(
                            top: 20,
                            child: Icon(Icons.star, color: Color(0xFFFFBCC9), size: 18),
                          ),
                          // Safety Harness Straps
                          Positioned(
                            top: 50,
                            bottom: 15,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 6, height: 50, color: const Color(0xFFBAC3CF)),
                                const SizedBox(width: 18),
                                Container(width: 6, height: 50, color: const Color(0xFFBAC3CF)),
                              ],
                            ),
                          ),
                          // Center Safety Buckle (Green details)
                          Positioned(
                            bottom: 25,
                            child: Container(
                              width: 20,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2EC4B6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // GRAPHIC 3: CASHMERE CLOTHES & GIFT BOX
  Widget _buildCuratedClothesIllustration(double progress, double floatingVal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow radial background
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD5FFF0).withOpacity(0.18),
                const Color(0xFFD5FFF0).withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Floating porcelain dolphin (top right)
        Positioned(
          top: 20 + floatingVal,
          right: 35,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.waves, color: Colors.cyan, size: 22),
          ),
        ),
        // Floating wooden spoon (left)
        Positioned(
          bottom: 50 - floatingVal,
          left: 15,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
          ),
        ),
        // Curved Arch of Baby Clothes (stack of containers)
        Positioned(
          top: 15,
          left: 40,
          right: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clothes item 1 (Leaning Left)
              Transform.translate(
                offset: const Offset(-35.0, 10.0),
                child: Transform.rotate(
                  angle: -0.25,
                  child: _buildBabyClothesCard(const Color(0xFFFFD4E0), "Pink Onesie"),
                ),
              ),
              // Clothes item 2 (Center back)
              Transform.translate(
                offset: const Offset(0.0, 0.0),
                child: _buildBabyClothesCard(const Color(0xFFD5FFF0), "Mint Jacket"),
              ),
              // Clothes item 3 (Leaning Right)
              Transform.translate(
                offset: const Offset(35.0, 10.0),
                child: Transform.rotate(
                  angle: 0.25,
                  child: _buildBabyClothesCard(const Color(0xFFD6E4FF), "Blue Coat"),
                ),
              ),
            ],
          ),
        ),
        // Velvet Gift Box with Gold Bow and Ribbon
        Positioned(
          bottom: 12,
          child: Transform.translate(
            offset: Offset(0.0, floatingVal * 0.3),
            child: SizedBox(
              width: 110,
              height: 75,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Box Body (Velvet pink)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 90,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5284), Color(0xFFFF3067)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gold Vertical Ribbon Strip
                          Container(width: 12, color: const Color(0xFFFFB300)),
                          // Golden 'H' Monogram
                          Positioned(
                            left: 14,
                            child: Text(
                              'H',
                              style: GoogleFonts.cinzel(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFE6A3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Box Lid (slightly open, tilted)
                  Positioned(
                    bottom: 44,
                    child: Transform.rotate(
                      angle: -0.06,
                      child: Container(
                        width: 96,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF709B),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 14, color: const Color(0xFFFFB300)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Golden bow/ribbon loops (top center)
                  Positioned(
                    bottom: 53,
                    child: Transform.translate(
                      offset: const Offset(0, -2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 16,
                              height: 10,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFFB300), width: 3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Transform.rotate(
                            angle: 0.5,
                            child: Container(
                              width: 16,
                              height: 10,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFFB300), width: 3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBabyClothesCard(Color pastelColor, String semantics) {
    return Container(
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: pastelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: Colors.black.withOpacity(0.2),
          size: 26,
        ),
      ),
    );
  }

  // Small floating cards with icons
  Widget _buildSmallFloatCard({required Widget child, String? label}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }
}

// Custom 3D Illustration Frame
class IllustrationCard extends StatelessWidget {
  final Widget child;
  final double progress;

  const IllustrationCard({Key? key, required this.child, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double angle = progress * 0.15; // Rotational sweep tilt
    final double scale = (1.0 - progress.abs() * 0.1).clamp(0.9, 1.0);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Depth perspective
        ..rotateY(angle)
        ..scale(scale),
      alignment: Alignment.center,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: child,
        ),
      ),
    );
  }
}

// Custom Painter for Stroller chassis structural connections
class StrollerChassisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700) // Brass gold
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Cross bar connections for chassis support
    path.moveTo(10, size.height - 5);
    path.lineTo(size.width - 10, 5);

    path.moveTo(size.width - 10, size.height - 5);
    path.lineTo(10, 5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dynamic Swirl Background Painter
class FluidSwirlBackground extends StatelessWidget {
  final double pageOffset;
  const FluidSwirlBackground({Key? key, required this.pageOffset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 3 premium fluid pastel stops representing design swirl layouts
    final screen1Colors = [
      const Color(0xFFFFF2F6), // Lavender Blush Pink
      const Color(0xFFE6F0FF), // Soft Blue
      const Color(0xFFFFF0F5), // Extra pink swirl
    ];

    final screen2Colors = [
      const Color(0xFFFFFDF0), // Rich Cream
      const Color(0xFFFFEEE0), // Soft Peach
      const Color(0xFFFFEBEF), // Coral base
    ];

    final screen3Colors = [
      const Color(0xFFF1FFF8), // Honeydew mint
      const Color(0xFFE0FCFF), // Soft cyan
      const Color(0xFFEBFDF7), // Soft teal
    ];

    List<Color> currentColors;
    double offsetFraction;

    if (pageOffset <= 1.0) {
      currentColors = _lerpColorList(screen1Colors, screen2Colors, pageOffset);
      offsetFraction = pageOffset;
    } else {
      currentColors = _lerpColorList(screen2Colors, screen3Colors, (pageOffset - 1.0).clamp(0.0, 1.0));
      offsetFraction = pageOffset - 1.0;
    }

    return Stack(
      children: [
        // Plain solid background
        Container(color: currentColors[0]),
        // Blurred Swirl 1
        Positioned(
          top: -100 + (offsetFraction * 60),
          left: -100 - (offsetFraction * 40),
          child: _buildGradientSwirlBubble(350, currentColors[1]),
        ),
        // Blurred Swirl 2
        Positioned(
          bottom: -80 - (offsetFraction * 50),
          right: -100 + (offsetFraction * 80),
          child: _buildGradientSwirlBubble(400, currentColors[2]),
        ),
        // Glassmorphic blur layer to blend colors smoothly
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    return List.generate(a.length, (idx) {
      return Color.lerp(a[idx], b[idx], t) ?? a[idx];
    });
  }

  Widget _buildGradientSwirlBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Data structures mapping items and content layouts
class OnboardingItemData {
  final String title;
  final String subtitle;
  final Widget Function(double progress, double floatingVal) illustrationBuilder;

  OnboardingItemData({
    required this.title,
    required this.subtitle,
    required this.illustrationBuilder,
  });
}
