import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'pembayaran_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

final GlobalKey<RiwayatScreenState> riwayatScreenKey = GlobalKey<RiwayatScreenState>();
// ✅ Baris 12: Tambahkan GlobalKey untuk Dashboard
final GlobalKey<DashboardScreenState> dashboardScreenKey = GlobalKey<DashboardScreenState>();

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: mainScreenKey);

  static void goToTab(int index) {
    mainScreenKey.currentState?.setTab(index);
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    // ✅ Baris 31: Pasang key ke DashboardScreen
    DashboardScreen(key: dashboardScreenKey),
    const PembayaranScreen(),
    RiwayatScreen(key: riwayatScreenKey),
    const ProfilScreen(),
  ];

  void setTab(int index) {
    setState(() => _currentIndex = index);

    // ✅ Baris 42-44: Refresh saat masuk tab Dashboard (index 0)
    if (index == 0) {
      dashboardScreenKey.currentState?.refreshData();
    }

    // Refresh saat masuk tab Riwayat (index 2)
    if (index == 2) {
      riwayatScreenKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setTab(i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment_rounded),
            label: 'Bayar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}