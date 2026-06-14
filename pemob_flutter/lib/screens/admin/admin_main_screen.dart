import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_screen.dart';
import 'admin_kios_screen.dart';
import 'admin_tagihan_screen.dart';
import 'admin_pembayaran_screen.dart';
import 'admin_laporan_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  static const Color _navyDark = Color(0xFF1A3C34);

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUserScreen(),
    AdminKiosScreen(),
    AdminPembayaranScreen(),
    AdminLaporanScreen(),
  ];

  void _onFabTap() {
    // Buka tagihan screen sebagai modal / navigate
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminTagihanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        backgroundColor: _navyDark,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 26),
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
              _navItem(Icons.payment_outlined, Icons.payment_rounded, 'Monitoring', 3),
              _navItem(Icons.description_outlined, Icons.description_rounded, 'Laporan', 4),
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