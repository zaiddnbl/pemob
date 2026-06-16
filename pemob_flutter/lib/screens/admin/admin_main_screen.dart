import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_screen.dart';
import 'admin_kios_screen.dart';
import 'admin_tagihan_screen.dart';
import 'admin_monitoring_screen.dart';
import 'admin_laporan_screen.dart';
import 'admin_profil_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // 0=Home 1=User 2=Kios 3=Monitoring 4=Laporan 5=Tagihan 6=Profil
  int _currentIndex = 0;
  static const Color _navyDark = Color(0xFF1A3C34);

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUserScreen(),
    AdminKiosScreen(),
    AdminMonitoringScreen(),
    AdminLaporanScreen(),
    AdminTagihanScreen(),
    AdminProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _navItem(Icons.people_outline_rounded, Icons.people_rounded, 'User', 1),
                _navItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Kios', 2),
                _navItem(Icons.monitor_outlined, Icons.monitor_rounded, 'Monitor', 3),
                _navItem(Icons.receipt_outlined, Icons.receipt_rounded, 'Tagihan', 5),
                _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            horizontal: isActive ? 12 : 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _navyDark : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.grey.shade400,
              size: 20,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}