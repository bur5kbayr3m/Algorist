import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/portfolio_screen.dart';
import '../screens/markets_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            Icons.account_balance_wallet_rounded,
            'Portföy',
            0,
            currentIndex == 0,
            userEmail,
          ),
          _buildNavItem(
            context,
            Icons.trending_up_rounded,
            'Piyasalar',
            1,
            currentIndex == 1,
            userEmail,
          ),
          const SizedBox(width: 56),
          _buildNavItem(
            context,
            Icons.bar_chart_rounded,
            'Analiz',
            2,
            currentIndex == 2,
            userEmail,
          ),
          _buildNavItem(
            context,
            Icons.person_rounded,
            'Profil',
            3,
            currentIndex == 3,
            userEmail,
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.6),
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.6),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
