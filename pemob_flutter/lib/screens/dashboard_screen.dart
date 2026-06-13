import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/pembayaran_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'notifikasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<PembayaranModel> _riwayat = [];
  DateTime? _jatuhTempo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refreshData() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final noKios = SessionUser.currentUser?.noKios ?? '';
      if (noKios.isEmpty || noKios == '-') {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final results = await Future.wait([
        FirestoreService.getPembayaranByKios(noKios),
        FirestoreService.getJatuhTempo(noKios),
      ]);
      if (mounted) {
        setState(() {
          _riwayat = results[0] as List<PembayaranModel>;
          _jatuhTempo = results[1] as DateTime?;
          _isLoading = false;
        });
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
    return buffer.toString();
  }

  String _formatTanggalPanjang(DateTime dt) {
    final bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  int get _sisaHari {
    if (_jatuhTempo == null) return -99;
    return _jatuhTempo!.difference(DateTime.now()).inDays;
  }

  double get _totalBulanIni {
    final now = DateTime.now();
    return _riwayat
        .where((p) {
      try {
        final parts = p.tanggal.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1].split(' ')[0]);
        return y == now.year && m == now.month;
      } catch (_) {
        return false;
      }
    })
        .fold(0.0, (sum, p) => sum + p.jumlah);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final firstName = user?.nama.split(' ').first ?? 'Pedagang';
    final noKios = user?.noKios ?? '-';
    final belumAdaKios = noKios == '-' || noKios.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 240,
              backgroundColor: AppTheme.primaryGreen,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SIPESEL',
                        style: TextStyle(
                          color: AppTheme.accentYellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Sistem Informasi Pembayaran Pajak Pasar',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Notif badge (stream real-time)
                StreamBuilder<int>(
                  stream: FirestoreService.streamJumlahBelumDibaca(noKios),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotifikasiScreen()),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppTheme.errorRed,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.accentYellow,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Lingkaran dekorasi
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      // Konten
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, $firstName 👋',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              user?.nama ?? 'Pedagang',
                              style: const TextStyle(
                                color: AppTheme.accentYellow,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.storefront_rounded,
                                          color: Colors.white70, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        belumAdaKios
                                            ? 'Belum ada kios'
                                            : 'Kios $noKios',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          color: Colors.white70, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pasar Wadungasri',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Belum ada kios warning ────────────
                    if (belumAdaKios)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.accentYellow.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppTheme.accentYellow, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kamu belum memiliki kios. Hubungi admin untuk assign kios.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.darkText),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Card Info Kios & Tagihan ──────────
                    if (!belumAdaKios) ...[
                      // Card utama — mirip web
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text('Kios',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11)),
                                    Text(
                                      noKios,
                                      style: const TextStyle(
                                        color: AppTheme.accentYellow,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.circle,
                                          color: Color(0xFF69F0AE), size: 8),
                                      SizedBox(width: 5),
                                      Text('Aktif',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _cardStatItem(
                                    label: 'Tagihan Berikutnya',
                                    value: _jatuhTempo != null
                                        ? _formatTanggalPanjang(_jatuhTempo!)
                                        : 'Belum ada',
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white24),
                                Expanded(
                                  child: _cardStatItem(
                                    label: 'Sisa Waktu',
                                    value: _jatuhTempo == null
                                        ? '-'
                                        : _sisaHari < 0
                                        ? 'Lewat jatuh tempo!'
                                        : _sisaHari == 0
                                        ? 'Hari ini!'
                                        : '✓ $_sisaHari hari lagi',
                                    valueColor: _sisaHari <= 1
                                        ? const Color(0xFFFF5252)
                                        : const Color(0xFF69F0AE),
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white24),
                                Expanded(
                                  child: _cardStatItem(
                                    label: 'Bayar Bulan Ini',
                                    value:
                                    'Rp ${_formatRupiah(_totalBulanIni)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Alert jatuh tempo ─────────────
                      if (_jatuhTempo != null && _sisaHari <= 3)
                        _buildAlert(),

                      const SizedBox(height: 16),

                      // ── Tombol Bayar ──────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => MainScreen.goToTab(1),
                          icon: const Icon(Icons.payment_rounded),
                          label: const Text('BAYAR TAGIHAN SEKARANG'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Riwayat Terakhir ──────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaksi Terakhir',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText)),
                        if (_riwayat.isNotEmpty)
                          TextButton(
                            onPressed: () => MainScreen.goToTab(2),
                            child: const Text('Lihat Semua',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryGreen)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen),
                        ),
                      )
                    else if (belumAdaKios || _riwayat.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 44, color: AppTheme.greyText),
                            SizedBox(height: 10),
                            Text('Belum ada transaksi',
                                style: TextStyle(
                                    color: AppTheme.greyText, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                    // Grid 2 kolom riwayat terakhir
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.55,
                        ),
                        itemCount:
                        _riwayat.length > 4 ? 4 : _riwayat.length,
                        itemBuilder: (context, index) =>
                            _riwayatCard(_riwayat[index]),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardStatItem({
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _buildAlert() {
    final isLewat = _sisaHari < 0;
    final isDanger = _sisaHari <= 1;
    final color = isLewat
        ? AppTheme.errorRed
        : isDanger
        ? const Color(0xFFE65100)
        : AppTheme.primaryGreen;
    final msg = isLewat
        ? 'Tagihan sudah melewati jatuh tempo!'
        : _sisaHari == 0
        ? 'Tagihan jatuh tempo hari ini!'
        : 'Tagihan jatuh tempo $_sisaHari hari lagi';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _riwayatCard(PembayaranModel p) {
    Color statusColor;
    IconData statusIcon;
    switch (p.status) {
      case 'berhasil':
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'gagal':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFE65100);
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                p.jenisPajak == 'harian'
                    ? Icons.today_rounded
                    : p.jenisPajak == 'mingguan'
                    ? Icons.date_range_rounded
                    : Icons.calendar_month_rounded,
                color: AppTheme.accentYellow,
                size: 18,
              ),
              Icon(statusIcon, color: statusColor, size: 15),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.jenisPajakLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText)),
          Text('Rp ${_formatRupiah(p.jumlah)}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen)),
          Text(
            p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal,
            style: const TextStyle(fontSize: 9, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }
}