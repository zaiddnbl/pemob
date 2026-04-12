import 'package:flutter/material.dart';
import '../models/user_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
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
                        // Avatar dengan Stack + Positioned
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
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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
                  // Info akun
                  _buildSectionCard(
                    'Informasi Akun',
                    [
                      _buildInfoTile(Icons.person_outline_rounded, 'Nama', user?.nama ?? '-'),
                      _buildInfoTile(Icons.alternate_email_rounded, 'Username', user?.username ?? '-'),
                      _buildInfoTile(Icons.email_outlined, 'Email', user?.email ?? '-'),
                      _buildInfoTile(Icons.phone_outlined, 'No. HP', user?.nomorHp ?? '-'),
                      _buildInfoTile(Icons.storefront_outlined, 'No. Kios', user?.noKios ?? '-'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notifikasi (StatefulWidget setState)
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

                  const SizedBox(height: 24),

                  // Tombol logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SessionUser.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
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

  Widget _buildSwitchTile(
      IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.darkText)),
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