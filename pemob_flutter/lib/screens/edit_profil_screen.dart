import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _hpCtrl;
  late String _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = SessionUser.currentUser;
    _namaCtrl = TextEditingController(text: user?.nama ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _hpCtrl = TextEditingController(text: user?.nomorHp ?? '');
    _selectedGender =
    user?.gender.isNotEmpty == true ? user!.gender : 'Laki-laki';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  void _handleSimpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = SessionUser.currentUser;
    if (user == null) return;

    final success = await FirestoreService.updateProfil(
      uid: user.uid,
      nama: _namaCtrl.text.trim(),
      nomorHp: _hpCtrl.text.trim(),
      gender: _selectedGender,
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final updatedUser = UserModel(
        uid: user.uid,
        nama: _namaCtrl.text.trim(),
        username: user.username,
        email: _emailCtrl.text.trim(),
        nomorHp: _hpCtrl.text.trim(),
        gender: _selectedGender,
        role: user.role,
        noKios: user.noKios,
      );
      SessionUser.login(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diupdate ✅'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupdate profil'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
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
              const SizedBox(height: 8),
              Text(
                '@${user?.username ?? ''}',
                style: const TextStyle(
                    color: AppTheme.greyText, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _buildCard(children: [
                // Username read-only
                TextFormField(
                  initialValue: user?.username ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor: Color(0xFFF0F0F0),
                    helperText: 'Username tidak dapat diubah',
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Nama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email wajib diisi';
                    if (!v.contains('@'))
                      return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _hpCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(
                        value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedGender = v!),
                ),
              ]),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSimpan,
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('SIMPAN PERUBAHAN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }
}