import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../screens/portfolio_screen.dart';
import '../screens/markets_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatefulWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userEmail = prefs.getString('user_email');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _userEmail;
    
    final hasFAB = widget.currentIndex == 0;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: hasFAB ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.account_balance_wallet_rounded,
              'Portföy',
              0,
              widget.currentIndex == 0,
              userEmail,
            ),
            _buildNavItem(
              context,
              Icons.trending_up_rounded,
              'Piyasalar',
              1,
              widget.currentIndex == 1,
              userEmail,
            ),
            if (hasFAB) const SizedBox(width: 60),
            _buildNavItem(
              context,
              Icons.bar_chart_rounded,
              'Analiz',
              2,
              widget.currentIndex == 2,
              userEmail,
            ),
            _buildNavItem(
              context,
              Icons.person_rounded,
              'Profil',
              3,
              widget.currentIndex == 3,
              userEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isActive,
    String? userEmail,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: isActive
            ? null
            : () {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PortfolioScreen()),
                  );
                } else if (index == 1) {
                  if (userEmail != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketsScreen(userEmail: userEmail),
                      ),
                    );
                  }
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen()),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                }
              },
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
