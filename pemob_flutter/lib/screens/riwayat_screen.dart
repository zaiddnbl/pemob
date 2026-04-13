import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'riwayat_detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'semua';

  List<PembayaranModel> get _riwayatSaya {
    final noKios = SessionUser.currentUser?.noKios ?? '';
    final list = dummyPembayaran.where((p) => p.noKios == noKios).toList();
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }

  List<PembayaranModel> get _filtered {
    final query = _searchController.text.toLowerCase();
    return _riwayatSaya.where((p) {
      final matchQuery = query.isEmpty ||
          p.noTransaksi.toLowerCase().contains(query) ||
          p.jenisPajakLabel.toLowerCase().contains(query) ||
          p.metodeBayar.toLowerCase().contains(query);
      final matchStatus =
          _filterStatus == 'semua' || p.status == _filterStatus;
      return matchQuery && matchStatus;
    }).toList();
  }

  // Summary stats
  double get _totalBerhasil => _riwayatSaya
      .where((p) => p.status == 'berhasil')
      .fold(0.0, (sum, p) => sum + p.jumlah);

  int get _totalTransaksi => _riwayatSaya.length;

  int get _jumlahPending =>
      _riwayatSaya.where((p) => p.status == 'pending').length;

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'berhasil':
        return const Color(0xFF2E7D32);
      case 'gagal':
        return AppTheme.errorRed;
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'berhasil':
        return Icons.check_circle_rounded;
      case 'gagal':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        SessionUser.currentUser?.nama.split(' ').first ?? 'Pedagang';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Summary Cards ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $firstName — menampilkan transaksi kios Anda',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          label: 'Total Pembayaran\n(Berhasil)',
                          value: 'Rp ${_formatRupiah(_totalBerhasil)}',
                          valueColor: AppTheme.darkText,
                          borderColor: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          label: 'Jumlah\nTransaksi',
                          value: _totalTransaksi.toString(),
                          valueColor: AppTheme.darkText,
                          borderColor: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard(
                          label: 'Menunggu\nVerifikasi',
                          value: _jumlahPending.toString(),
                          valueColor: const Color(0xFFE65100),
                          borderColor: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search & Filter ────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter buttons (mirip web)
                  Row(
                    children: [
                      _filterBtn('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _filterBtn('berhasil', 'Berhasil'),
                      const SizedBox(width: 8),
                      _filterBtn('pending', 'Pending'),
                      const SizedBox(width: 8),
                      _filterBtn('gagal', 'Gagal'),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Daftar Transaksi ───────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 60, color: AppTheme.greyText),
                    SizedBox(height: 12),
                    Text(
                      'Tidak ada transaksi ditemukan',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final p = _filtered[index];
                  final color = _statusColor(p.status);
                  final icon = _statusIcon(p.status);

                  // Format tanggal
                  final parts = p.tanggal.split(' ');
                  final date = parts[0];
                  final time = parts.length > 1
                      ? parts[1].substring(0, 5)
                      : '';

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiwayatDetailScreen(pembayaran: p),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon jenis pajak
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                              AppTheme.accentYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              p.jenisPajak == 'harian'
                                  ? Icons.today_rounded
                                  : p.jenisPajak == 'mingguan'
                                  ? Icons.date_range_rounded
                                  : Icons.calendar_month_rounded,
                              color: AppTheme.accentYellow,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.jenisPajakLabel} — Kios ${p.noKios}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Text(
                                  p.noTransaksi,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$date $time • ${p.metodeBayar}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rp ${_formatRupiah(p.jumlah)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon,
                                        color: color, size: 10),
                                    const SizedBox(width: 3),
                                    Text(
                                      p.statusLabel,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lihat Detail →',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryGreen
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color valueColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.greyText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String key, String label) {
    final isSelected = _filterStatus == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
              isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.greyText,
            ),
          ),
        ),
      ),
    );
  }
}