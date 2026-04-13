import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/pembayaran_model.dart';
import '../theme/app_theme.dart';
import 'pembayaran_screen.dart';
import 'riwayat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  List<PembayaranModel> get _riwayatSaya {
    final noKios = SessionUser.currentUser?.noKios ?? '';
    final list = dummyPembayaran.where((p) => p.noKios == noKios).toList();
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }

  PembayaranModel? get _pembayaranTerakhir {
    final berhasil = _riwayatSaya.where((p) => p.status == 'berhasil').toList();
    return berhasil.isNotEmpty ? berhasil.first : null;
  }

  // Hitung tagihan berikutnya berdasarkan transaksi berhasil terakhir
  DateTime? get _tagihankBerikutnya {
    final last = _pembayaranTerakhir;
    if (last == null) return null;
    final lastDate = DateTime.parse(last.tanggal.split(' ')[0]);
    switch (last.jenisPajak) {
      case 'harian':
        return lastDate.add(const Duration(days: 1));
      case 'mingguan':
        return lastDate.add(const Duration(days: 7));
      case 'bulanan':
        return lastDate.add(const Duration(days: 30));
      default:
        return null;
    }
  }

  String _formatTanggal(DateTime dt) {
    final bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final firstName = user?.nama.split(' ').first ?? 'Pedagang';
    final noKios = user?.noKios ?? '-';
    final lastPay = _pembayaranTerakhir;
    final nextBill = _tagihankBerikutnya;
    final sisaHari = nextBill != null
        ? nextBill.difference(DateTime.now()).inDays
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppTheme.primaryGreen,
            automaticallyImplyLeading: false,
            title: Column(
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
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.accentYellow,
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      firstName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient dengan pola lingkaran
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Dekorasi lingkaran
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 60,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentYellow.withOpacity(0.12),
                      ),
                    ),
                  ),
                  // Teks welcome
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(
                                color: AppTheme.accentYellow,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋',
                                style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kios $noKios',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 3 Info Cards ──────────────────────────────
                  Row(
                    children: [
                      // Tagihan Berikutnya
                      Expanded(
                        child: _infoCard(
                          label: 'TAGIHAN BERIKUTNYA',
                          value: nextBill != null
                              ? _formatTanggal(nextBill)
                              : '-',
                          sub: sisaHari != null
                              ? 'Sisa $sisaHari hari'
                              : 'Belum ada data',
                          subColor: sisaHari != null && sisaHari <= 3
                              ? AppTheme.errorRed
                              : AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Jenis Pajak Terakhir
                      Expanded(
                        child: _infoCard(
                          label: 'JENIS PAJAK TERAKHIR',
                          value: lastPay?.jenisPajakLabel ?? '-',
                          sub: lastPay != null
                              ? _formatRupiah(lastPay.jumlah)
                              : '-',
                          subColor: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nomor Kios
                      Expanded(
                        child: _infoCard(
                          label: 'NOMOR KIOS',
                          value: noKios,
                          sub: '',
                          subColor: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Aksi Cepat ────────────────────────────────
                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _aksiCard(
                          icon: Icons.payment_rounded,
                          title: 'Bayar Pajak',
                          subtitle: 'Lakukan pembayaran sekarang',
                          color: AppTheme.primaryGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PembayaranScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _aksiCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Riwayat Bayar',
                          subtitle: 'Lihat semua transaksi Anda',
                          color: const Color(0xFF6B7280),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RiwayatScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Transaksi Terakhir ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaksi Terakhir',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RiwayatScreen()),
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Daftar 3 transaksi terakhir
                  ..._riwayatSaya.take(3).map((p) => _transaksiTile(p)),

                  if (_riwayatSaya.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 44, color: AppTheme.greyText),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                                color: AppTheme.greyText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Helpers ────────────────────────────────────────

  Widget _infoCard({
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AppTheme.greyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aksiCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transaksiTile(PembayaranModel p) {
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

    // Format tanggal singkat
    final parts = p.tanggal.split(' ');
    final date = parts[0]; // '2026-04-13'
    final time = parts.length > 1 ? parts[1].substring(0, 5) : '';

    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  '$date $time • ${p.metodeBayar}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${p.jumlah.toInt() >= 1000 ? _formatRupiahRaw(p.jumlah) : p.jumlah.toInt().toString()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRupiahRaw(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}