import 'package:flutter/material.dart';
import '../models/kios_model.dart';
import '../theme/app_theme.dart';

class KiosCard extends StatelessWidget {
  final KiosModel kios;
  final VoidCallback? onTap;

  const KiosCard({super.key, required this.kios, this.onTap});

  Color get _statusColor {
    switch (kios.status) {
      case 'aktif':
        return AppTheme.primaryGreen;
      case 'kosong':
        return const Color(0xFFE65100);
      default:
        return AppTheme.greyText;
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge zona
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      kios.zona,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kios.statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kios ${kios.noKios}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                kios.jenisJualan.isNotEmpty && kios.jenisJualan != '-'
                    ? kios.jenisJualan
                    : 'Tersedia',
                style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (kios.namaPedagang.isNotEmpty)
                Text(
                  kios.namaPedagang,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                'Rp ${_formatRupiah(kios.hargaSewa)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
