import 'package:flutter/material.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminPembayaranScreen extends StatefulWidget {
  const AdminPembayaranScreen({super.key});

  @override
  State<AdminPembayaranScreen> createState() =>
      _AdminPembayaranScreenState();
}

class _AdminPembayaranScreenState extends State<AdminPembayaranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _navyDark = Color(0xFF1A3C34);

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
      backgroundColor: const Color(0xFFF4F6F5),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pembayaran',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _navyDark)),
                const Text('Monitoring & verifikasi transaksi',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.greyText)),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  indicatorColor: _navyDark,
                  indicatorWeight: 3,
                  labelColor: _navyDark,
                  unselectedLabelColor: AppTheme.greyText,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Monitoring'),
                    Tab(text: 'Verifikasi'),
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
                _VerifikasiTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monitoring Tab ───────────────────────────────────────────
class _MonitoringTab extends StatefulWidget {
  const _MonitoringTab();

  @override
  State<_MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<_MonitoringTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'semua';

  static const Color _navyDark = Color(0xFF1A3C34);

  @override
  void dispose() {
    _searchController.dispose();
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
      case 'berhasil': return AppTheme.primaryGreen;
      case 'pending': return const Color(0xFFD97706);
      case 'ditolak': return AppTheme.errorRed;
      default: return AppTheme.greyText;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'berhasil': return 'Disetujui';
      case 'pending': return 'Pending';
      case 'ditolak': return 'Ditolak';
      default: return status;
    }
  }

  void _kirimNotif(String noKios) {
    final ctrl = TextEditingController();
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
            Text('Kirim Notifikasi ke Kios $noKios',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _navyDark)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  await FirestoreService.buatNotifikasiAdmin(
                    noKios: noKios,
                    pesan: ctrl.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi dikirim ✅'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded,
                    size: 16, color: Colors.white),
                label: const Text('KIRIM',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PembayaranModel>>(
      stream: FirestoreService.streamSemuaPembayaran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _navyDark));
        }

        final allData = snapshot.data ?? [];
        final filtered = allData.where((p) {
          final q = _searchQuery.toLowerCase();
          final matchQ = q.isEmpty ||
              p.noKios.toLowerCase().contains(q) ||
              p.namaPedagang.toLowerCase().contains(q);
          final matchStatus = _filterStatus == 'semua' ||
              p.status == _filterStatus;
          return matchQ && matchStatus;
        }).toList();

        final totalBerhasil =
            allData.where((p) => p.status == 'berhasil').length;
        final totalPending =
            allData.where((p) => p.status == 'pending').length;
        final totalDitolak =
            allData.where((p) => p.status == 'ditolak').length;
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
                  _summaryCard('Disetujui', '$totalBerhasil',
                      AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  _summaryCard('Pending', '$totalPending',
                      const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _summaryCard('Ditolak', '$totalDitolak',
                      AppTheme.errorRed),
                  const SizedBox(width: 8),
                  _summaryCard('Total Masuk',
                      _formatRupiah(totalNominal), _navyDark),
                ],
              ),
            ),

            // Search & Filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Cari kios / nama pedagang...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: AppTheme.greyText),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.greyText, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _filterChip('semua', 'Semua'),
                      const SizedBox(width: 6),
                      _filterChip('berhasil', 'Disetujui'),
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

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                  child: Text('Tidak ada data',
                      style:
                      TextStyle(color: AppTheme.greyText)))
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
                            color:
                            Colors.black.withOpacity(0.04),
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
                            borderRadius:
                            const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          p.namaPedagang
                                              .isNotEmpty
                                              ? p.namaPedagang
                                              : '-',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w700,
                                              color: _navyDark),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 7,
                                              vertical: 2),
                                          decoration:
                                          BoxDecoration(
                                            color: color
                                                .withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius
                                                .circular(6),
                                          ),
                                          child: Text(
                                            _statusLabel(p.status),
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight:
                                                FontWeight.w700,
                                                color: color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kios ${p.noKios} • ${p.jenisPajakLabel} • ${_formatRupiah(p.jumlah)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color:
                                          AppTheme.greyText),
                                    ),
                                    Text(
                                      p.tanggal.length >= 10
                                          ? p.tanggal
                                          .substring(0, 10)
                                          : p.tanggal,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                          AppTheme.greyText),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: _navyDark,
                                    size: 20),
                                onPressed: () =>
                                    _kirimNotif(p.noKios),
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

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
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

  Widget _filterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _navyDark
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppTheme.greyText)),
      ),
    );
  }
}

// ── Verifikasi Tab ───────────────────────────────────────────
class _VerifikasiTab extends StatelessWidget {
  const _VerifikasiTab();

  static const Color _navyDark = Color(0xFF1A3C34);

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  void _approve(BuildContext context, PembayaranModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppTheme.primaryGreen, size: 24),
            SizedBox(width: 8),
            Text('Setujui Pembayaran'),
          ],
        ),
        content: Text(
            'Setujui pembayaran ${p.jenisPajakLabel} kios ${p.noKios} sebesar ${_formatRupiah(p.jumlah)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
              await FirestoreService.approvePembayaran(p.id);
              if (success) {
                await FirestoreService.buatNotifikasiVerifikasi(
                  noKios: p.noKios,
                  noTransaksi: p.noTransaksi,
                  jenisPajak: p.jenisPajak,
                  jumlah: p.jumlah,
                );
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Pembayaran disetujui ✅'
                      : 'Gagal menyetujui'),
                  backgroundColor: success
                      ? AppTheme.accentGreen
                      : AppTheme.errorRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            child: const Text('Setujui',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, PembayaranModel p) {
    final alasanCtrl = TextEditingController();
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
            const Text('Tolak Pembayaran',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.red)),
            const SizedBox(height: 4),
            const Text(
                'Masukkan alasan penolakan yang jelas',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.greyText)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: alasanCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Bukti pembayaran tidak valid...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (alasanCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Alasan penolakan wajib diisi')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  final success =
                  await FirestoreService.rejectPembayaran(
                    id: p.id,
                    alasan: alasanCtrl.text.trim(),
                  );
                  if (success) {
                    await FirestoreService.buatNotifikasiPenolakan(
                      noKios: p.noKios,
                      noTransaksi: p.noTransaksi,
                      alasan: alasanCtrl.text.trim(),
                    );
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Pembayaran ditolak'
                          : 'Gagal menolak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
                label: const Text('TOLAK PEMBAYARAN',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PembayaranModel>>(
      stream: FirestoreService.streamSemuaPembayaran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
              CircularProgressIndicator(color: _navyDark));
        }

        final allData = snapshot.data ?? [];
        final pending =
        allData.where((p) => p.status == 'pending').toList();

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 48, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 16),
                const Text('Semua pembayaran sudah diverifikasi!',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _navyDark)),
                const Text('Tidak ada yang perlu ditindak.',
                    style: TextStyle(
                        color: AppTheme.greyText, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final p = pending[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A3C34),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                          Colors.white.withOpacity(0.2),
                          child: Text(
                            p.namaPedagang.isNotEmpty
                                ? p.namaPedagang[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
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
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Kios ${p.noKios} • ${p.metodeBayar}',
                                style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.7),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Pending',
                              style: TextStyle(
                                  color: Color(0xFFFFB74D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _verRow('No. Transaksi', p.noTransaksi),
                        _verRow('Jenis Retribusi',
                            p.jenisPajakLabel),
                        _verRow('Tanggal',
                            p.tanggal.length >= 16
                                ? p.tanggal.substring(0, 16)
                                : p.tanggal),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _navyDark)),
                            Text(
                              _formatRupiah(p.jumlah),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _reject(context, p),
                                icon: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.red),
                                label: const Text('TOLAK',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w800)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.red),
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _approve(context, p),
                                icon: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white),
                                label: const Text('SETUJUI',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  AppTheme.primaryGreen,
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          12)),
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
        );
      },
    );
  }

  Widget _verRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.greyText)),
          ),
          Expanded(
            child: Text(': $value',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _navyDark)),
          ),
        ],
      ),
    );
  }
}