import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class PengawasProfilScreen extends StatefulWidget {
  const PengawasProfilScreen({super.key});

  @override
  State<PengawasProfilScreen> createState() => _PengawasProfilScreenState();
}

class _PengawasProfilScreenState extends State<PengawasProfilScreen> {
  static const Color _color = const Color(0xFF1B5E20);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  File? _photoFile;
  bool _isLoadingPhoto = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPhoto();
  }

  Future<void> _loadSavedPhoto() async {
    final uid = SessionUser.currentUser?.uid ?? 'unknown';
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('profile_photo_${uid}');
    if (savedPath != null) {
      final file = File(savedPath);
      if (await file.exists() && mounted) {
        setState(() => _photoFile = file);
      }
    }
    if (mounted) setState(() => _isLoadingPhoto = false);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Foto Profil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _color)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color.withOpacity(0.3)),
                      ),
                      child: const Column(children: [
                        Icon(Icons.camera_alt_rounded, color: _color, size: 28),
                        SizedBox(height: 6),
                        Text('Kamera', style: TextStyle(color: _color, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _color.withOpacity(0.3)),
                      ),
                      child: const Column(children: [
                        Icon(Icons.photo_library_rounded, color: _color, size: 28),
                        SizedBox(height: 6),
                        Text('Galeri', style: TextStyle(color: _color, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked == null || !mounted) return;

    final uid = SessionUser.currentUser?.uid ?? 'unknown';
    final appDir = await getApplicationDocumentsDirectory();
    final permanentPath = '${appDir.path}/profile_${uid}.jpg';
    final permanentFile = await File(picked.path).copy(permanentPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_${uid}', permanentPath);

    if (mounted) setState(() => _photoFile = permanentFile);
  }

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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
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
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Edit Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _color)),
                  const Text('Username tidak dapat diubah', style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                  const SizedBox(height: 20),
                  _inputBox(child: TextFormField(initialValue: user.username, enabled: false,
                      decoration: const InputDecoration(labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email_rounded, color: _color, size: 20),
                          border: InputBorder.none, filled: true, fillColor: Color(0xFFEEEEEE)))),
                  const SizedBox(height: 10),
                  _inputBox(child: TextField(controller: namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: _color, size: 20),
                          border: InputBorder.none))),
                  const SizedBox(height: 10),
                  _inputBox(child: TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: _color, size: 20),
                          border: InputBorder.none))),
                  const SizedBox(height: 10),
                  _inputBox(child: TextField(controller: hpCtrl, keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Nomor HP',
                          prefixIcon: Icon(Icons.phone_outlined, color: _color, size: 20),
                          border: InputBorder.none))),
                  const SizedBox(height: 10),
                  _inputBox(child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: 'Jenis Kelamin',
                          prefixIcon: Icon(Icons.wc_outlined, color: _color, size: 20),
                          border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                      ],
                      onChanged: (v) => setModal(() => selectedGender = v!))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModal(() => isSaving = true);
                        final u = SessionUser.currentUser;
                        if (u == null) return;
                        final success = await FirestoreService.updateProfil(
                            uid: u.uid, nama: namaCtrl.text.trim(),
                            nomorHp: hpCtrl.text.trim(), gender: selectedGender,
                            email: emailCtrl.text.trim());
                        if (!sheetCtx.mounted) return;
                        if (success) {
                          SessionUser.login(UserModel(uid: u.uid, nama: namaCtrl.text.trim(),
                              username: u.username, email: emailCtrl.text.trim(),
                              nomorHp: hpCtrl.text.trim(), gender: selectedGender,
                              role: u.role, noKios: u.noKios));
                          Navigator.pop(sheetCtx);
                          setState(() {});
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Profil berhasil diupdate ✅'),
                              backgroundColor: AppTheme.accentGreen));
                        } else {
                          setModal(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('SIMPAN PERUBAHAN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        // Tambahkan padding di actions agar lebih rapi
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              // Sisi Kiri: Tombol Keluar
              Expanded(
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(width: 12), // Jarak antara kiri dan kanan

              // Sisi Kanan: Tombol Batal
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        // Opsional: tambah border tipis untuk tombol batal agar lebih kentara
                        side: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
    final initial = user?.nama.isNotEmpty == true ? user!.nama[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _color,
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _showEditProfil),
            ],
            title: Text('Profil Pengawas', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_color.withOpacity(0.9), _color, _color.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -30, child: Container(width: 140, height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)))),
                  Positioned(bottom: 10, left: -20, child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04)))),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(children: [
                        _isLoadingPhoto
                            ? CircleAvatar(radius: 40, backgroundColor: AppTheme.accentYellow,
                            child: CircularProgressIndicator(color: _color, strokeWidth: 2))
                            : CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.accentYellow,
                            backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                            child: _photoFile == null
                                ? Text(initial, style: TextStyle(fontSize: 30,
                                fontWeight: FontWeight.w900, color: _color))
                                : null),
                        Positioned(bottom: 0, right: 0, child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: AppTheme.accentYellow,
                                shape: BoxShape.circle,
                                border: Border.all(color: _color, width: 2)),
                            child: Icon(Icons.camera_alt_rounded, size: 12, color: _color))),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text(user?.nama ?? 'User', style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w800)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('PENGAWAS', style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ])),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(children: [
                _sectionCard('Informasi Akun', Icons.person_rounded, [
                  _infoRow(Icons.person_outline_rounded, 'Nama', user?.nama ?? '-'),
                  _divider(),
                  _infoRow(Icons.alternate_email_rounded, 'Username', user?.username ?? '-'),
                  _divider(),
                  _infoRow(Icons.email_outlined, 'Email', user?.email ?? '-'),
                  _divider(),
                  _infoRow(Icons.phone_outlined, 'No. HP',
                      user?.nomorHp.isNotEmpty == true ? user!.nomorHp : '-'),
                  _divider(),
                  _infoRow(Icons.wc_outlined, 'Gender', _normaliseGender(user?.gender)),
                  _divider(),
                  _infoRow(Icons.badge_outlined, 'Role', 'Pengawas'),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showEditProfil,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _color.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit_outlined, color: _color, size: 18),
                      const SizedBox(width: 8),
                      Text('Edit Profil', style: TextStyle(color: _color, fontSize: 14,
                          fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard('Informasi Sistem', Icons.info_outline_rounded, [
                  _infoRow(Icons.storefront_outlined, 'Pasar', 'Pasar Wadungasri, Sidoarjo'),
                  _divider(),
                  _infoRow(Icons.verified_outlined, 'Versi App', 'SIPESEL v1.0.0'),
                  _divider(),
                  _infoRow(Icons.cloud_outlined, 'Database', 'Cloud Firestore'),
                ]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Keluar dari Akun', style: TextStyle(color: Colors.red.shade600,
                          fontSize: 15, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox({required Widget child}) => Container(
      decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 4), child: child);

  Widget _sectionCard(String title, IconData icon, List<Widget> children) => Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [Icon(icon, color: _color, size: 18), const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _color))])),
        const Divider(height: 1), ...children]));

  Widget _infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: _color), const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.greyText))),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _color))),
      ]));

  Widget _divider() => const Divider(height: 1, indent: 46);
}