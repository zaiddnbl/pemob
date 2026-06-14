import 'dart:async';
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

class _PengawasMonitoringScreenState extends State<PengawasMonitoringScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _filterStatus = 'semua';

  // Ganti StreamBuilder dengan subscription manual
  List<PembayaranModel> _allData = [];
  StreamSubscription<List<PembayaranModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirestoreService.streamSemuaPembayaran().listen((data) {
      if (mounted) setState(() => _allData = data);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
      case 'berhasil':
        return AppTheme.primaryGreen;
      case 'pending':
        return const Color(0xFFE65100);
      case 'ditolak':
        return AppTheme.errorRed;
      default:
        return AppTheme.greyText;
    }
  }

  List<PembayaranModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _allData.where((p) {
      final matchQ = q.isEmpty ||
          p.noKios.toLowerCase().contains(q) ||
          p.namaPedagang.toLowerCase().contains(q);
      final matchStatus = _filterStatus == 'semua' || p.status == _filterStatus;
      return matchQ && matchStatus;
    }).toList();
  }

  void _showAlasanPenolakan(String alasan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: Text(alasan.isNotEmpty ? alasan : '-'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = _filtered;
    final totalBerhasil = _allData.where((p) => p.status == 'berhasil').length;
    final totalPending = _allData.where((p) => p.status == 'pending').length;
    final totalDitolak = _allData.where((p) => p.status == 'ditolak').length;
    final totalNominal = _allData
        .where((p) => p.status == 'berhasil')
        .fold(0.0, (s, p) => s + p.jumlah);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Monitoring Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Summary cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                    child: _miniCard(
                        'Berhasil', '$totalBerhasil', AppTheme.primaryGreen)),
                const SizedBox(width: 8),
                Expanded(
                    child: _miniCard(
                        'Pending', '$totalPending', const Color(0xFFE65100))),
                const SizedBox(width: 8),
                Expanded(
                    child: _miniCard(
                        'Ditolak', '$totalDitolak', AppTheme.errorRed)),
                const SizedBox(width: 8),
                Expanded(
                    child: _miniCard('Total Masuk', _formatRupiah(totalNominal),
                        const Color(0xFF1565C0))),
              ],
            ),
          ),

          // Search & Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari no kios / nama pedagang...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filterChip('semua', 'Semua'),
                    const SizedBox(width: 6),
                    _filterChip('berhasil', 'Berhasil'),
                    const SizedBox(width: 6),
                    _filterChip('pending', 'Pending'),
                    const SizedBox(width: 6),
                    _filterChip('ditolak', 'Ditolak'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Tidak ada data',
                        style: TextStyle(color: AppTheme.greyText)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final color = _statusColor(p.status);
                      final isDitolak = p.status == 'ditolak';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: color, width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          title: Row(
                            children: [
                              Text(
                                p.namaPedagang.isNotEmpty
                                    ? p.namaPedagang
                                    : '-',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(p.statusLabel,
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Kios ${p.noKios} • ${p.jenisPajakLabel} • ${_formatRupiah(p.jumlah)}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.greyText),
                              ),
                              Text(
                                'Tanggal: ${p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal} • ${p.metodeBayar}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.greyText),
                              ),
                            ],
                          ),
                          trailing: isDitolak
                              ? IconButton(
                                  icon: const Icon(Icons.info_outline_rounded,
                                      color: AppTheme.errorRed),
                                  tooltip: 'Lihat alasan penolakan',
                                  onPressed: () =>
                                      _showAlasanPenolakan(p.alasanPenolakan),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.greyText)),
      ),
    );
  }
}
