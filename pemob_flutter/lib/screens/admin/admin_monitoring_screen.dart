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

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen>
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
                const Text('Monitoring',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _navyDark)),
                const Text('Pantau & verifikasi pembayaran pedagang',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
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
                    Tab(text: 'Monitoring Pedagang'),
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
                _MonitoringPedagangTab(),
                _VerifikasiTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringPedagangTab extends StatefulWidget {
  const _MonitoringPedagangTab();

  @override
  State<_MonitoringPedagangTab> createState() => _MonitoringPedagangTabState();
}

class _MonitoringPedagangTabState extends State<_MonitoringPedagangTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = 'semua';
  bool _isLoading = true;
  List<_PedagangData> _data = [];
  List<_PedagangData> _filtered = [];

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _data.where((item) {
        final matchQ = q.isEmpty ||
            item.user.nama.toLowerCase().contains(q) ||
            item.user.noKios.toLowerCase().contains(q);
        final matchStatus = _filterStatus == 'semua' ||
            (_filterStatus == 'sudah' && item.sudahBayar) ||
            (_filterStatus == 'belum' && !item.sudahBayar);
        return matchQ && matchStatus;
      }).toList();
    });
  }

  void _setFilter(String val) {
    _filterStatus = val;
    _applyFilter();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pedagang = await FirestoreService.getUsersByRole('pedagang');
      final semuaPembayaran = await FirestoreService.getSemuaPembayaran();
      final jatuhTempoMap = await FirestoreService.getAllJatuhTempo();

      final result = <_PedagangData>[];
      for (final p in pedagang) {
        final pembayaranPedagang =
        semuaPembayaran.where((trx) => trx.noKios == p.noKios).toList();
        final lastPembayaran =
        pembayaranPedagang.isNotEmpty ? pembayaranPedagang.first : null;
        final jatuhTempo = (p.noKios != '-' && p.noKios.isNotEmpty)
            ? jatuhTempoMap[p.noKios]
            : null;

        bool sudahBayar = false;
        if (lastPembayaran != null) {
          final now = DateTime.now();
          try {
            final parts = lastPembayaran.tanggal.split(' ')[0].split('-');
            final tglBayar = DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            sudahBayar =
                tglBayar.year == now.year && tglBayar.month == now.month;
          } catch (_) {}
        }

        result.add(_PedagangData(
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
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
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

  // ✅ KEY FIX: builder pakai sheetCtx, bukan _
  // viewInsets dibaca dari sheetCtx sehingga keyboard height ter-detect
  void _showNotifDialog(_PedagangData item) {
    const defaultPesan =
        'Halo, tolong segera membayar retribusi hari ini. Terima kasih.';
    final pesanCtrl = TextEditingController(text: defaultPesan);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // ✅ sheetCtx dipakai untuk baca viewInsets keyboard
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // ✅ SingleChildScrollView agar konten bisa scroll saat keyboard muncul
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _navyDark,
                      child: Text(
                        item.user.nama.isNotEmpty
                            ? item.user.nama[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.user.nama,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _navyDark)),
                          Text(
                              'Kios ${item.user.noKios} • ${item.user.nomorHp}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.greyText)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.accentYellow.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: AppTheme.accentYellow, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pesan sudah diisi otomatis. Bisa diubah sebelum dikirim.',
                          style: TextStyle(fontSize: 11, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: pesanCtrl,
                    // ✅ maxLines 3 agar sheet tidak terlalu tinggi
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final pesan = pesanCtrl.text.trim();
                          if (pesan.isEmpty) return;
                          if (item.user.noKios != '-' &&
                              item.user.noKios.isNotEmpty) {
                            await FirestoreService.buatNotifikasiAdmin(
                              noKios: item.user.noKios,
                              pesan: pesan,
                            );
                          }
                          // ✅ pop pakai sheetCtx
                          if (!sheetCtx.mounted) return;
                          Navigator.pop(sheetCtx);
                          if (!context.mounted) return;
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
                          final pesan = pesanCtrl.text.trim();
                          var hp = item.user.nomorHp
                              .replaceAll(RegExp(r'[^0-9]'), '');
                          if (hp.isEmpty) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor HP tidak tersedia'),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                            return;
                          }
                          if (hp.startsWith('0')) hp = '62${hp.substring(1)}';
                          final pesanFinal = pesan.isNotEmpty
                              ? pesan
                              : 'Halo ${item.user.nama}, tolong segera membayar retribusi hari ini. Terima kasih.';
                          final url = Uri.parse(
                              'https://wa.me/$hp?text=${Uri.encodeComponent(pesanFinal)}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                          // ✅ pop pakai sheetCtx
                          if (!sheetCtx.mounted) return;
                          Navigator.pop(sheetCtx);
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _data.length;
    final sudah = _data.where((i) => i.sudahBayar).length;
    final belum = _data.where((i) => !i.sudahBayar).length;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama pedagang / no kios...',
                  hintStyle:
                  const TextStyle(fontSize: 13, color: AppTheme.greyText),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.greyText, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _navyDark, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F6F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (_, val, __) => val.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('semua', 'Semua ($total)'),
                  const SizedBox(width: 6),
                  _chip('sudah', 'Sudah Bayar ($sudah)'),
                  const SizedBox(width: 6),
                  _chip('belum', 'Belum Bayar ($belum)'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: _navyDark, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _summaryBadge('Total', '$total', _navyDark),
                  const SizedBox(width: 8),
                  _summaryBadge('Sudah Bayar', '$sudah', AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  _summaryBadge('Belum Bayar', '$belum', AppTheme.errorRed),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _navyDark))
              : _filtered.isEmpty
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
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final item = _filtered[index];
              final sudahBayar = item.sudahBayar;
              final jtColor = _jatuhTempoColor(item.jatuhTempo);
              final isNunggak = item.jatuhTempo != null &&
                  item.jatuhTempo!.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isNunggak
                      ? Border.all(
                      color: AppTheme.errorRed.withOpacity(0.4),
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
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: sudahBayar
                            ? AppTheme.primaryGreen
                            : AppTheme.errorRed,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: sudahBayar
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
                                      color: sudahBayar
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
                                    Text(item.user.nama,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.w700,
                                            color: _navyDark)),
                                    Text('Kios ${item.user.noKios}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                            AppTheme.greyText)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sudahBayar
                                      ? AppTheme.primaryGreen
                                      .withOpacity(0.1)
                                      : AppTheme.errorRed
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sudahBayar
                                      ? 'Sudah Bayar'
                                      : 'Belum Bayar',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sudahBayar
                                          ? AppTheme.primaryGreen
                                          : AppTheme.errorRed),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
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
                                          fontWeight: FontWeight.w700,
                                          color: _navyDark,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
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
                                          fontWeight: FontWeight.w600,
                                          color: jtColor,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showNotifDialog(item),
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
    );
  }

  Widget _chip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => _setFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                    fontSize: 14, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: AppTheme.greyText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 2 — Verifikasi Pembayaran
// ══════════════════════════════════════════════════════════════
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppTheme.primaryGreen, size: 22),
            SizedBox(width: 8),
            Text('Setujui Pembayaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedagang: ${p.namaPedagang}'),
            Text('Kios: ${p.noKios}'),
            Text('Jenis: ${p.jenisPajakLabel}'),
            Text('Jumlah: ${_formatRupiah(p.jumlah)}'),
            const SizedBox(height: 8),
            const Text(
              'Pedagang akan mendapat notifikasi bahwa pembayarannya telah disetujui.',
              style: TextStyle(fontSize: 12, color: AppTheme.greyText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await FirestoreService.approvePembayaran(p.id);
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
                  content: Text(
                      success ? 'Pembayaran disetujui ✅' : 'Gagal menyetujui'),
                  backgroundColor:
                  success ? AppTheme.accentGreen : AppTheme.errorRed,
                ),
              );
            },
            icon:
            const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            label: const Text('Setujui', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, PembayaranModel p) {
    final alasanCtrl = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          // ✅ FIX sama: pakai viewInsets dari ctx
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.cancel_rounded,
                            color: Colors.red.shade600, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tolak Pembayaran',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red)),
                            Text('${p.namaPedagang} • Kios ${p.noKios}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.greyText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Jenis', p.jenisPajakLabel),
                        _infoRow('Jumlah', _formatRupiah(p.jumlah)),
                        _infoRow('Metode', p.metodeBayar),
                        _infoRow(
                            'Tanggal',
                            p.tanggal.length >= 10
                                ? p.tanggal.substring(0, 10)
                                : p.tanggal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Alasan Penolakan *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _navyDark)),
                  const SizedBox(height: 4),
                  const Text(
                    'Alasan ini akan dikirim sebagai notifikasi ke pedagang.',
                    style: TextStyle(fontSize: 11, color: AppTheme.greyText),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: Colors.red.shade200, width: 1.5),
                    ),
                    child: TextField(
                      controller: alasanCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                        'Contoh: Bukti pembayaran tidak valid, nominal tidak sesuai...',
                        hintStyle:
                        TextStyle(fontSize: 12, color: AppTheme.greyText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                        if (alasanCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content:
                              Text('Alasan penolakan wajib diisi'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                          return;
                        }
                        setModal(() => isSending = true);
                        final alasan = alasanCtrl.text.trim();
                        final success =
                        await FirestoreService.rejectPembayaran(
                          id: p.id,
                          alasan: alasan,
                        );
                        if (success) {
                          await FirestoreService.buatNotifikasiPenolakan(
                            noKios: p.noKios,
                            noTransaksi: p.noTransaksi,
                            alasan: alasan,
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Pembayaran ditolak & notifikasi dikirim'
                                : 'Gagal menolak pembayaran'),
                            backgroundColor:
                            success ? Colors.red : AppTheme.errorRed,
                          ),
                        );
                      },
                      icon: isSending
                          ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.close_rounded,
                          size: 16, color: Colors.white),
                      label: Text(
                          isSending
                              ? 'Mengirim...'
                              : 'TOLAK & KIRIM NOTIFIKASI',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
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
        final pending = allData.where((p) => p.status == 'pending').toList();

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
                const Text('Semua sudah diverifikasi! 🎉',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _navyDark)),
                const Text('Tidak ada pembayaran yang perlu ditinjau.',
                    style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_rounded,
                            color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 6),
                        Text('${pending.length} pembayaran menunggu verifikasi',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: _navyDark,
                            borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.2),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Text('Kios ${p.noKios} • ${p.metodeBayar}',
                                        style: TextStyle(
                                            color:
                                            Colors.white.withOpacity(0.7),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFFD97706).withOpacity(0.25),
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
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow('No. Transaksi', p.noTransaksi),
                              _infoRow('Jenis Retribusi', p.jenisPajakLabel),
                              _infoRow(
                                  'Tanggal',
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
                                  Text(_formatRupiah(p.jumlah),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryGreen)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _reject(context, p),
                                      icon: const Icon(Icons.close_rounded,
                                          size: 14, color: Colors.red),
                                      label: const Text('TOLAK',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800)),
                                      style: OutlinedButton.styleFrom(
                                        side:
                                        const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approve(context, p),
                                      icon: const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.white),
                                      label: const Text('SETUJUI',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryGreen,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12)),
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
        );
      },
    );
  }
}

class _PedagangData {
  final UserModel user;
  final PembayaranModel? lastPembayaran;
  final DateTime? jatuhTempo;
  final bool sudahBayar;

  _PedagangData({
    required this.user,
    this.lastPembayaran,
    this.jatuhTempo,
    required this.sudahBayar,
  });
}