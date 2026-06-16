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

  static const Color _green = Color(0xFF1B5E20);

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
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_outlined, Icons.dashboard_rounded,
                    'Dashboard', 0),
                _navItem(Icons.payment_outlined, Icons.payment_rounded,
                    'Bayar', 1),
                _navItem(Icons.history_outlined, Icons.history_rounded,
                    'Riwayat', 2),
                _navItem(Icons.person_outline_rounded, Icons.person_rounded,
                    'Profil', 3),
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
      onTap: () => setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _green : Colors.transparent,
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
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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