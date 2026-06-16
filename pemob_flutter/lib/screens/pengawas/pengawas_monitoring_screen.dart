import 'package:flutter/material.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PengawasMonitoringScreen extends StatefulWidget {
  const PengawasMonitoringScreen({super.key});

  @override
  State<PengawasMonitoringScreen> createState() =>
      _PengawasMonitoringScreenState();
}

class _PengawasMonitoringScreenState
    extends State<PengawasMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color _teal = Color(0xFF1A3C34);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo_biru.png',
                          height: 28,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront_rounded,
                              color: _teal, size: 28)),
                      const SizedBox(width: 8),
                      const Text('SIPESEL',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _teal,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Monitoring',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _teal)),
                  const Text('Pantau pembayaran pedagang',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.greyText)),
                  const SizedBox(height: 14),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: _teal,
                    indicatorWeight: 3,
                    labelColor: _teal,
                    unselectedLabelColor: AppTheme.greyText,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Monitoring Pembayaran'),
                      Tab(text: 'Statistik'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _MonitoringTab(),
                  _StatistikTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Monitoring ───────────────────────────────────────────────
class _MonitoringTab extends StatefulWidget {
  const _MonitoringTab();

  @override
  State<_MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<_MonitoringTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = 'semua';

  static const Color _teal = Color(0xFF1A3C34);

  @override
  void initState() {
    super.initState();
    // listener untuk rebuild saat search berubah
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PembayaranModel> _applyFilter(List<PembayaranModel> data) {
    final q = _searchCtrl.text.toLowerCase();
    return data.where((p) {
      final matchQ = q.isEmpty ||
          p.noKios.toLowerCase().contains(q) ||
          p.namaPedagang.toLowerCase().contains(q);
      final matchStatus =
          _filterStatus == 'semua' || p.status == _filterStatus;
      return matchQ && matchStatus;
    }).toList();
  }

  void _setFilter(String val) => setState(() => _filterStatus = val);

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'berhasil': return AppTheme.primaryGreen;
      case 'pending':  return const Color(0xFFD97706);
      default:         return AppTheme.errorRed;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'berhasil': return 'Disetujui';
      case 'pending':  return 'Pending';
      default:         return 'Ditolak';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PembayaranModel>>(
      stream: FirestoreService.streamSemuaPembayaran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.errorRed)));
        }

        final allData = snapshot.data ?? [];
        final filtered = _applyFilter(allData);
        final berhasil = allData.where((p) => p.status == 'berhasil').length;
        final pending  = allData.where((p) => p.status == 'pending').length;
        final totalNominal = allData
            .where((p) => p.status == 'berhasil')
            .fold(0.0, (s, p) => s + p.jumlah);

        return Column(
          children: [
            // Summary cards
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _summaryCard('Disetujui', '$berhasil', AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  _summaryCard('Pending', '$pending', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _summaryCard('Total Masuk', _formatRupiah(totalNominal), _teal),
                ],
              ),
            ),

            // Search + filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari kios / nama pedagang...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.greyText),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.greyText, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _teal, width: 1.5)),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchCtrl,
                        builder: (_, val, __) => val.text.isNotEmpty
                            ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchCtrl.clear())
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('semua', 'Semua'),
                      const SizedBox(width: 6),
                      _chip('berhasil', 'Disetujui'),
                      const SizedBox(width: 6),
                      _chip('pending', 'Pending'),
                      const SizedBox(width: 6),
                      _chip('ditolak', 'Ditolak'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  final color = _statusColor(p.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: _teal.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                child: Text(
                                  p.namaPedagang.isNotEmpty
                                      ? p.namaPedagang[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _teal),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.namaPedagang.isNotEmpty
                                          ? p.namaPedagang
                                          : '-',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _teal),
                                    ),
                                    Text(
                                      'Kios ${p.noKios} • ${p.jenisPajakLabel} • ${p.metodeBayar}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.greyText),
                                    ),
                                    Text(
                                      p.tanggal.length >= 10
                                          ? p.tanggal.substring(0, 10)
                                          : p.tanggal,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.greyText),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatRupiah(p.jumlah),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryGreen),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _statusLabel(p.status),
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: color),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppTheme.greyText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );

  Widget _chip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => _setFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _teal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.greyText)),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06), blurRadius: 10)
            ],
          ),
          child: const Icon(Icons.receipt_long_outlined,
              size: 40, color: AppTheme.greyText),
        ),
        const SizedBox(height: 16),
        const Text('Tidak ada data pembayaran',
            style: TextStyle(color: AppTheme.greyText)),
      ],
    ),
  );
}

// ── Tab Statistik ────────────────────────────────────────────────
class _StatistikTab extends StatelessWidget {
  const _StatistikTab();

  static const Color _teal = Color(0xFF1A3C34);

  String _formatRupiah(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PembayaranModel>>(
      stream: FirestoreService.streamSemuaPembayaran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _teal));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.errorRed)));
        }

        final allData = snapshot.data ?? [];

        // Hitung statistik bulan ini
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        int berhasil = 0, pending = 0, ditolak = 0;
        double totalMasuk = 0;
        final Map<String, double> perJenis = {};

        for (final p in allData) {
          try {
            final parts = p.tanggal.split(' ')[0].split('-');
            final tgl = DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            if (tgl.isBefore(startOfMonth)) continue;
          } catch (_) {}

          if (p.status == 'berhasil') {
            berhasil++;
            totalMasuk += p.jumlah;
            perJenis[p.jenisPajakLabel] =
                (perJenis[p.jenisPajakLabel] ?? 0) + p.jumlah;
          } else if (p.status == 'pending') {
            pending++;
          } else if (p.status == 'ditolak') {
            ditolak++;
          }
        }

        final total = berhasil + pending + ditolak;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner total pemasukan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2D25), _teal, Color(0xFF2D5A4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pemasukan Bulan Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_formatRupiah(totalMasuk),
                        style: const TextStyle(
                            color: AppTheme.accentYellow,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('$total total transaksi',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(children: [
                _statCard('Disetujui', berhasil, AppTheme.primaryGreen,
                    Icons.check_circle_rounded),
                const SizedBox(width: 10),
                _statCard('Pending', pending, const Color(0xFFD97706),
                    Icons.pending_rounded),
                const SizedBox(width: 10),
                _statCard('Ditolak', ditolak, AppTheme.errorRed,
                    Icons.cancel_rounded),
              ]),

              const SizedBox(height: 16),

              if (perJenis.isNotEmpty) ...[
                const Text('Pemasukan Per Jenis',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _teal)),
                const SizedBox(height: 10),
                Container(
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
                  child: Column(
                    children: perJenis.entries.map((e) {
                      final pct = totalMasuk > 0 ? e.value / totalMasuk : 0.0;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _teal)),
                                  Text(_formatRupiah(e.value),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryGreen)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor:
                                  const AlwaysStoppedAnimation<Color>(_teal),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (e.key != perJenis.keys.last)
                          const Divider(height: 1),
                      ]);
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(height: 8),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
      );
}