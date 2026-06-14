import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'semua';
  bool _isLoading = true;

  List<_PedagangMonitor> _data = [];

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Ambil semua pedagang
      final pedagang =
          await FirestoreService.getUsersByRole('pedagang');

      // Ambil semua pembayaran
      final semuaPembayaran =
          await FirestoreService.getSemuaPembayaran();

      // Ambil semua jatuh tempo
      final jatuhTempoMap =
          await FirestoreService.getAllJatuhTempo();

      final List<_PedagangMonitor> result = [];

      for (final p in pedagang) {
        // Cari pembayaran terakhir pedagang ini
        final pembayaranPedagang = semuaPembayaran
            .where((trx) => trx.noKios == p.noKios)
            .toList();

        // Pembayaran terakhir
        final lastPembayaran =
            pembayaranPedagang.isNotEmpty ? pembayaranPedagang.first : null;

        // Jatuh tempo
        final jatuhTempo = p.noKios != '-' && p.noKios.isNotEmpty
            ? jatuhTempoMap[p.noKios]
            : null;

        // Status bayar
        bool sudahBayar = false;
        if (lastPembayaran != null) {
          final now = DateTime.now();
          try {
            final parts = lastPembayaran.tanggal.split(' ')[0].split('-');
            final tglBayar = DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            // Bayar bulan ini
            sudahBayar = tglBayar.year == now.year &&
                tglBayar.month == now.month;
          } catch (_) {}
        }

        result.add(_PedagangMonitor(
          user: p,
          lastPembayaran: lastPembayaran,
          jatuhTempo: jatuhTempo,
          sudahBayar: sudahBayar,
        ));
      }

      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_PedagangMonitor> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _data.where((item) {
      final matchQ = q.isEmpty ||
          item.user.nama.toLowerCase().contains(q) ||
          item.user.noKios.toLowerCase().contains(q);
      final matchStatus = _filterStatus == 'semua' ||
          (_filterStatus == 'sudah' && item.sudahBayar) ||
          (_filterStatus == 'belum' && !item.sudahBayar);
      return matchQ && matchStatus;
    }).toList();
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

  String _formatJatuhTempo(DateTime? dt) {
    if (dt == null) return 'Belum ada';
    final bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final sisa = dt.difference(DateTime.now()).inDays;
    final tgl = '${dt.day} ${bulan[dt.month]} ${dt.year}';
    if (sisa < 0) return '$tgl\n(Nunggak ${-sisa} hari)';
    if (sisa == 0) return '$tgl\n(Jatuh tempo hari ini)';
    return '$tgl\n(Sisa $sisa hari)';
  }

  Color _jatuhTempoColor(DateTime? dt) {
    if (dt == null) return AppTheme.greyText;
    final sisa = dt.difference(DateTime.now()).inDays;
    if (sisa < 0) return AppTheme.errorRed;
    if (sisa <= 3) return const Color(0xFFD97706);
    return AppTheme.primaryGreen;
  }

  void _showNotifDialog(BuildContext context, _PedagangMonitor item) {
    final pesanCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Kirim Pesan ke ${item.user.nama}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _navyDark),
            ),
            Text('Kios ${item.user.noKios}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.greyText)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: pesanCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Mohon segera lakukan pembayaran retribusi...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dua tombol: In-App & WhatsApp
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (pesanCtrl.text.trim().isEmpty) return;
                      if (item.user.noKios != '-') {
                        await FirestoreService.buatNotifikasiAdmin(
                          noKios: item.user.noKios,
                          pesan: pesanCtrl.text.trim(),
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi in-app dikirim ✅'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('In-App',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final hp = item.user.nomorHp
                          .replaceAll(RegExp(r'[^0-9]'), '');
                      if (hp.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor HP tidak tersedia'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }
                      final noWa = hp.startsWith('0')
                          ? '62${hp.substring(1)}'
                          : hp;
                      final pesan = pesanCtrl.text.trim().isNotEmpty
                          ? pesanCtrl.text.trim()
                          : 'Halo ${item.user.nama}, mohon segera melakukan pembayaran retribusi kios ${item.user.noKios}. Terima kasih.';
                      final url = Uri.parse(
                          'https://wa.me/$noWa?text=${Uri.encodeComponent(pesan)}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.chat_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('WhatsApp',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final sudahBayar = filtered.where((i) => i.sudahBayar).length;
    final belumBayar = filtered.where((i) => !i.sudahBayar).length;

    return Scaffold(
      backgroundColor: _bgGrey,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monitoring Pedagang',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _navyDark)),
                const Text('Status pembayaran semua pedagang',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.greyText)),
                const SizedBox(height: 14),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pedagang / no kios...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.greyText),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.greyText, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 13),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter chips + refresh
                Row(
                  children: [
                    _chip('semua', 'Semua (${_data.length})'),
                    const SizedBox(width: 6),
                    _chip('sudah',
                        'Sudah Bayar (${_data.where((i) => i.sudahBayar).length})'),
                    const SizedBox(width: 6),
                    _chip('belum',
                        'Belum Bayar (${_data.where((i) => !i.sudahBayar).length})'),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: _navyDark, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Summary strip ─────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _summaryBadge('Total', '${_data.length}', _navyDark),
                const SizedBox(width: 8),
                _summaryBadge(
                    'Sudah Bayar', '$sudahBayar', AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _summaryBadge('Belum Bayar', '$belumBayar',
                    AppTheme.errorRed),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Content ───────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _navyDark))
                : filtered.isEmpty
                    ? Center(
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
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 10)
                                ],
                              ),
                              child: const Icon(Icons.people_outline_rounded,
                                  size: 40, color: AppTheme.greyText),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tidak ada data pedagang',
                                style: TextStyle(color: AppTheme.greyText)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final sudah = item.sudahBayar;
                          final jatuhTempoColor =
                              _jatuhTempoColor(item.jatuhTempo);
                          final isNunggak = item.jatuhTempo != null &&
                              item.jatuhTempo!
                                  .isBefore(DateTime.now());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isNunggak
                                  ? Border.all(
                                      color: AppTheme.errorRed
                                          .withOpacity(0.4),
                                      width: 1.5)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Status bar atas
                                Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: sudah
                                        ? AppTheme.primaryGreen
                                        : AppTheme.errorRed,
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    children: [
                                      // Row 1: Nama + Status
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: sudah
                                                ? AppTheme.primaryGreen
                                                    .withOpacity(0.15)
                                                : AppTheme.errorRed
                                                    .withOpacity(0.1),
                                            child: Text(
                                              item.user.nama.isNotEmpty
                                                  ? item.user.nama[0]
                                                      .toUpperCase()
                                                  : 'P',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: sudah
                                                      ? AppTheme.primaryGreen
                                                      : AppTheme.errorRed),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.user.nama,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _navyDark),
                                                ),
                                                Text(
                                                  'Kios ${item.user.noKios}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.greyText),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: sudah
                                                  ? AppTheme.primaryGreen
                                                      .withOpacity(0.1)
                                                  : AppTheme.errorRed
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              sudah
                                                  ? 'Sudah Bayar'
                                                  : 'Belum Bayar',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: sudah
                                                      ? AppTheme.primaryGreen
                                                      : AppTheme.errorRed),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),

                                      // Row 2: Detail info
                                      Row(
                                        children: [
                                          // Jenis + Jumlah
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Pembayaran',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            AppTheme.greyText)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.lastPembayaran != null
                                                      ? '${item.lastPembayaran!.jenisPajakLabel}\n${_formatRupiah(item.lastPembayaran!.jumlah)}'
                                                      : '-',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _navyDark,
                                                      height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Jatuh tempo
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Jatuh Tempo',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            AppTheme.greyText)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatJatuhTempo(
                                                      item.jatuhTempo),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: jatuhTempoColor,
                                                      height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Tombol notif
                                          GestureDetector(
                                            onTap: () =>
                                                _showNotifDialog(context, item),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    _navyDark.withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.send_rounded,
                                                color: _navyDark,
                                                size: 18,
                                              ),
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
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _navyDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.greyText)),
      ),
    );
  }

  Widget _summaryBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppTheme.greyText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PedagangMonitor {
  final UserModel user;
  final PembayaranModel? lastPembayaran;
  final DateTime? jatuhTempo;
  final bool sudahBayar;

  _PedagangMonitor({
    required this.user,
    this.lastPembayaran,
    this.jatuhTempo,
    required this.sudahBayar,
  });
}