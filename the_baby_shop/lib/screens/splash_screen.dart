import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:the_baby_shop/screens/onboarding/onboarding_screen.dart';
import 'package:the_baby_shop/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final bool showLoadingOnly;
  const SplashScreen({super.key, this.showLoadingOnly = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  late AnimationController _loadingController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    
    // Breathing/floating animation for the hero stroller and toys
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Staggered loading controller for triple bouncing dots
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1Animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _dot2Animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.15, 0.75, curve: Curves.easeInOut),
    ));

    _dot3Animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeInOut),
    ));

    // Auto navigate after 3.5 seconds
    if (!widget.showLoadingOnly) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Dynamic Mesh Swirl Background
          Positioned.fill(
            child: _FluidSwirlStaticBackground(),
          ),

          // 2. Centralized Layout
          SafeArea(
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                final floatingVal = _breathingAnimation.value;
                return Column(
                  children: [
                    const Spacer(flex: 3),
                    
                    // 3. Stroller Illustration (No Card Container, floats naturally)
                    Center(
                      child: _buildStrollerIllustration(floatingVal),
                    ),
                    
                    const SizedBox(height: 50),

                    // 4. Premium App Logo (Header)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF699B), Color(0xFFFF4071)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4071).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.child_friendly_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'BabyShopHub',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),

                    // 5. Professional Tagline
                    Text(
                      'Everything for your baby in one place',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const Spacer(flex: 4),

                    // 6. Premium Staggered Bouncing Dots Loader
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BouncingDotsLoader(
                            dot1: _dot1Animation,
                            dot2: _dot2Animation,
                            dot3: _dot3Animation,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Vector Stroller Illustration (Matches Onboarding)
  Widget _buildStrollerIllustration(double floatingVal) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Main Glow Circle behind illustration
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFF4071).withOpacity(0.12),
                const Color(0xFFFF4071).withOpacity(0.0),
              ],
            ),
          ),
        ),
        
        // Floating baby bottle (bottom right)
        Positioned(
          bottom: 25 + floatingVal * 0.8,
          right: -15,
          child: _buildSmallFloatCard(
            child: const FaIcon(FontAwesomeIcons.bottleWater, color: Color(0xFF4A90E2), size: 16),
          ),
        ),

        // Floating toy star (top right)
        Positioned(
          top: 15 + floatingVal * 1.1,
          right: -5,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
          ),
        ),

        // Floating rattle (left center)
        Positioned(
          bottom: 45 - floatingVal * 0.9,
          left: -15,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.child_care_rounded, color: Color(0xFFFF4071), size: 22),
          ),
        ),

        // Floating love heart (top left)
        Positioned(
          top: 25 - floatingVal * 0.7,
          left: 0,
          child: _buildSmallFloatCard(
            child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF699B), size: 16),
          ),
        ),

        // Central Pink Velvet Stroller
        Transform.translate(
          offset: Offset(0.0, floatingVal * 0.5),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gold Chassis Lines
                Positioned(
                  bottom: 35,
                  left: 48,
                  right: 48,
                  child: CustomPaint(
                    size: const Size(84, 42),
                    painter: _StrollerChassisPainter(),
                  ),
                ),
                // Wheels
                Positioned(
                  bottom: 12,
                  left: 36,
                  child: _buildStrollerWheel(),
                ),
                Positioned(
                  bottom: 12,
                  right: 36,
                  child: _buildStrollerWheel(),
                ),
                // Stroller Basket (pink velvet structure)
                Positioned(
                  top: 52,
                  left: 30,
                  child: Container(
                    width: 120,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF699B), Color(0xFFFF4071)],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(58),
                        bottomRight: Radius.circular(58),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4071).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                  ),
                ),
                // Stroller Canopy (folded cover)
                Positioned(
                  top: 16,
                  left: 30,
                  child: Container(
                    width: 84,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(84),
                        topRight: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0xFFFFBCC9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            width: 54,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE3E8),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(54),
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
                  top: 32,
                  right: 14,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      width: 12,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5E3C), Color(0xFF5C3E25)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
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
      ],
    );
  }

  Widget _buildStrollerWheel() {
    return Container(
      width: 40,
      height: 40,
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

  Widget _buildSmallFloatCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }
}

// Custom Painter for Stroller chassis structural connections
class _StrollerChassisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700) // Brass gold
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(10, size.height - 5);
    path.lineTo(size.width - 10, 5);

    path.moveTo(size.width - 10, size.height - 5);
    path.lineTo(10, 5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Static Fluid Swirl background matches onboarding palette
class _FluidSwirlStaticBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid soft lavender/rose base
        Container(color: const Color(0xFFFFF7F9)),
        
        // Soft Blue Swirl (Top-Left)
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Soft Peach Swirl (Center-Right)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: -150,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEB).withOpacity(0.65),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Soft Pink Swirl (Bottom-Left)
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5).withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Backdrop Blur to smoothly blend the shapes into a mesh gradient
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

// Custom staggered bouncing dots loader
class _BouncingDotsLoader extends StatelessWidget {
  final Animation<double> dot1;
  final Animation<double> dot2;
  final Animation<double> dot3;

  const _BouncingDotsLoader({
    Key? key,
    required this.dot1,
    required this.dot2,
    required this.dot3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(dot1, const Color(0xFFFF4071)),
        const SizedBox(width: 8),
        _buildDot(dot2, const Color(0xFF4A90E2)),
        const SizedBox(width: 8),
        _buildDot(dot3, const Color(0xFFFFC107)),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
