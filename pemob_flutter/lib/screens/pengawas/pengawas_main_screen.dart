import 'package:flutter/material.dart';
import 'pengawas_dashboard_screen.dart';
import 'pengawas_monitoring_screen.dart';
import 'pengawas_laporan_screen.dart';
import 'pengawas_profil_screen.dart';

class PengawasMainScreen extends StatefulWidget {
  const PengawasMainScreen({super.key});

  @override
  State<PengawasMainScreen> createState() => _PengawasMainScreenState();
}

class _PengawasMainScreenState extends State<PengawasMainScreen> {
  int _currentIndex = 0;
  static const Color _teal = Color(0xFF1A3C34);

  final List<Widget> _screens = const [
    PengawasDashboardScreen(),
    PengawasMonitoringScreen(),
    PengawasLaporanScreen(),
    PengawasProfilScreen(),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_outlined,
                    Icons.dashboard_rounded, 'Dashboard', 0),
                _navItem(Icons.monitor_outlined,
                    Icons.monitor_rounded, 'Monitoring', 1),
                _navItem(Icons.description_outlined,
                    Icons.description_rounded, 'Laporan', 2),
                _navItem(Icons.person_outline_rounded,
                    Icons.person_rounded, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _teal : Colors.transparent,
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
                padding: const EdgeInsets.only(left: 6),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 11,
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