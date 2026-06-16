import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/kios_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  final _nomorHpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;
  bool _loadingKios = false;
  String _selectedRole = 'pedagang';
  String _selectedGender = 'Laki-laki';
  String? _selectedNoKios;
  List<KiosModel> _kiosKosong = [];

  @override
  void initState() {
    super.initState();
    _loadKiosKosong();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  Future<void> _loadKiosKosong() async {
    setState(() => _loadingKios = true);
    final list = await FirestoreService.getKiosKosong();
    if (mounted) {
      setState(() {
        _kiosKosong = list;
        _loadingKios = false;
      });
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi kios untuk pedagang
    if (_selectedRole == 'pedagang' && _selectedNoKios == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih nomor kios terlebih dahulu'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cek username sudah dipakai
      final existingEmail = await FirestoreService.getEmailByUsername(
        _usernameController.text.trim(),
      );
      if (existingEmail != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username sudah digunakan, pilih yang lain'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      // Buat akun Firebase Auth
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;
      final noKios =
      _selectedRole == 'pedagang' ? (_selectedNoKios ?? '-') : '-';

      // Simpan user ke Firestore
      final user = UserModel(
        uid: uid,
        nama: _namaController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        nomorHp: _nomorHpController.text.trim(),
        gender: _selectedGender,
        role: _selectedRole,
        noKios: noKios,
      );

      await FirestoreService.saveUser(user);

      // Update status kios jadi aktif jika pedagang
      if (_selectedRole == 'pedagang' && _selectedNoKios != null) {
        await FirestoreService.updateStatusKios(
          noKios: _selectedNoKios!,
          status: 'aktif',
          namaPedagang: _namaController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login ✅'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (minimal 6 karakter)';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        default:
          message = 'Registrasi gagal: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Data Diri',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Nama
                            TextFormField(
                              controller: _namaController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon:
                                Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Nama wajib diisi';
                                if (v.trim().length < 3)
                                  return 'Nama minimal 3 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon:
                                Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Username wajib diisi';
                                if (v.trim().length < 4)
                                  return 'Username minimal 4 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _emailController,
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

                            // Nomor HP
                            TextFormField(
                              controller: _nomorHpController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Nomor HP',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Nomor HP wajib diisi';
                                if (v.trim().length < 10)
                                  return 'Nomor HP minimal 10 digit';
                                if (!RegExp(r'^[0-9+]+$').hasMatch(v.trim()))
                                  return 'Nomor HP hanya boleh angka';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Gender
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Laki-laki',
                                    child: Text('Laki-laki')),
                                DropdownMenuItem(
                                    value: 'Perempuan',
                                    child: Text('Perempuan')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedGender = v!),
                            ),
                            const SizedBox(height: 14),

                            // Role — tanpa admin
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'pedagang',
                                    child: Text('Pedagang')),
                                DropdownMenuItem(
                                    value: 'pengawas',
                                    child: Text('Pengawas')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _selectedRole = v!;
                                  _selectedNoKios = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            // Dropdown Kios — hanya muncul kalau role pedagang
                            if (_selectedRole == 'pedagang') ...[
                              _loadingKios
                                  ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryGreen),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Memuat daftar kios...',
                                        style: TextStyle(
                                            color: AppTheme.greyText)),
                                  ],
                                ),
                              )
                                  : _kiosKosong.isEmpty
                                  ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                  AppTheme.errorRed.withOpacity(0.05),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.errorRed
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: AppTheme.errorRed,
                                        size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tidak ada kios tersedia saat ini',
                                      style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                                  : DropdownButtonFormField<String>(
                                value: _selectedNoKios,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Kios',
                                  prefixIcon: Icon(
                                      Icons.storefront_outlined),
                                  hintText:
                                  'Pilih kios yang tersedia',
                                ),
                                items: _kiosKosong.map((kios) {
                                  return DropdownMenuItem(
                                    value: kios.noKios,
                                    child: Text(
                                      '${kios.noKios} — Zona ${kios.zona} (${kios.jenisJualan == '-' ? 'Kosong' : kios.jenisJualan})',
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(
                                        () => _selectedNoKios = v),
                                validator: (v) {
                                  if (_selectedRole == 'pedagang' &&
                                      v == null)
                                    return 'Pilih kios terlebih dahulu';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Password wajib diisi';
                                if (v.length < 6)
                                  return 'Password minimal 6 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Konfirmasi Password
                            TextFormField(
                              controller: _konfirmasiController,
                              obscureText: _obscureKonfirmasi,
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Password',
                                prefixIcon:
                                const Icon(Icons.lock_reset_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureKonfirmasi
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(() =>
                                  _obscureKonfirmasi =
                                  !_obscureKonfirmasi),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Konfirmasi password wajib diisi';
                                if (v != _passwordController.text)
                                  return 'Password tidak cocok';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                _isLoading ? null : _handleRegister,
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text('DAFTAR SEKARANG'),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}