import 'package:flutter/material.dart';
import '../login_screen.dart';
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
    AdminDashboardScreen(),   // 0
    AdminUserScreen(),         // 1
    AdminKiosScreen(),         // 2
    AdminMonitoringScreen(),   // 3
    AdminLaporanScreen(),      // 4
    AdminTagihanScreen(),      // 5 — FAB
    AdminProfilScreen(),       // 6 — Avatar
  ];

  @override
  Widget build(BuildContext context) {
    // Tentukan index bottom nav yang aktif
    // (5 dan 6 tidak ada di bottom nav, tapi tetap tampil di IndexedStack)
    final bottomActiveIndex = _currentIndex <= 4 ? _currentIndex : -1;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 5),
        backgroundColor: _currentIndex == 5 ? Colors.white : _navyDark,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Tagihan',
        child: Icon(
          Icons.receipt_rounded,
          color: _currentIndex == 5 ? _navyDark : Colors.white,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
              _navItem(Icons.people_outline_rounded, Icons.people_rounded, 'User', 1),
              const SizedBox(width: 48), // Space for FAB
              _navItem(Icons.monitor_outlined, Icons.monitor_rounded, 'Monitoring', 3),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil', 6),
            ],
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
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _navyDark : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _navyDark : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}