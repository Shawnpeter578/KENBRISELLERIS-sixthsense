import 'package:flutter/material.dart';
import 'package:sixth_sense_app/screens/homescreen.dart';
import 'package:sixth_sense_app/screens/safezone.dart';
import 'package:sixth_sense_app/screens/login_page.dart';
import 'package:sixth_sense_app/screens/profile.dart';
import 'package:sixth_sense_app/services/auth_service.dart';
import 'package:sixth_sense_app/theme/auth_theme.dart';

// TODO: point this at your real profile screen widget
// import 'package:sixth_sense_app/screens/profile_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  static const _titles = ['Home', 'Location', 'Profile'];

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CaneDashboardScreen(),
      const SafeZoneMapScreen(),
      const _ProfilePlaceholder(), // swap with your real ProfileScreen()
    ];

    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AuthColors.textPrimary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Placeholder so this file compiles standalone.
/// Replace with your actual ProfileScreen widget.
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ProfileScreen();
  }
}

// ---------------------------------------------------------------------------
// Custom bottom nav — 3 tabs, floating pill style
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _primary = Color(0xFF2563EB);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE7EDF7);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                  primary: _primary,
                  textSecondary: _textSecondary,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                  primary: _primary,
                  textSecondary: _textSecondary,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                  primary: _primary,
                  textSecondary: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final Color textSecondary;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 0, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? primary : textSecondary,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}