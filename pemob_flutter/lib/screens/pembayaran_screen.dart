import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'riwayat_screen.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final _kiosController = TextEditingController();
  String _selectedJenis = 'harian';
  String _selectedMetode = 'DANA';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _jenisPajak = [
    {
      'key': 'harian',
      'label': 'Harian',
      'icon': Icons.today_rounded,
      'harga': 5000,
      'desc': 'Bayar per hari',
    },
    {
      'key': 'mingguan',
      'label': 'Mingguan',
      'icon': Icons.date_range_rounded,
      'harga': 35000,
      'desc': 'Bayar per minggu',
    },
    {
      'key': 'bulanan',
      'label': 'Bulanan',
      'icon': Icons.calendar_month_rounded,
      'harga': 150000,
      'desc': 'Bayar per bulan',
    },
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
    // Auto-fill nomor kios dari session
    final userKios = SessionUser.currentUser?.noKios ?? '';
    _kiosController.text = userKios;
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

  double get _hargaSekarang =>
      hargaPajak[_selectedJenis] ?? 0;

  String _generateNoTransaksi() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (100000 + (now.millisecond * 997 + now.second * 31) % 900000)
        .toString();
    return 'TRX-$dateStr-$rand';
  }

  void _handleBayar() async {
    final noKios = _kiosController.text.trim();
    if (noKios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor kios tidak boleh kosong'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final noTransaksi = _generateNoTransaksi();
    final now = DateTime.now();
    final tanggal =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final transaksi = PembayaranModel(
      noTransaksi: noTransaksi,
      noKios: noKios,
      jenisPajak: _selectedJenis,
      jumlah: _hargaSekarang,
      status: 'pending',
      tanggal: tanggal,
      metodeBayar: _selectedMetode,
    );

    _showPopupPembayaran(transaksi);
  }

  void _showPopupPembayaran(PembayaranModel transaksi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon status pending
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_rounded,
                  color: Color(0xFFE65100),
                  size: 48,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Menunggu Verifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaksi.noTransaksi,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.greyText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Detail transaksi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _popupRow('Nomor Kios', transaksi.noKios),
                    _popupRow('Jenis Pajak', transaksi.jenisPajakLabel),
                    _popupRow('Metode', transaksi.metodeBayar),
                    _popupRow('Tanggal', transaksi.tanggal),
                    const Divider(height: 16),
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
                          'Rp ${_formatRupiah(transaksi.jumlah)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // tutup popup
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RiwayatScreen()),
                        );
                      },
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Ke Riwayat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // tutup popup
                        setState(() {
                          _selectedJenis = 'harian';
                          _selectedMetode = 'DANA';
                          // noKios tetap (auto-fill dari session)
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Bayar Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.greyText)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Pembayaran Pajak'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pilih Jenis Pajak ──────────────────────────
              const Text(
                'Pilih Jenis Pajak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _jenisPajak.map((j) {
                  final isSelected = _selectedJenis == j['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedJenis = j['key']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: j != _jenisPajak.last ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color:
                              AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              j['icon'] as IconData,
                              color:
                              isSelected ? Colors.white : AppTheme.greyText,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              j['label'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${_formatRupiah((j['harga'] as int).toDouble())}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Form Card ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
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
                    const Text(
                      'Detail Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Nomor Kios
                    TextField(
                      controller: _kiosController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kios',
                        prefixIcon: Icon(Icons.storefront_rounded),
                        hintText: 'Contoh: k-321',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pilih Metode Pembayaran
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.greyText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _metodeList.map((m) {
                        final isSelected = _selectedMetode == m['key'];
                        final color = m['color'] as Color;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedMetode = m['key']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                isSelected ? color : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m['icon'] as IconData,
                                  color: isSelected ? color : AppTheme.greyText,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m['key'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color:
                                    isSelected ? color : AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Ringkasan Pembayaran ───────────────────────
              Container(
                padding: const EdgeInsets.all(18),
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
                    const Text(
                      'Ringkasan Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ringkasanRow(
                      'Jenis Pajak',
                      _jenisPajak.firstWhere(
                              (j) => j['key'] == _selectedJenis)['label']
                      as String,
                    ),
                    _ringkasanRow(
                      'Nomor Kios',
                      _kiosController.text.trim().isEmpty
                          ? '-'
                          : _kiosController.text.trim(),
                    ),
                    _ringkasanRow('Metode', _selectedMetode),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Bayar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'Rp ${_formatRupiah(_hargaSekarang)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Tombol Bayar ──────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleBayar,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.payment_rounded),
                  label: Text(
                    _isLoading ? 'Memproses...' : 'BAYAR SEKARANG',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
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

  Widget _ringkasanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.greyText)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText)),
        ],
      ),
    );
  }
}