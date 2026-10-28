import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_profile_screen.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminProductsScreen(),
    AdminOrdersScreen(),
    AdminUsersScreen(),
    AdminCategoriesScreen(),
    AdminCouponsScreen(),
    AdminProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
    _NavItem(Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Products'),
    _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
    _NavItem(Icons.people_rounded, Icons.people_outlined, 'Users'),
    _NavItem(Icons.category_rounded, Icons.category_outlined, 'Categories'),
    _NavItem(Icons.local_offer_rounded, Icons.local_offer_outlined, 'Coupons'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.black.withOpacity(0.04),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.white,
                selectedIconTheme:
                    const IconThemeData(color: AppTheme.primaryColor),
                unselectedIconTheme:
                    const IconThemeData(color: AppTheme.textSecondary),
                selectedLabelTextStyle: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                unselectedLabelTextStyle: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 12),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFFFF8FB1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.baby_changing_station_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                destinations: _navItems
                    .map((item) => NavigationRailDestination(
                          icon: Icon(item.inactiveIcon),
                          selectedIcon: Icon(item.activeIcon),
                          label: Text(item.label),
                        ))
                    .toList(),
              ),
            ),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 68,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.primaryColor,
                unselectedItemColor: AppTheme.textSecondary,
                selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 10),
                backgroundColor: Colors.white,
                elevation: 0,
                items: _navItems
                    .map((item) => BottomNavigationBarItem(
                          icon: Icon(item.inactiveIcon),
                          activeIcon: Icon(item.activeIcon),
                          label: item.label,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
