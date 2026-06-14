import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../edit_profil_screen.dart';
import '../login_screen.dart';

class PengawasProfilScreen extends StatefulWidget {
  const PengawasProfilScreen({super.key});

  @override
  State<PengawasProfilScreen> createState() => _PengawasProfilScreenState();
}

class _PengawasProfilScreenState extends State<PengawasProfilScreen> {
  // Refresh tampilan setelah kembali dari EditProfilScreen
  void _toEditProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilScreen()),
    ).then((_) => setState(() {}));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon lingkaran merah
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.errorRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keluar dari Akun?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apakah kamu yakin ingin keluar dari akun ini?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.greyText),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              // Tombol Batal
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: AppTheme.greyText,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Keluar
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FirebaseAuth.instance.signOut();
                    SessionUser.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final nama = user?.nama ?? '-';
    final initial =
        nama.trim().isNotEmpty ? nama.trim()[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ───────────────────────────────
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primaryGreen,
            title: const Text(
              'Profil Saya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Avatar & Identitas ────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppTheme.accentYellow,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nama,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? '-'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pengawas',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Info Card ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                          value: user?.username ?? '-',
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Nama Lengkap',
                          value: nama,
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '-',
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.phone_outlined,
                          label: 'Nomor HP',
                          value: user?.nomorHp ?? '-',
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.wc_rounded,
                          label: 'Jenis Kelamin',
                          value: user?.gender ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Tombol Edit Profil ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toEditProfil,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tombol Keluar ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.errorRed, size: 18),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppTheme.errorRed, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.greyText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 68, endIndent: 16, color: Color(0xFFEEEEEE));
}