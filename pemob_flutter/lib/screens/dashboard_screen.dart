import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/pembayaran_model.dart';
import '../models/kios_model.dart';
import '../theme/app_theme.dart';
import 'riwayat_detail_screen.dart';
import 'pembayaran_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isFavorite = false;

  // Ambil data pembayaran milik pedagang yang login saja
  List<PembayaranModel> get _pembayaranSaya {
    final user = SessionUser.currentUser;
    if (user == null) return [];
    return dummyPembayaran
        .where((p) => p.noKios == user.noKios)
        .toList();
  }

  KiosModel? get _kiosSaya {
    final user = SessionUser.currentUser;
    if (user == null || user.noKios == '-') return null;
    try {
      return dummyKios.firstWhere((k) => k.noKios == user.noKios);
    } catch (_) {
      return null;
    }
  }

  PembayaranModel? get _pembayaranBulanIni {
    final bulanSekarang = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ][DateTime.now().month - 1];

    try {
      return _pembayaranSaya.firstWhere(
            (p) => p.bulan == bulanSekarang && p.tahun == DateTime.now().year,
      );
    } catch (_) {
      return null;
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
    final user = SessionUser.currentUser;
    final kios = _kiosSaya;
    final bayarBulanIni = _pembayaranBulanIni;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite ? 'Ditambahkan ke favorit ❤️' : 'Dihapus dari favorit',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentYellow.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        // Avatar + badge online (Stack + Positioned)
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.accentYellow,
                              child: Text(
                                user?.nama.isNotEmpty == true
                                    ? user!.nama[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent[400],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.primaryGreen, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?.nama.split(' ').first ?? 'Pedagang'} 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentYellow.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppTheme.accentYellow
                                          .withOpacity(0.5)),
                                ),
                                child: const Text(
                                  'PEDAGANG',
                                  style: TextStyle(
                                    color: AppTheme.accentYellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
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
                  // ── Status Pembayaran Bulan Ini ──────────────
                  _buildSectionTitle('Status Bulan Ini'),
                  const SizedBox(height: 12),
                  _buildStatusBulanIni(bayarBulanIni, kios),

                  const SizedBox(height: 20),

                  // ── Info Kios Saya ───────────────────────────
                  _buildSectionTitle('Kios Saya'),
                  const SizedBox(height: 12),
                  kios != null ? _buildKiosCard(kios) : _buildNoKiosCard(),

                  const SizedBox(height: 20),

                  // ── Aksi Cepat ───────────────────────────────
                  _buildSectionTitle('Aksi Cepat'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAksiCard(
                          Icons.payment_rounded,
                          'Bayar Sewa',
                          'Lakukan pembayaran',
                          AppTheme.primaryGreen,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PembayaranScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAksiCard(
                          Icons.history_rounded,
                          'Riwayat',
                          'Lihat semua transaksi',
                          const Color(0xFF1565C0),
                              () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Riwayat Pembayaran Kios Sendiri ──────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Riwayat Saya'),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _pembayaranSaya.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pembayaranSaya.length,
                    itemBuilder: (context, index) {
                      return _buildRiwayatTile(
                          context, _pembayaranSaya[index]);
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Helpers ─────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildStatusBulanIni(PembayaranModel? bayar, KiosModel? kios) {
    final sudahBayar = bayar?.status == 'lunas';
    final terlambat = bayar?.status == 'telat';

    Color bgColor;
    Color iconColor;
    IconData icon;
    String statusText;
    String subText;

    if (sudahBayar) {
      bgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      statusText = 'Sudah Lunas ✅';
      subText =
      'Dibayar pada ${bayar!.tanggalBayar} via ${bayar.metodeBayar}';
    } else if (terlambat) {
      bgColor = const Color(0xFFFFEBEE);
      iconColor = AppTheme.errorRed;
      icon = Icons.warning_rounded;
      statusText = 'Pembayaran Terlambat ⚠️';
      subText = 'Segera bayar untuk menghindari denda';
    } else {
      bgColor = const Color(0xFFFFF8E1);
      iconColor = const Color(0xFFE65100);
      icon = Icons.pending_rounded;
      statusText = 'Belum Bayar Bulan Ini';
      subText = kios != null
          ? 'Tagihan: Rp ${_formatRupiah(kios.hargaSewa)}'
          : 'Segera lakukan pembayaran bulan ini';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          if (!sudahBayar)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PembayaranScreen()),
              ),
              style: TextButton.styleFrom(
                backgroundColor: iconColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Bayar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKiosCard(KiosModel kios) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kios ${kios.noKios}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      kios.jenisJualan,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  kios.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKiosInfoItem('Zona', kios.zona),
              _buildKiosInfoItem(
                  'Sewa/Bulan', 'Rp ${_formatRupiah(kios.hargaSewa)}'),
              _buildKiosInfoItem('Status', kios.statusLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKiosInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNoKiosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront_outlined,
              color: AppTheme.greyText, size: 32),
          SizedBox(width: 14),
          Text(
            'Belum ada kios terdaftar',
            style: TextStyle(color: AppTheme.greyText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCard(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style:
              const TextStyle(fontSize: 11, color: AppTheme.greyText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTile(BuildContext context, PembayaranModel p) {
    Color statusColor;
    IconData statusIcon;
    switch (p.status) {
      case 'lunas':
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'telat':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = const Color(0xFFE65100);
        statusIcon = Icons.pending_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RiwayatDetailScreen(pembayaran: p)),
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
                    '${p.bulan} ${p.tahun}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  Text(
                    p.tanggalBayar == '-'
                        ? 'Belum dibayar'
                        : 'Dibayar: ${p.tanggalBayar}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.greyText),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.statusLabel,
                    style: TextStyle(
                      color: statusColor,
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
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppTheme.greyText),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat pembayaran',
            style: TextStyle(color: AppTheme.greyText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}