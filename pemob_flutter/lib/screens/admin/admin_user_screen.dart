import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manajemen User',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _navyDark)),
                        Text('Kelola pedagang & pengawas',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.greyText)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showTambahUser(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Tambah',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search
                Container(
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama, username, email...',
                      hintStyle:
                      TextStyle(fontSize: 13, color: AppTheme.greyText),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppTheme.greyText, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: _navyDark,
                  indicatorWeight: 3,
                  labelColor: _navyDark,
                  unselectedLabelColor: AppTheme.greyText,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Pedagang'),
                    Tab(text: 'Pengawas'),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UserList(
                    role: 'pedagang', searchQuery: _searchQuery),
                _UserList(
                    role: 'pengawas', searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTambahUser(BuildContext context) {
    final namaCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final hpCtrl = TextEditingController();
    final kiosCtrl = TextEditingController();
    String selectedRole = 'pedagang';
    String selectedGender = 'Laki-laki';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
                const Text('Tambah User Baru',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A3C34))),
                const Text('Password default: password123',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.greyText)),
                const SizedBox(height: 20),
                _inputField(namaCtrl, 'Nama Lengkap',
                    Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _inputField(usernameCtrl, 'Username',
                    Icons.alternate_email_rounded),
                const SizedBox(height: 10),
                _inputField(
                    emailCtrl, 'Email', Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _inputField(hpCtrl, 'Nomor HP', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 10),
                _dropdownField(
                  label: 'Role',
                  icon: Icons.badge_outlined,
                  value: selectedRole,
                  items: const ['pedagang', 'pengawas', 'admin'],
                  onChanged: (v) =>
                      setModalState(() => selectedRole = v!),
                ),
                const SizedBox(height: 10),
                _dropdownField(
                  label: 'Jenis Kelamin',
                  icon: Icons.wc_outlined,
                  value: selectedGender,
                  items: const ['Laki-laki', 'Perempuan'],
                  onChanged: (v) =>
                      setModalState(() => selectedGender = v!),
                ),
                if (selectedRole == 'pedagang') ...[
                  const SizedBox(height: 10),
                  _inputField(
                      kiosCtrl, 'No. Kios', Icons.storefront_outlined),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirestoreService.saveUser(UserModel(
                        uid: DateTime.now().millisecondsSinceEpoch.toString(),
                        nama: namaCtrl.text.trim(),
                        username: usernameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        nomorHp: hpCtrl.text.trim(),
                        gender: selectedGender,
                        role: selectedRole,
                        noKios: selectedRole == 'pedagang'
                            ? kiosCtrl.text.trim()
                            : '-',
                      ));
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('User berhasil ditambahkan ✅'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C34),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('TAMBAH USER',
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

  Widget _inputField(TextEditingController ctrl, String label,
      IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A3C34), size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
          Icon(icon, color: const Color(0xFF1A3C34), size: 20),
          border: InputBorder.none,
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String role;
  final String searchQuery;

  const _UserList({required this.role, required this.searchQuery});

  static const Color _navyDark = Color(0xFF1A3C34);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService.streamUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1A3C34)));
        }

        var users = snapshot.data ?? [];
        if (searchQuery.isNotEmpty) {
          users = users
              .where((u) =>
          u.nama
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
              u.username
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              u.email
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
              .toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.people_outline_rounded,
                      size: 40, color: AppTheme.greyText),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty
                      ? 'Tidak ada hasil pencarian'
                      : 'Belum ada $role terdaftar',
                  style: const TextStyle(color: AppTheme.greyText),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final colors = [
              const Color(0xFF1A3C34),
              const Color(0xFF2D5A4E),
              const Color(0xFF1B6B3A),
              const Color(0xFF0F4C35),
            ];
            final color = colors[index % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  child: Text(
                    user.nama.isNotEmpty
                        ? user.nama[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
                title: Text(user.nama,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navyDark)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${user.username} • ${user.email}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.greyText)),
                    if (role == 'pedagang' && user.noKios != '-')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Kios ${user.noKios}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.greyText),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) =>
                      _handleAction(context, value, user),
                  itemBuilder: (_) => [
                    _menuItem(
                        'detail', 'Lihat Detail', Icons.visibility_outlined),
                    _menuItem('edit', 'Edit Data', Icons.edit_outlined),
                    _menuItem('reset', 'Reset Password',
                        Icons.lock_reset_rounded),
                    _menuItem('hapus', 'Hapus',
                        Icons.delete_outline_rounded,
                        isRed: true),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, String label, IconData icon,
      {bool isRed = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isRed ? Colors.red : const Color(0xFF1A3C34)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: isRed ? Colors.red : const Color(0xFF1A3C34),
                  fontSize: 13)),
        ],
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, UserModel user) {
    switch (action) {
      case 'detail':
        _showDetail(context, user);
        break;
      case 'edit':
        _showEdit(context, user);
        break;
      case 'reset':
        _resetPassword(context, user);
        break;
      case 'hapus':
        _hapusUser(context, user);
        break;
    }
  }

  void _showDetail(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: _navyDark,
              child: Text(
                user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(user.nama,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _navyDark)),
            Text('@${user.username}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.greyText)),
            const SizedBox(height: 20),
            _detailRow('Email', user.email),
            _detailRow('No. HP',
                user.nomorHp.isNotEmpty ? user.nomorHp : '-'),
            _detailRow('Gender',
                user.gender.isNotEmpty ? user.gender : '-'),
            _detailRow('Role', user.role.toUpperCase()),
            if (user.role == 'pedagang')
              _detailRow('No. Kios', user.noKios),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.greyText)),
          ),
          Expanded(
            child: Text(': $value',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _navyDark)),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context, UserModel user) {
    final namaCtrl = TextEditingController(text: user.nama);
    final emailCtrl = TextEditingController(text: user.email);
    final hpCtrl = TextEditingController(text: user.nomorHp);
    final kiosCtrl = TextEditingController(text: user.noKios);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              Text('Edit ${user.nama}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _navyDark)),
              const SizedBox(height: 16),
              _buildInput(namaCtrl, 'Nama'),
              const SizedBox(height: 10),
              _buildInput(emailCtrl, 'Email'),
              const SizedBox(height: 10),
              _buildInput(hpCtrl, 'No. HP'),
              if (user.role == 'pedagang') ...[
                const SizedBox(height: 10),
                _buildInput(kiosCtrl, 'No. Kios'),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirestoreService.updateUser(
                      uid: user.uid,
                      nama: namaCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      nomorHp: hpCtrl.text.trim(),
                      noKios: user.role == 'pedagang'
                          ? kiosCtrl.text.trim()
                          : user.noKios,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil diupdate ✅'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('SIMPAN',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _resetPassword(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Text(
            'Kirim email reset password ke ${user.email}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: user.email);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email reset dikirim ✅'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _navyDark),
            child: const Text('Kirim',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _hapusUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus User'),
        content: Text('Hapus data ${user.nama}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService.deleteUser(user.uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}