import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../models/pembayaran_model.dart';
import '../theme/app_theme.dart';

class BuktiPembayaranScreen extends StatefulWidget {
  final PembayaranModel pembayaran;

  const BuktiPembayaranScreen({super.key, required this.pembayaran});

  @override
  State<BuktiPembayaranScreen> createState() => _BuktiPembayaranScreenState();
}

class _BuktiPembayaranScreenState extends State<BuktiPembayaranScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatTanggal(String tanggal) {
    try {
      final parts = tanggal.split(' ');
      final dateParts = parts[0].split('-');
      final bulan = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final d = int.parse(dateParts[2]);
      final m = int.parse(dateParts[1]);
      final y = dateParts[0];
      final time = parts.length > 1 ? parts[1].substring(0, 5) : '00:00';
      return '$d ${bulan[m]} $y, $time WIB';
    } catch (e) {
      return tanggal;
    }
  }

  Future<void> _simpanBukti() async {
    setState(() => _isSaving = true);
    try {
      // Tangkap gambar dari widget Screenshot
      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (image == null) {
        throw Exception('Gagal mengambil tangkapan layar');
      }

      // Tentukan nama file yang akan muncul di galeri publik
      final fileName = 'bukti_${widget.pembayaran.noTransaksi}_${DateTime.now().millisecondsSinceEpoch}';

      // SIMPAN LANGSUNG KE GALERI PUBLIK MENGGUNAKAN LIBRARY GAL
      await Gal.putImageBytes(image, name: fileName);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran berhasil disimpan ke Galeri!'),
          backgroundColor: AppTheme.accentGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pembayaran;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Bukti Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.download_rounded),
            onPressed: _isSaving ? null : _simpanBukti,
            tooltip: 'Simpan Bukti',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Receipt Card (yang akan di-screenshot) ────
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Header hijau
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                size: 32, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'SIPESEL',
                            style: TextStyle(
                              color: AppTheme.accentYellow,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          const Text(
                            'Sistem Pengelolaan Sewa Kios',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          // Status badge dinamis
                          Builder(builder: (_) {
                            IconData statusIcon;
                            Color statusColor;
                            String statusText;
                            switch (p.status) {
                              case 'berhasil':
                                statusIcon = Icons.check_circle_rounded;
                                statusColor = AppTheme.primaryGreen;
                                statusText = 'Pembayaran Berhasil';
                                break;
                              case 'ditolak':
                                statusIcon = Icons.cancel_rounded;
                                statusColor = AppTheme.errorRed;
                                statusText = 'Pembayaran Ditolak';
                                break;
                              default:
                                statusIcon = Icons.pending_rounded;
                                statusColor = const Color(0xFFE65100);
                                statusText = 'Menunggu Verifikasi';
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      color: statusColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Zigzag separator
                    CustomPaint(
                      size: const Size(double.infinity, 20),
                      painter: _ZigzagPainter(color: AppTheme.bgColor),
                    ),

                    // Body receipt
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nomor transaksi
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'No. Transaksi',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.greyText),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.noTransaksi,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Detail rows
                          _receiptRow('Nama Pedagang', p.namaPedagang.isNotEmpty ? p.namaPedagang : '-'),
                          _receiptRow('Nomor Kios', p.noKios),
                          _receiptRow('Jenis Pajak', p.jenisPajakLabel),
                          _receiptRow('Metode Pembayaran', p.metodeBayar),
                          _receiptRow('Tanggal & Jam', _formatTanggal(p.tanggal)),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              Text(
                                'Rp ${_formatRupiah(p.jumlah)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Footer
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Pasar Wadungasri, Sidoarjo',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.greyText),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Simpan bukti ini sebagai tanda pembayaran.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.greyText),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpanBukti,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.download_rounded),
                label: Text(
                    _isSaving ? 'Menyimpan...' : 'SIMPAN BUKTI PEMBAYARAN'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.primaryGreen),
                label: const Text('KEMBALI',
                    style: TextStyle(color: AppTheme.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.greyText)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
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

// Zigzag painter untuk efek receipt
class _ZigzagPainter extends CustomPainter {
  final Color color;
  _ZigzagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    const zigzagWidth = 12.0;
    const zigzagHeight = 10.0;

    path.moveTo(0, 0);
    double x = 0;
    bool goDown = true;
    while (x < size.width) {
      x += zigzagWidth;
      path.lineTo(x, goDown ? zigzagHeight : 0);
      goDown = !goDown;
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}