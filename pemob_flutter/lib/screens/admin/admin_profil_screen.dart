import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class AdminProfilScreen extends StatefulWidget {
  const AdminProfilScreen({super.key});

  @override
  State<AdminProfilScreen> createState() => _AdminProfilScreenState();
}

class _AdminProfilScreenState extends State<AdminProfilScreen> {
  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  String _normaliseGender(String? raw) {
    if (raw == null || raw.isEmpty) return 'Laki-laki';
    final lower = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (lower.contains('perempu')) return 'Perempuan';
    return 'Laki-laki';
  }

  void _showEditProfil() {
    final user = SessionUser.currentUser;
    if (user == null) return;

    final namaCtrl = TextEditingController(text: user.nama);
    final emailCtrl = TextEditingController(text: user.email);
    final hpCtrl = TextEditingController(text: user.nomorHp);
    String selectedGender = _normaliseGender(user.gender);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                const Text('Edit Profil',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navyDark)),
                const Text('Username tidak dapat diubah',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.greyText)),
                const SizedBox(height: 20),

                _inputField(child: TextFormField(
                  initialValue: user.username,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: _navyDark, size: 20),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFEEEEEE),
                  ),
                )),
                const SizedBox(height: 10),

                _inputField(child: TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: _navyDark, size: 20),
                    border: InputBorder.none,
                  ),
                )),
                const SizedBox(height: 10),

                _inputField(child: TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: _navyDark, size: 20),
                    border: InputBorder.none,
                  ),
                )),
                const SizedBox(height: 10),

                _inputField(child: TextField(
                  controller: hpCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: _navyDark, size: 20),
                    border: InputBorder.none,
                  ),
                )),
                const SizedBox(height: 10),

                _inputField(child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    prefixIcon: Icon(Icons.wc_outlined,
                        color: _navyDark, size: 20),
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (v) => setModal(() => selectedGender = v!),
                )),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setModal(() => isSaving = true);
                      final u = SessionUser.currentUser;
                      if (u == null) return;

                      final success = await FirestoreService.updateProfil(
                        uid: u.uid,
                        nama: namaCtrl.text.trim(),
                        nomorHp: hpCtrl.text.trim(),
                        gender: selectedGender,
                        email: emailCtrl.text.trim(),
                      );

                      if (!ctx.mounted) return;

                      if (success) {
                        SessionUser.login(UserModel(
                          uid: u.uid,
                          nama: namaCtrl.text.trim(),
                          username: u.username,
                          email: emailCtrl.text.trim(),
                          nomorHp: hpCtrl.text.trim(),
                          gender: selectedGender,
                          role: u.role,
                          noKios: u.noKios,
                        ));
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Profil berhasil diupdate ✅'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      } else {
                        setModal(() => isSaving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal mengupdate profil'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('SIMPAN PERUBAHAN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              SessionUser.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final initial = user?.nama.isNotEmpty == true
        ? user!.nama[0].toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: _bgGrey,
      // Tidak pakai AppBar — navbar dari AdminMainScreen
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _navyDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _showEditProfil,
                tooltip: 'Edit Profil',
              ),
            ],
            title: const Text(
              'Profil Admin',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F2D25),
                      Color(0xFF1A3C34),
                      Color(0xFF2D5A4E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -30,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: _showEditProfil,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppTheme.accentYellow,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: _navyDark,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentYellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _navyDark, width: 2),
                                    ),
                                    child: const Icon(Icons.edit,
                                        size: 12, color: _navyDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.nama ?? 'Admin',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('ADMIN',
                                style: TextStyle(
                                    color: AppTheme.accentYellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Informasi Akun
                  _sectionCard(
                    title: 'Informasi Akun',
                    icon: Icons.person_rounded,
                    children: [
                      _infoRow(Icons.person_outline_rounded, 'Nama',
                          user?.nama ?? '-'),
                      _divider(),
                      _infoRow(Icons.alternate_email_rounded, 'Username',
                          user?.username ?? '-'),
                      _divider(),
                      _infoRow(Icons.email_outlined, 'Email',
                          user?.email ?? '-'),
                      _divider(),
                      _infoRow(Icons.phone_outlined, 'No. HP',
                          user?.nomorHp.isNotEmpty == true
                              ? user!.nomorHp
                              : '-'),
                      _divider(),
                      _infoRow(Icons.wc_outlined, 'Gender',
                          _normaliseGender(user?.gender)),
                      _divider(),
                      _infoRow(Icons.badge_outlined, 'Role', 'Admin Pasar'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tombol Edit
                  GestureDetector(
                    onTap: _showEditProfil,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _navyDark.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _navyDark.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: _navyDark, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Profil',
                              style: TextStyle(
                                  color: _navyDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Informasi Sistem
                  _sectionCard(
                    title: 'Informasi Sistem',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _infoRow(Icons.storefront_outlined, 'Pasar',
                          'Pasar Wadungasri, Sidoarjo'),
                      _divider(),
                      _infoRow(Icons.verified_outlined, 'Versi App',
                          'SIPESEL v1.0.0'),
                      _divider(),
                      _infoRow(Icons.cloud_outlined, 'Database',
                          'Cloud Firestore'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tombol Logout
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Keluar dari Akun',
                              style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),

                  // Padding untuk navbar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: _navyDark, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _navyDark)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _navyDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.greyText)),
          ),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navyDark)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 46);
}