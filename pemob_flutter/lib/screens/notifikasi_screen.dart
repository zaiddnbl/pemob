import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  String _formatWaktu(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = createdAt.toDate() as DateTime;
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final noKios = SessionUser.currentUser?.noKios ?? '';
    final belumAdaKios = noKios == '-' || noKios.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: belumAdaKios
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 52, color: AppTheme.greyText),
            SizedBox(height: 12),
            Text('Belum ada kios terdaftar',
                style: TextStyle(color: AppTheme.greyText)),
          ],
        ),
      )
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.streamNotifikasi(noKios),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen),
            );
          }

          final notifs = snapshot.data ?? [];

          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 52, color: AppTheme.greyText),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Notifikasi muncul ketika admin\nmemverifikasi pembayaranmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.greyText, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final notif = notifs[index];
              final dibaca = notif['dibaca'] == true;

              return GestureDetector(
                onTap: () {
                  if (!dibaca) {
                    FirestoreService.tandaiDibaca(notif['id']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dibaca
                        ? Colors.white
                        : AppTheme.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: dibaca
                          ? Colors.grey.shade200
                          : AppTheme.primaryGreen.withOpacity(0.3),
                      width: dibaca ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['judul'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: dibaca
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ),
                                if (!dibaca)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['pesan'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.greyText,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatWaktu(notif['createdAt']),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.greyText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}