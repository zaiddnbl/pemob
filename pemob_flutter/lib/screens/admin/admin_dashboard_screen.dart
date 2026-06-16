import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _navyMed = Color(0xFF2D5A4E);
  static const Color _bgGrey = Color(0xFFF4F6F5);

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

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final firstName = user?.nama.split(' ').first ?? 'Admin';

    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Image.asset('assets/images/logo_biru.png', height: 32,
                            errorBuilder: (_, __, ___) => Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: _navyDark,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20))),
                        const SizedBox(width: 8),
                        const Text('SIPESEL', style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w900, color: _navyDark, letterSpacing: 1.5)),
                      ]),
                      CircleAvatar(radius: 20, backgroundColor: _navyDark,
                          child: Text(firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Hi, $firstName!', style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: _navyDark, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
                ],
              ),
            ),
          ),

          // ── Body — StreamBuilder ─────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<PembayaranModel>>(
              stream: FirestoreService.streamSemuaPembayaran(),
              builder: (context, snapPembayaran) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users').where('role', isEqualTo: 'pedagang').snapshots(),
                  builder: (context, snapUsers) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('kios').where('status', isEqualTo: 'aktif').snapshots(),
                      builder: (context, snapKios) {

                        // Loading
                        if (snapPembayaran.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                          );
                        }

                        // Error
                        if (snapPembayaran.hasError) {
                          return Center(child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('Gagal memuat data: ${snapPembayaran.error}',
                                style: const TextStyle(color: AppTheme.errorRed)),
                          ));
                        }

                        final semuaPembayaran = snapPembayaran.data ?? [];
                        final totalPedagang = snapUsers.data?.docs.length ?? 0;
                        final totalKiosAktif = snapKios.data?.docs.length ?? 0;

                        // Hitung statistik bulan ini
                        final now = DateTime.now();
                        final startOfMonth = DateTime(now.year, now.month, 1);
                        double totalPemasukan = 0;
                        int berhasil = 0, pending = 0, ditolak = 0;
                        for (final p in semuaPembayaran) {
                          try {
                            final parts = p.tanggal.split(' ')[0].split('-');
                            final tgl = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                            if (!tgl.isBefore(startOfMonth)) {
                              if (p.status == 'berhasil') { totalPemasukan += p.jumlah; berhasil++; }
                              else if (p.status == 'pending') pending++;
                              else if (p.status == 'ditolak') ditolak++;
                            }
                          } catch (_) {}
                        }

                        final total = berhasil + pending + ditolak;

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: _navyDark,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(children: [
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Dashboard Admin', style: TextStyle(
                                          color: AppTheme.accentYellow, fontSize: 16, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      const Text('Kelola sistem pembayaran\nretribusi Pasar Wadungasri',
                                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 12),
                                      if (pending > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: const Color(0xFFD97706),
                                              borderRadius: BorderRadius.circular(20)),
                                          child: Text('$pending menunggu verifikasi',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16)),
                                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
                                  ),
                                ]),
                              ),

                              const SizedBox(height: 20),

                              // Stats 2x2
                              Row(children: [
                                _statMini('Total Pedagang', '$totalPedagang', Icons.people_rounded, _navyDark),
                                const SizedBox(width: 10),
                                _statMini('Kios Aktif', '$totalKiosAktif', Icons.storefront_rounded, _navyMed),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                _statMini('Pemasukan Bulan Ini', _formatRupiah(totalPemasukan),
                                    Icons.payments_rounded, const Color(0xFF1B6B3A)),
                                const SizedBox(width: 10),
                                _statMini('Menunggu Verifikasi', '$pending',
                                    Icons.pending_rounded, const Color(0xFFB45309)),
                              ]),

                              const SizedBox(height: 20),

                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('Transaksi Masuk', style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: _navyDark)),
                                Text('lihat semua', style: TextStyle(
                                    fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 12),

                              // Grid status
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10, mainAxisSpacing: 10,
                                childAspectRatio: 1.3,
                                children: [
                                  _trxCard('Disetujui', '$berhasil transaksi',
                                      Icons.check_circle_rounded, AppTheme.primaryGreen,
                                      berhasil / (total + 0.001)),
                                  _trxCard('Pending', '$pending transaksi',
                                      Icons.pending_rounded, const Color(0xFFD97706),
                                      pending / (total + 0.001)),
                                  _trxCard('Ditolak', '$ditolak transaksi',
                                      Icons.cancel_rounded, AppTheme.errorRed,
                                      ditolak / (total + 0.001)),
                                  _trxCard('Total', '$total transaksi',
                                      Icons.receipt_long_rounded, _navyDark, 1.0),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Bar chart
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10, offset: const Offset(0, 4))]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      const Text('Statistik Pembayaran', style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w800, color: _navyDark)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _bgGrey,
                                            borderRadius: BorderRadius.circular(20)),
                                        child: const Text('Bulan ini', style: TextStyle(
                                            fontSize: 10, color: AppTheme.greyText, fontWeight: FontWeight.w600)),
                                      ),
                                    ]),
                                    const SizedBox(height: 20),
                                    total == 0
                                        ? const Center(child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text('Belum ada data',
                                            style: TextStyle(color: AppTheme.greyText))))
                                        : SizedBox(
                                      height: 160,
                                      child: BarChart(BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: total.toDouble() * 1.3,
                                        barGroups: [
                                          BarChartGroupData(x: 0, barRods: [BarChartRodData(
                                              toY: berhasil.toDouble(), color: AppTheme.primaryGreen,
                                              width: 36, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
                                          BarChartGroupData(x: 1, barRods: [BarChartRodData(
                                              toY: pending.toDouble(), color: const Color(0xFFD97706),
                                              width: 36, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
                                          BarChartGroupData(x: 2, barRods: [BarChartRodData(
                                              toY: ditolak.toDouble(), color: AppTheme.errorRed,
                                              width: 36, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
                                        ],
                                        titlesData: FlTitlesData(
                                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, _) {
                                                const labels = ['Disetujui', 'Pending', 'Ditolak'];
                                                return Padding(padding: const EdgeInsets.only(top: 6),
                                                    child: Text(labels[val.toInt()],
                                                        style: const TextStyle(fontSize: 10, color: AppTheme.greyText)));
                                              })),
                                          leftTitles: AxisTitles(sideTitles: SideTitles(
                                              showTitles: true, reservedSize: 24,
                                              getTitlesWidget: (val, _) => Text('${val.toInt()}',
                                                  style: const TextStyle(fontSize: 9, color: AppTheme.greyText)))),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                      )),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, IconData icon, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.greyText, height: 1.3), maxLines: 2),
          ])),
        ]),
      ));

  Widget _trxCard(String title, String subtitle, IconData icon, Color color, double progress) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4)),
          ],
        ),
      );
}