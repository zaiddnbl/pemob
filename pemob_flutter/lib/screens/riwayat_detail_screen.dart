import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'riwayat_detail_screen.dart';

class RiwayatDetailScreen extends StatelessWidget {
  final PembayaranModel pembayaran;

  const RiwayatDetailScreen({super.key, required this.pembayaran});

  Color get _statusColor {
    switch (pembayaran.status) {
      case 'berhasil':
        return const Color(0xFF2E7D32);
      case 'gagal':
        return AppTheme.errorRed;
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData get _statusIcon {
    switch (pembayaran.status) {
      case 'berhasil':
        return Icons.check_circle_rounded;
      case 'gagal':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Status Card ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon, color: _statusColor, size: 52),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pembayaran.statusLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatRupiah(pembayaran.jumlah)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pembayaran.jenisPajakLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Detail Info ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Transaksi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRow('No. Transaksi', pembayaran.noTransaksi),
                    _buildRow('No. Kios', pembayaran.noKios),
                    _buildRow('Jenis Pajak', pembayaran.jenisPajakLabel),
                    _buildRow('Tanggal', pembayaran.tanggal),
                    _buildRow('Metode Bayar', pembayaran.metodeBayar),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bayar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'Rp ${_formatRupiah(pembayaran.jumlah)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tombol Kembali ─────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('KEMBALI'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}