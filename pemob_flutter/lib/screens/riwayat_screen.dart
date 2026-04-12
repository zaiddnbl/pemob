import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
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
  List<PembayaranModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = dummyPembayaran;
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = dummyPembayaran.where((p) {
        final matchQuery = p.noKios.toLowerCase().contains(query) ||
            p.namaPedagang.toLowerCase().contains(query) ||
            p.bulan.toLowerCase().contains(query);
        final matchStatus = _filterStatus == 'semua' || p.status == _filterStatus;
        return matchQuery && matchStatus;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'lunas':
        return const Color(0xFF2E7D32);
      case 'telat':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFE65100);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    decoration: InputDecoration(
                      hintText: 'Cari kios, pedagang, bulan...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter chips (StatefulWidget setState)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['semua', 'lunas', 'belum', 'telat'].map((s) {
                        final isSelected = _filterStatus == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s == 'semua'
                                ? 'Semua'
                                : s == 'lunas'
                                ? 'Lunas'
                                : s == 'belum'
                                ? 'Belum Bayar'
                                : 'Terlambat'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _filterStatus = s);
                              _applyFilter();
                            },
                            selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
                            checkmarkColor: AppTheme.primaryGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.greyText,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: AppTheme.greyText),
                    SizedBox(height: 12),
                    Text('Tidak ada data ditemukan',
                        style: TextStyle(color: AppTheme.greyText)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final p = _filtered[index];
                  final color = _statusColor(p.status);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatDetailScreen(pembayaran: p),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              p.status == 'lunas'
                                  ? Icons.check_circle_rounded
                                  : p.status == 'telat'
                                  ? Icons.warning_rounded
                                  : Icons.pending_rounded,
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kios ${p.noKios} — ${p.bulan} ${p.tahun}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Text(
                                  p.namaPedagang,
                                  style: const TextStyle(
                                    fontSize: 12,
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
                                  color: AppTheme.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.statusLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
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
}