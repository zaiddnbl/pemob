import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PengawasDashboardScreen extends StatefulWidget {
  const PengawasDashboardScreen({super.key});

  @override
  State<PengawasDashboardScreen> createState() =>
      _PengawasDashboardScreenState();
}

class _PengawasDashboardScreenState extends State<PengawasDashboardScreen> {
  int _totalPedagang = 0;
  int _totalKiosAktif = 0;
  double _totalRetribusiBulanIni = 0;
  int _berhasil = 0, _pending = 0, _ditolak = 0;
  bool _isLoading = true;

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
      final statistik = results[2] as Map<String, dynamic>;
      setState(() {
        _totalPedagang = results[0] as int;
        _totalKiosAktif = results[1] as int;
        _totalRetribusiBulanIni = statistik['totalMasuk'] as double;
        _berhasil = statistik['berhasil'] as int;
        _pending = statistik['pending'] as int;
        _ditolak = statistik['ditolak'] as int;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${amount.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final total = _berhasil + _pending + _ditolak;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // ── Header — tombol edit & logout sudah dihapus ──
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard Pengawas',
                          style: TextStyle(
                            color: AppTheme.accentYellow,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Halo, ${user?.nama.split(' ').first ?? 'Pengawas'} 👋',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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
                          // ── Stat Cards ──────────────────
                          Row(
                            children: [
                              Expanded(
                                  child: _statCard(
                                icon: Icons.people_rounded,
                                label: 'Total Pedagang',
                                value: '$_totalPedagang',
                                color: const Color(0xFF1565C0),
                              )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _statCard(
                                icon: Icons.storefront_rounded,
                                label: 'Kios Aktif',
                                value: '$_totalKiosAktif',
                                color: AppTheme.primaryGreen,
                              )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _statCard(
                                icon: Icons.payments_rounded,
                                label: 'Retribusi Bulan Ini',
                                value: _formatRupiah(_totalRetribusiBulanIni),
                                color: const Color(0xFF6A1B9A),
                              )),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Chart Kepatuhan ─────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kepatuhan Pembayaran',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.darkText),
                                ),
                                const Text(
                                  'Bulan ini',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.greyText),
                                ),
                                const SizedBox(height: 20),
                                total == 0
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text(
                                            'Belum ada data pembayaran',
                                            style: TextStyle(
                                                color: AppTheme.greyText),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 200,
                                        child: PieChart(
                                          PieChartData(
                                            sections: [
                                              if (_berhasil > 0)
                                                PieChartSectionData(
                                                  value: _berhasil.toDouble(),
                                                  color: AppTheme.primaryGreen,
                                                  title:
                                                      '$_berhasil\nBerhasil',
                                                  titleStyle: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                  radius: 80,
                                                ),
                                              if (_pending > 0)
                                                PieChartSectionData(
                                                  value: _pending.toDouble(),
                                                  color:
                                                      const Color(0xFFE65100),
                                                  title: '$_pending\nPending',
                                                  titleStyle: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                  radius: 80,
                                                ),
                                              if (_ditolak > 0)
                                                PieChartSectionData(
                                                  value: _ditolak.toDouble(),
                                                  color: AppTheme.errorRed,
                                                  title: '$_ditolak\nDitolak',
                                                  titleStyle: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                  radius: 80,
                                                ),
                                            ],
                                            centerSpaceRadius: 40,
                                            sectionsSpace: 2,
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _legend(AppTheme.primaryGreen, 'Berhasil'),
                                    const SizedBox(width: 16),
                                    _legend(
                                        const Color(0xFFE65100), 'Pending'),
                                    const SizedBox(width: 16),
                                    _legend(AppTheme.errorRed, 'Ditolak'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Summary bottom ──────────────
                          Row(
                            children: [
                              Expanded(
                                child: _summaryCard(
                                  label: 'Total Berhasil',
                                  value: '$_berhasil transaksi',
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryCard(
                                  label: 'Total Pembayaran',
                                  value: '$total transaksi',
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.greyText, height: 1.3)),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.greyText)),
      ],
    );
  }
}