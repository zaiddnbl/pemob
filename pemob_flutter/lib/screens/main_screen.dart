import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';
import 'pembayaran_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();
final GlobalKey<DashboardScreenState> dashboardScreenKey =
GlobalKey<DashboardScreenState>();
final GlobalKey<RiwayatScreenState> riwayatScreenKey =
GlobalKey<RiwayatScreenState>();

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
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    await FirestoreService.seedKios();
    _seeded = true;
  }

  late final List<Widget> _screens = [
    DashboardScreen(key: dashboardScreenKey),
    const PembayaranScreen(),
    RiwayatScreen(key: riwayatScreenKey),
    const ProfilScreen(),
  ];

  void setTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) dashboardScreenKey.currentState?.refreshData();
    if (index == 2) riwayatScreenKey.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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