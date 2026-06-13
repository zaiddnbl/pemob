import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'bukti_pembayaran_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => RiwayatScreenState();
}

class RiwayatScreenState extends State<RiwayatScreen> {
  void refreshData() => setState(() {});

  final _searchController = TextEditingController();
  String _filterJenis = 'semua'; // semua, harian, mingguan, bulanan

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PembayaranModel> _applyFilter(List<PembayaranModel> all) {
    final query = _searchController.text.toLowerCase();
    return all.where((p) {
      final matchQuery = query.isEmpty ||
          p.noTransaksi.toLowerCase().contains(query) ||
          p.jenisPajakLabel.toLowerCase().contains(query) ||
          p.metodeBayar.toLowerCase().contains(query);
      final matchJenis =
          _filterJenis == 'semua' || p.jenisPajak == _filterJenis;
      return matchQuery && matchJenis;
    }).toList();
  }

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
  Widget build(BuildContext context) {
    final noKios = SessionUser.currentUser?.noKios ?? '';
    final firstName =
        SessionUser.currentUser?.nama.split(' ').first ?? 'Pedagang';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<PembayaranModel>>(
          stream: FirestoreService.streamPembayaranByKios(noKios),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryGreen),
                    SizedBox(height: 14),
                    Text('Memuat riwayat...',
                        style: TextStyle(color: AppTheme.greyText)),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 52, color: AppTheme.errorRed),
                    const SizedBox(height: 12),
                    const Text('Gagal memuat riwayat',
                        style: TextStyle(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final allData = snapshot.data ?? [];
            final filtered = _applyFilter(allData);

            final totalBerhasil = allData
                .where((p) => p.status == 'berhasil')
                .fold(0.0, (sum, p) => sum + p.jumlah);
            final jumlahPending =
                allData.where((p) => p.status == 'pending').length;

            return Column(
              children: [
                // ── Summary ──────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $firstName — kios $noKios',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.greyText),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              label: 'Total\n(Berhasil)',
                              value: 'Rp ${_formatRupiah(totalBerhasil)}',
                              borderColor: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _summaryCard(
                              label: 'Jumlah\nTransaksi',
                              value: allData.length.toString(),
                              borderColor: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _summaryCard(
                              label: 'Menunggu\nVerifikasi',
                              value: jumlahPending.toString(),
                              borderColor: const Color(0xFFE65100),
                              valueColor: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Search ────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
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
                ),

                // ── Filter Jenis Retribusi ─────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _filterBtn('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _filterBtn('harian', 'Harian'),
                      const SizedBox(width: 8),
                      _filterBtn('mingguan', 'Mingguan'),
                      const SizedBox(width: 8),
                      _filterBtn('bulanan', 'Bulanan'),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── List Riwayat ──────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 52, color: AppTheme.greyText),
                        const SizedBox(height: 12),
                        Text(
                          allData.isEmpty
                              ? 'Belum ada transaksi'
                              : 'Tidak ada transaksi ditemukan',
                          style: const TextStyle(
                              color: AppTheme.greyText),
                        ),
                        if (_filterJenis != 'semua' ||
                            _searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filterJenis = 'semua');
                            },
                            child: const Text('Reset Filter'),
                          ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final color = _statusColor(p.status);
                      final icon = _statusIcon(p.status);

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
                                BuktiPembayaranScreen(pembayaran: p),
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
                                  color:
                                  Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Ikon jenis pajak
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentYellow
                                      .withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  p.jenisPajak == 'harian'
                                      ? Icons.today_rounded
                                      : p.jenisPajak == 'mingguan'
                                      ? Icons.date_range_rounded
                                      : Icons
                                      .calendar_month_rounded,
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
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
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
                                      color:
                                      color.withOpacity(0.1),
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
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Lihat Bukti →',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryGreen,
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
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color borderColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: borderColor, width: 3)),
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
                fontSize: 10, color: AppTheme.greyText, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String key, String label) {
    final isSelected = _filterJenis == key;
    return GestureDetector(
      onTap: () => setState(() => _filterJenis = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.greyText,
          ),
        ),
      ),
    );
  }
}