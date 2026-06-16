import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/kios_model.dart';
import '../models/pembayaran_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'notifikasi_screen.dart';
import 'kios_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  void refreshData() {} // tetap ada supaya main_screen tidak error

  Future<void> _loadPhoto() async {
    final uid = SessionUser.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_photo_$uid');
      if (path != null) {
        final f = File(path);
        if (await f.exists() && mounted) setState(() => _photoFile = f);
      }
    } catch (_) {}
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
    final bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  DateTime? _hitungJatuhTempo(List<PembayaranModel> payments) {
    if (payments.isEmpty) return null;
    final berhasil = payments.where((p) => p.status == 'berhasil').toList();
    if (berhasil.isEmpty) return null;
    berhasil.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    DateTime? earliest;
    try {
      final parts = berhasil.first.tanggal.split(' ')[0].split('-');
      earliest = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) { return null; }
    int totalHari = 0;
    for (final p in berhasil) {
      switch (p.jenisPajak.toLowerCase()) {
        case 'harian':   totalHari += 1;  break;
        case 'mingguan': totalHari += 7;  break;
        case 'bulanan':  totalHari += 30; break;
      }
    }
    return earliest.add(Duration(days: totalHari));
  }

  double _totalBulanIni(List<PembayaranModel> riwayat) {
    final now = DateTime.now();
    return riwayat.where((p) {
      try {
        final parts = p.tanggal.split(' ')[0].split('-');
        final tgl = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return tgl.year == now.year && tgl.month == now.month && p.status == 'berhasil';
      } catch (_) { return false; }
    }).fold(0.0, (s, p) => s + p.jumlah);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final firstName = user?.nama.split(' ').first ?? 'Pedagang';
    final noKios = user?.noKios ?? '';
    final belumAdaKios = noKios.isEmpty || noKios == '-';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppTheme.primaryGreen,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Image.asset('assets/images/logo_hijau.png', height: 28,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SIPESEL', style: TextStyle(
                        color: AppTheme.accentYellow, fontSize: 16,
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('Sistem Pengelolaan Sewa Kios',
                        style: TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ],
            ),
            actions: [
              // Notifikasi dengan StreamBuilder badge
              StreamBuilder<int>(
                stream: FirestoreService.streamJumlahBelumDibaca(noKios),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                                color: AppTheme.errorRed, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(count > 9 ? '9+' : '$count',
                                style: const TextStyle(fontSize: 9,
                                    color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => MainScreen.goToTab(3),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.accentYellow,
                    backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                    child: _photoFile == null
                        ? Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w800, color: AppTheme.primaryGreen))
                        : null,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -30,
                      child: Container(width: 150, height: 150,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05)))),
                  Positioned(bottom: 60, left: -20,
                      child: Container(width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.04)))),
                  Positioned(bottom: 20, left: 20, right: 20,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Halo, $firstName 👋',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(user?.nama ?? 'Pedagang', style: const TextStyle(
                          color: AppTheme.accentYellow, fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _badge(Icons.storefront_rounded,
                            belumAdaKios ? 'Belum ada kios' : 'Kios $noKios'),
                        const SizedBox(width: 8),
                        _badge(Icons.location_on_outlined, 'Pasar Wadungasri'),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),

          // ── Body StreamBuilder ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (belumAdaKios)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentYellow.withOpacity(0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.accentYellow, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                            'Kamu belum memiliki kios. Hubungi admin untuk assign kios.',
                            style: TextStyle(fontSize: 12, color: AppTheme.darkText))),
                      ]),
                    ),

                  if (!belumAdaKios)
                    StreamBuilder<List<PembayaranModel>>(
                      stream: FirestoreService.streamPembayaranByKios(noKios),
                      builder: (context, snapPembayaran) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('kios')
                              .where('noKios', isEqualTo: noKios)
                              .limit(1)
                              .snapshots()
                              .map((q) => q.docs.first),
                          builder: (context, snapKios) {

                            if (snapPembayaran.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(color: AppTheme.primaryGreen)));
                            }

                            if (snapPembayaran.hasError) {
                              return Center(child: Text('Error: ${snapPembayaran.error}',
                                  style: const TextStyle(color: AppTheme.errorRed)));
                            }

                            final riwayat = snapPembayaran.data ?? [];
                            final jatuhTempo = _hitungJatuhTempo(riwayat);
                            final sisa = jatuhTempo?.difference(DateTime.now()).inDays ?? -99;
                            final total = _totalBulanIni(riwayat);

                            // Ambil data kios untuk detail
                            KiosModel? kiosData;
                            if (snapKios.hasData && snapKios.data!.exists) {
                              kiosData = KiosModel.fromFirestore(snapKios.data!);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card info kios
                                GestureDetector(
                                  onTap: kiosData != null
                                      ? () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => KiosDetailScreen(kios: kiosData!)))
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(
                                          color: AppTheme.primaryGreen.withOpacity(0.3),
                                          blurRadius: 15, offset: const Offset(0, 5))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              const Text('Kios', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                              Text(noKios, style: const TextStyle(
                                                  color: AppTheme.accentYellow, fontSize: 28,
                                                  fontWeight: FontWeight.w900)),
                                            ]),
                                            Row(children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(20)),
                                                child: const Row(children: [
                                                  Icon(Icons.circle, color: Color(0xFF69F0AE), size: 8),
                                                  SizedBox(width: 5),
                                                  Text('Aktif', style: TextStyle(
                                                      color: Colors.white, fontSize: 12,
                                                      fontWeight: FontWeight.w600)),
                                                ]),
                                              ),
                                              // Tombol detail kios
                                              if (kiosData != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                      color: AppTheme.accentYellow.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(20)),
                                                  child: const Row(children: [
                                                    Text('Detail', style: TextStyle(
                                                        color: AppTheme.accentYellow, fontSize: 11,
                                                        fontWeight: FontWeight.w700)),
                                                    SizedBox(width: 4),
                                                    Icon(Icons.arrow_forward_rounded,
                                                        color: AppTheme.accentYellow, size: 12),
                                                  ]),
                                                ),
                                              ],
                                            ]),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        const Divider(color: Colors.white24, height: 1),
                                        const SizedBox(height: 16),
                                        Row(children: [
                                          Expanded(child: _cardStatItem(
                                              label: 'Tagihan Berikutnya',
                                              value: jatuhTempo != null
                                                  ? _formatTanggalPanjang(jatuhTempo)
                                                  : 'Belum ada')),
                                          Container(width: 1, height: 40, color: Colors.white24),
                                          Expanded(child: _cardStatItem(
                                              label: 'Sisa Waktu',
                                              value: jatuhTempo == null ? '-'
                                                  : sisa < 0 ? 'Lewat jatuh tempo!'
                                                  : sisa == 0 ? 'Hari ini!'
                                                  : '✓ $sisa hari lagi',
                                              valueColor: sisa <= 1
                                                  ? const Color(0xFFFF5252)
                                                  : const Color(0xFF69F0AE))),
                                          Container(width: 1, height: 40, color: Colors.white24),
                                          Expanded(child: _cardStatItem(
                                              label: 'Bayar Bulan Ini',
                                              value: 'Rp ${_formatRupiah(total)}')),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                if (jatuhTempo != null && sisa <= 3) _buildAlert(sisa),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => MainScreen.goToTab(1),
                                    icon: const Icon(Icons.payment_rounded),
                                    label: const Text('BAYAR TAGIHAN SEKARANG'),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14)),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Riwayat transaksi
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Transaksi Terakhir',
                                        style: TextStyle(fontSize: 15,
                                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                                    if (riwayat.isNotEmpty)
                                      TextButton(
                                        onPressed: () => MainScreen.goToTab(2),
                                        child: const Text('Lihat Semua',
                                            style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (riwayat.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(28),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16)),
                                    child: const Column(children: [
                                      Icon(Icons.receipt_long_outlined,
                                          size: 44, color: AppTheme.greyText),
                                      SizedBox(height: 10),
                                      Text('Belum ada transaksi',
                                          style: TextStyle(color: AppTheme.greyText, fontSize: 13)),
                                    ]),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, crossAxisSpacing: 10,
                                        mainAxisSpacing: 10, childAspectRatio: 1.55),
                                    itemCount: riwayat.length > 4 ? 4 : riwayat.length,
                                    itemBuilder: (context, index) => _riwayatCard(riwayat[index]),
                                  ),

                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _cardStatItem({required String label, required String value,
    Color valueColor = Colors.white}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor,
              fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _buildAlert(int sisa) {
    final isLewat = sisa < 0;
    final isDanger = sisa <= 1;
    final color = isLewat ? AppTheme.errorRed
        : isDanger ? const Color(0xFFE65100)
        : AppTheme.primaryGreen;
    final msg = isLewat ? 'Tagihan sudah melewati jatuh tempo!'
        : sisa == 0 ? 'Tagihan jatuh tempo hari ini!'
        : 'Tagihan jatuh tempo $sisa hari lagi';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _riwayatCard(PembayaranModel p) {
    Color statusColor;
    IconData statusIcon;
    switch (p.status) {
      case 'berhasil': statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded; break;
      case 'gagal': statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel_rounded; break;
      default: statusColor = const Color(0xFFE65100);
      statusIcon = Icons.pending_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(p.jenisPajak == 'harian' ? Icons.today_rounded
                : p.jenisPajak == 'mingguan' ? Icons.date_range_rounded
                : Icons.calendar_month_rounded,
                color: AppTheme.accentYellow, size: 18),
            Icon(statusIcon, color: statusColor, size: 15),
          ]),
          const SizedBox(height: 4),
          Text(p.jenisPajakLabel, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.darkText)),
          Text('Rp ${_formatRupiah(p.jumlah)}', style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
          Text(p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal,
              style: const TextStyle(fontSize: 9, color: AppTheme.greyText)),
        ],
      ),
    );
  }
}