import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';
import 'admin_profil_screen.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';



class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalPedagang = 0;
  int _totalKiosAktif = 0;
  double _totalPemasukan = 0;
  int _berhasil = 0, _pending = 0, _ditolak = 0;
  bool _isLoading = true;

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _navyMed = Color(0xFF2D5A4E);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      FirestoreService.getTotalPedagang(),
      FirestoreService.getTotalKiosAktif(),
      FirestoreService.getStatistikBulanIni(),
    ]);
    if (mounted) {
      final stat = results[2] as Map<String, dynamic>;
      setState(() {
        _totalPedagang = results[0] as int;
        _totalKiosAktif = results[1] as int;
        _totalPemasukan = stat['totalMasuk'] as double;
        _berhasil = stat['berhasil'] as int;
        _pending = stat['pending'] as int;
        _ditolak = stat['ditolak'] as int;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toInt()}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              SessionUser.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final firstName = user?.nama.split(' ').first ?? 'Admin';

    return Scaffold(
      backgroundColor: _bgGrey,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Logo + Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _navyDark,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'SIPESEL',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _navyDark,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminProfilScreen()),
                          ).then((_) => setState(() {})),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _navyDark,
                            child: Text(
                              firstName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Hi, $firstName!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _navyDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _greeting(),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.greyText),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _navyDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dashboard Admin',
                                        style: TextStyle(
                                          color: AppTheme.accentYellow,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Kelola sistem pembayaran\nretribusi Pasar Wadungasri',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_pending > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD97706),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$_pending menunggu verifikasi',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Stats 2x2
                          Row(
                            children: [
                              _statMini('Total Pedagang', '$_totalPedagang',
                                  Icons.people_rounded, _navyDark),
                              const SizedBox(width: 10),
                              _statMini('Kios Aktif', '$_totalKiosAktif',
                                  Icons.storefront_rounded, _navyMed),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _statMini('Pemasukan Bulan Ini',
                                  _formatRupiah(_totalPemasukan),
                                  Icons.payments_rounded,
                                  const Color(0xFF1B6B3A)),
                              const SizedBox(width: 10),
                              _statMini('Menunggu Verifikasi', '$_pending',
                                  Icons.pending_rounded,
                                  const Color(0xFFB45309)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Section title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transaksi Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _navyDark,
                                ),
                              ),
                              Text('lihat semua',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Grid status cards
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.3,
                            children: [
                              _trxCard('Disetujui', '$_berhasil transaksi',
                                  Icons.check_circle_rounded,
                                  AppTheme.primaryGreen,
                                  _berhasil / (_berhasil + _pending + _ditolak + 0.001)),
                              _trxCard('Pending', '$_pending transaksi',
                                  Icons.pending_rounded,
                                  const Color(0xFFD97706),
                                  _pending / (_berhasil + _pending + _ditolak + 0.001)),
                              _trxCard('Ditolak', '$_ditolak transaksi',
                                  Icons.cancel_rounded,
                                  AppTheme.errorRed,
                                  _ditolak / (_berhasil + _pending + _ditolak + 0.001)),
                              _trxCard('Total', '${_berhasil + _pending + _ditolak} transaksi',
                                  Icons.receipt_long_rounded,
                                  _navyDark, 1.0),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Chart
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Statistik Pembayaran',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _navyDark)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _bgGrey,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Bulan ini',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.greyText,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                (_berhasil + _pending + _ditolak) == 0
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text('Belum ada data',
                                              style: TextStyle(
                                                  color: AppTheme.greyText)),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 160,
                                        child: BarChart(
                                          BarChartData(
                                            alignment: BarChartAlignment.spaceAround,
                                            maxY: (_berhasil + _pending + _ditolak).toDouble() * 1.3,
                                            barGroups: [
                                              BarChartGroupData(x: 0, barRods: [
                                                BarChartRodData(
                                                  toY: _berhasil.toDouble(),
                                                  color: AppTheme.primaryGreen,
                                                  width: 36,
                                                  borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(8)),
                                                ),
                                              ]),
                                              BarChartGroupData(x: 1, barRods: [
                                                BarChartRodData(
                                                  toY: _pending.toDouble(),
                                                  color: const Color(0xFFD97706),
                                                  width: 36,
                                                  borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(8)),
                                                ),
                                              ]),
                                              BarChartGroupData(x: 2, barRods: [
                                                BarChartRodData(
                                                  toY: _ditolak.toDouble(),
                                                  color: AppTheme.errorRed,
                                                  width: 36,
                                                  borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(8)),
                                                ),
                                              ]),
                                            ],
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (val, _) {
                                                    const labels = ['Disetujui', 'Pending', 'Ditolak'];
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 6),
                                                      child: Text(labels[val.toInt()],
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: AppTheme.greyText)),
                                                    );
                                                  },
                                                ),
                                              ),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 24,
                                                  getTitlesWidget: (val, _) => Text(
                                                    '${val.toInt()}',
                                                    style: const TextStyle(
                                                        fontSize: 9,
                                                        color: AppTheme.greyText),
                                                  ),
                                                ),
                                              ),
                                              topTitles: const AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false)),
                                              rightTitles: const AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false)),
                                            ),
                                            gridData: const FlGridData(show: false),
                                            borderData: FlBorderData(show: false),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statMini(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.greyText,
                          height: 1.3),
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trxCard(String title, String subtitle, IconData icon,
      Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}