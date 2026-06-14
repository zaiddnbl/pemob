import 'package:flutter/material.dart';
import 'pengawas_dashboard_screen.dart';
import 'pengawas_monitoring_screen.dart';
import 'pengawas_laporan_screen.dart';

class PengawasMainScreen extends StatefulWidget {
  const PengawasMainScreen({super.key});

  @override
  State<PengawasMainScreen> createState() => _PengawasMainScreenState();
}

class _PengawasMainScreenState extends State<PengawasMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PengawasDashboardScreen(),
    PengawasMonitoringScreen(),
    PengawasLaporanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_outlined),
            activeIcon: Icon(Icons.monitor_rounded),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
