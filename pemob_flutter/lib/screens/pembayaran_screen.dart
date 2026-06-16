import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kiosController = TextEditingController();

  String _selectedJenis = 'harian';
  String _selectedMetode = 'DANA';
  bool _isLoading = false;
  bool _showQRIS = false;
  String? _qrisData;

  double _hargaHarian = 5000;
  double _hargaMingguan = 35000;
  double _hargaBulanan = 150000;

  List<Map<String, dynamic>> get _jenisPajak => [
    {'key': 'harian', 'label': 'Harian', 'icon': Icons.today_rounded,
      'harga': _hargaHarian, 'durasi': '+1 hari'},
    {'key': 'mingguan', 'label': 'Mingguan', 'icon': Icons.date_range_rounded,
      'harga': _hargaMingguan, 'durasi': '+7 hari'},
    {'key': 'bulanan', 'label': 'Bulanan', 'icon': Icons.calendar_month_rounded,
      'harga': _hargaBulanan, 'durasi': '+30 hari'},
  ];

  final List<Map<String, dynamic>> _metodeList = [
    {'key': 'DANA', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF0288D1)},
    {'key': 'Transfer', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF2E7D32)},
    {'key': 'QRIS', 'icon': Icons.qr_code_rounded, 'color': const Color(0xFF6A1B9A)},
    {'key': 'Virtual Account', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFFE65100)},
  ];

  @override
  void initState() {
    super.initState();
    _kiosController.text = SessionUser.currentUser?.noKios ?? '';
    _loadHarga();
  }

  Future<void> _loadHarga() async {
    final tagihan = await FirestoreService.getTagihan();
    if (tagihan != null && mounted) {
      setState(() {
        _hargaHarian = tagihan.hargaHarian;
        _hargaMingguan = tagihan.hargaMingguan;
        _hargaBulanan = tagihan.hargaBulanan;
      });
      tagihan.applyToGlobal();
    }
  }

  @override
  void dispose() {
    _kiosController.dispose();
    super.dispose();
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

  double get _hargaSekarang {
    switch (_selectedJenis) {
      case 'harian':   return _hargaHarian;
      case 'mingguan': return _hargaMingguan;
      case 'bulanan':  return _hargaBulanan;
      default:         return _hargaHarian;
    }
  }

  String _generateNoTransaksi() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand =
    (100000 + (now.millisecond * 997 + now.second * 31) % 900000).toString();
    return 'TRX-$dateStr-$rand';
  }

  void _onMetodeChanged(String metode) {
    setState(() {
      _selectedMetode = metode;
      _showQRIS = false;
      _qrisData = null;
    });
  }

  void _generateQRIS() {
    final noTransaksi = _generateNoTransaksi();
    final noKios = _kiosController.text.trim();
    setState(() {
      _qrisData = 'SIPESEL|$noTransaksi|$noKios|$_selectedJenis|${_hargaSekarang.toInt()}';
      _showQRIS = true;
    });
  }

  void _handleBayar() async {
    if (!_formKey.currentState!.validate()) return;

    // Kalau QRIS belum di-generate, generate dulu
    if (_selectedMetode == 'QRIS' && !_showQRIS) {
      _generateQRIS();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan QRIS di bawah, lalu tekan Bayar lagi'),
          backgroundColor: Color(0xFF6A1B9A),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final tanggal =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final transaksi = PembayaranModel(
      noTransaksi: _generateNoTransaksi(),
      noKios: _kiosController.text.trim(),
      jenisPajak: _selectedJenis,
      jumlah: _hargaSekarang,
      status: 'pending',
      tanggal: tanggal,
      metodeBayar: _selectedMetode,
      namaPedagang: SessionUser.currentUser?.nama ?? '',
    );

    final success = await FirestoreService.tambahPembayaran(transaksi);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuksesDialog(transaksi);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan pembayaran. Coba lagi.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showSuksesDialog(PembayaranModel transaksi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuksesDialog(
        transaksi: transaksi,
        onSelesai: () {
          Navigator.pop(context);
          setState(() {
            _selectedJenis = 'harian';
            _selectedMetode = 'DANA';
            _showQRIS = false;
            _qrisData = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Pembayaran Retribusi'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Jenis Retribusi ───────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis Retribusi',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                    const SizedBox(height: 14),
                    Row(
                      children: _jenisPajak.map((j) {
                        final isSelected = _selectedJenis == j['key'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedJenis = j['key'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : Colors.grey.shade200),
                              ),
                              child: Column(children: [
                                Icon(j['icon'] as IconData,
                                    color: isSelected ? Colors.white : AppTheme.greyText,
                                    size: 24),
                                const SizedBox(height: 6),
                                Text(j['label'] as String,
                                    style: TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : AppTheme.darkText)),
                                Text('Rp ${_formatRupiah(j['harga'] as double)}',
                                    style: TextStyle(fontSize: 10,
                                        color: isSelected ? Colors.white70 : AppTheme.greyText)),
                                Text(j['durasi'] as String,
                                    style: TextStyle(fontSize: 9,
                                        color: isSelected ? AppTheme.accentYellow : AppTheme.greyText)),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Nomor Kios ────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Kios',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kiosController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kios',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty || v.trim() == '-')
                          return 'Nomor kios tidak boleh kosong';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Metode Pembayaran ─────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Metode Pembayaran',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3.2,
                      ),
                      itemCount: _metodeList.length,
                      itemBuilder: (context, index) {
                        final m = _metodeList[index];
                        final isSelected = _selectedMetode == m['key'];
                        final color = m['color'] as Color;
                        return GestureDetector(
                          onTap: () => _onMetodeChanged(m['key'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected ? color : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(m['icon'] as IconData,
                                    color: isSelected ? color : AppTheme.greyText,
                                    size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(m['key'] as String,
                                      style: TextStyle(fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? color : AppTheme.greyText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // ── QRIS section ──────────────────────
                    if (_selectedMetode == 'QRIS') ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      if (_showQRIS && _qrisData != null)
                        Center(
                          child: Column(children: [
                            const Text('Scan QRIS untuk Membayar',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkText)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF6A1B9A), width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: _qrisData!,
                                version: QrVersions.auto,
                                size: 180,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('SIPESEL • Pasar Wadungasri',
                                style: TextStyle(fontSize: 11, color: AppTheme.greyText)),
                            const SizedBox(height: 4),
                            Text('Total: Rp ${_formatRupiah(_hargaSekarang)}',
                                style: const TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6A1B9A))),
                          ]),
                        )
                      else
                        Center(
                          child: Column(children: [
                            const Icon(Icons.qr_code_rounded,
                                size: 48, color: AppTheme.greyText),
                            const SizedBox(height: 8),
                            const Text(
                              'Tekan "Generate QRIS" untuk\nmemunculkan kode QR',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                            ),
                          ]),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Ringkasan ─────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Pembayaran',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                    const SizedBox(height: 14),
                    _ringkasanRow('Jenis Retribusi',
                        _jenisPajak.firstWhere(
                                (j) => j['key'] == _selectedJenis)['label'] as String),
                    _ringkasanRow('Nomor Kios',
                        _kiosController.text.trim().isEmpty
                            ? '-' : _kiosController.text.trim()),
                    _ringkasanRow('Metode', _selectedMetode),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                        Text('Rp ${_formatRupiah(_hargaSekarang)}',
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGreen)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleBayar,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Icon(_selectedMetode == 'QRIS' && !_showQRIS
                      ? Icons.qr_code_rounded
                      : Icons.payment_rounded),
                  label: Text(
                    _isLoading
                        ? 'Menyimpan...'
                        : _selectedMetode == 'QRIS' && !_showQRIS
                        ? 'GENERATE QRIS'
                        : 'BAYAR SEKARANG',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _ringkasanRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: AppTheme.darkText)),
      ],
    ),
  );
}

// ── Popup sukses ─────────────────────────────────────────────────
class _SuksesDialog extends StatelessWidget {
  final PembayaranModel transaksi;
  final VoidCallback onSelesai;

  const _SuksesDialog({required this.transaksi, required this.onSelesai});

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
    final p = transaksi;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.pending_rounded,
                  color: Color(0xFFE65100), size: 52),
            ),
            const SizedBox(height: 16),
            const Text('Pembayaran Diajukan!',
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: AppTheme.darkText)),
            const SizedBox(height: 4),
            const Text('Menunggu verifikasi admin',
                style: TextStyle(fontSize: 13, color: AppTheme.greyText)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _row('No. Transaksi', p.noTransaksi),
                _row('Jenis Pajak', p.jenisPajakLabel),
                _row('Nomor Kios', p.noKios),
                _row('Metode', p.metodeBayar),
                _row('Tanggal', p.tanggal.length >= 10
                    ? p.tanggal.substring(0, 10) : p.tanggal),
                _row('Jam', p.tanggal.length >= 16
                    ? p.tanggal.substring(11, 16) : '-'),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bayar',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                    Text('Rp ${_formatRupiah(p.jumlah)}',
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen)),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSelesai,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('SELESAI'),
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: AppTheme.darkText))),
      ],
    ),
  );
}