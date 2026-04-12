import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../theme/app_theme.dart';

class RiwayatDetailScreen extends StatelessWidget {
  final PembayaranModel pembayaran;

  const RiwayatDetailScreen({super.key, required this.pembayaran});

  Color get _statusColor {
    switch (pembayaran.status) {
      case 'lunas':
        return const Color(0xFF2E7D32);
      case 'telat':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData get _statusIcon {
    switch (pembayaran.status) {
      case 'lunas':
        return Icons.check_circle_rounded;
      case 'telat':
        return Icons.warning_rounded;
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
        title: const Text('Detail Pembayaran'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
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
              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                      child: Icon(_statusIcon, color: _statusColor, size: 48),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pembayaran.bulan} ${pembayaran.tahun}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detail info
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
                      'Informasi Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('ID Pembayaran', '#${pembayaran.idPembayaran.toString().padLeft(4, '0')}'),
                    _buildDetailRow('No. Kios', pembayaran.noKios),
                    _buildDetailRow('Nama Pedagang', pembayaran.namaPedagang),
                    _buildDetailRow('Periode', '${pembayaran.bulan} ${pembayaran.tahun}'),
                    _buildDetailRow('Jumlah', 'Rp ${_formatRupiah(pembayaran.jumlah)}'),
                    _buildDetailRow('Tanggal Bayar',
                        pembayaran.tanggalBayar == '-' ? 'Belum dibayar' : pembayaran.tanggalBayar),
                    _buildDetailRow('Metode Bayar',
                        pembayaran.metodeBayar == '-' ? '-' : pembayaran.metodeBayar),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tombol kembali
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}