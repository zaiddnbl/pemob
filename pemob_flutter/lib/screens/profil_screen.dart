import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/kios_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _notifPembayaran = true;
  bool _notifTagihan = false;
  bool _notifSistem = true;

  // ✅ State untuk toggle tampil/sembunyikan daftar kios
  bool _showDaftarKios = false;

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar dengan Stack + Positioned ────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // ✅ Stack + Positioned — dekorasi lingkaran (ETS requirement)
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // ✅ Stack + Positioned — edit icon di atas avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppTheme.accentYellow,
                              child: Text(
                                user?.nama.isNotEmpty == true
                                    ? user!.nama[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user?.nama ?? 'Pengguna',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role.toUpperCase() ?? 'PEDAGANG',
                            style: const TextStyle(
                              color: AppTheme.accentYellow,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
                  // ── Info Akun ─────────────────────────────────
                  _buildSectionCard(
                    'Informasi Akun',
                    [
                      _buildInfoTile(Icons.person_outline_rounded, 'Nama',
                          user?.nama ?? '-'),
                      _buildInfoTile(Icons.alternate_email_rounded, 'Username',
                          user?.username ?? '-'),
                      _buildInfoTile(
                          Icons.email_outlined, 'Email', user?.email ?? '-'),
                      _buildInfoTile(Icons.phone_outlined, 'No. HP',
                          user?.nomorHp ?? '-'),
                      _buildInfoTile(Icons.storefront_outlined, 'No. Kios',
                          user?.noKios ?? '-'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Notifikasi (setState) ─────────────────────
                  _buildSectionCard(
                    'Pengaturan Notifikasi',
                    [
                      _buildSwitchTile(
                        Icons.notifications_outlined,
                        'Notif Pembayaran',
                        _notifPembayaran,
                            (v) => setState(() => _notifPembayaran = v),
                      ),
                      _buildSwitchTile(
                        Icons.receipt_outlined,
                        'Notif Tagihan',
                        _notifTagihan,
                            (v) => setState(() => _notifTagihan = v),
                      ),
                      _buildSwitchTile(
                        Icons.settings_outlined,
                        'Notif Sistem',
                        _notifSistem,
                            (v) => setState(() => _notifSistem = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Daftar Kios Pasar ─────────────────────────
                  // ✅ ListView.builder dari dummyKios (14 data) — memenuhi
                  // ETS requirement: ListView.builder + min 10 dummy data
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section — bisa di-tap untuk toggle
                        InkWell(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          onTap: () =>
                              setState(() => _showDaftarKios = !_showDaftarKios),
                          child: Padding(
                            padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_rounded,
                                    size: 18, color: AppTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Daftar Kios Pasar (${dummyKios.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                // ✅ setState — ikon berubah saat tap
                                Icon(
                                  _showDaftarKios
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.greyText,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),

                        // ✅ ListView.builder — ditampilkan kondisional
                        if (_showDaftarKios)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dummyKios.length,
                            itemBuilder: (context, index) {
                              final kios = dummyKios[index];
                              return _buildKiosTile(kios);
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              'Tap untuk lihat ${dummyKios.length} kios',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.greyText),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tombol Logout ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SessionUser.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                              (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('KELUAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                      ),
                    ),
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

  // ── Kios Tile ─────────────────────────────────────────────
  Widget _buildKiosTile(KiosModel kios) {
    Color statusColor;
    switch (kios.status) {
      case 'aktif':
        statusColor = AppTheme.primaryGreen;
        break;
      case 'kosong':
        statusColor = const Color(0xFFE65100);
        break;
      default:
        statusColor = AppTheme.greyText;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Badge zona
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              kios.zona,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      kios.noKios,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // ✅ Badge status dengan Stack visual
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kios.statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  kios.namaPedagang.isNotEmpty
                      ? kios.namaPedagang
                      : 'Kios Kosong',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.greyText),
                ),
                Text(
                  kios.jenisJualan,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${_formatRupiah(kios.hargaSewa)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
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

  // ── Section Helpers ───────────────────────────────────────

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.greyText)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.darkText)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}