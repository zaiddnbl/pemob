import 'package:flutter/material.dart';
import '../models/pembayaran_model.dart';
import '../models/kios_model.dart';
import '../theme/app_theme.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedKios;
  String? _selectedBulan;
  String _selectedMetode = 'Transfer';
  bool _isLoading = false;

  final List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _metodeList = ['Transfer', 'Tunai', 'QRIS', 'Virtual Account'];

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  KiosModel? get _selectedKiosData {
    if (_selectedKios == null) return null;
    try {
      return dummyKios.firstWhere((k) => k.noKios == _selectedKios);
    } catch (_) {
      return null;
    }
  }

  void _handleBayar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pembayaran Kios $_selectedKios bulan $_selectedBulan berhasil! ✅',
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
      ),
    );

    // Reset form
    setState(() {
      _selectedKios = null;
      _selectedBulan = null;
      _selectedMetode = 'Transfer';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Pembayaran Sewa'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lakukan pembayaran sewa kios untuk periode yang dipilih.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form card
                Container(
                  padding: const EdgeInsets.all(20),
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
                        'Form Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pilih Kios
                      DropdownButtonFormField<String>(
                        value: _selectedKios,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Kios',
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                        items: dummyKios
                            .where((k) => k.status == 'aktif')
                            .map((k) => DropdownMenuItem(
                          value: k.noKios,
                          child: Text('Kios ${k.noKios} — ${k.namaPedagang}'),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedKios = v),
                        validator: (v) => v == null ? 'Pilih kios terlebih dahulu' : null,
                      ),

                      const SizedBox(height: 14),

                      // Pilih Bulan
                      DropdownButtonFormField<String>(
                        value: _selectedBulan,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Bulan',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        items: _bulanList
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBulan = v),
                        validator: (v) => v == null ? 'Pilih bulan pembayaran' : null,
                      ),

                      const SizedBox(height: 14),

                      // Metode Bayar
                      DropdownButtonFormField<String>(
                        value: _selectedMetode,
                        decoration: const InputDecoration(
                          labelText: 'Metode Pembayaran',
                          prefixIcon: Icon(Icons.payment_rounded),
                        ),
                        items: _metodeList
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMetode = v!),
                      ),

                      // Preview jumlah
                      if (_selectedKiosData != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              Text(
                                'Rp ${_formatRupiah(_selectedKiosData!.hargaSewa)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

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
                          label: Text(_isLoading ? 'Memproses...' : 'BAYAR SEKARANG'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tagihan pending
                const Text(
                  'Tagihan Tertunda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                ...dummyPembayaran
                    .where((p) => p.status != 'lunas')
                    .map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p.status == 'telat'
                          ? AppTheme.errorRed.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.status == 'telat'
                            ? Icons.warning_rounded
                            : Icons.pending_rounded,
                        color: p.status == 'telat'
                            ? AppTheme.errorRed
                            : const Color(0xFFE65100),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kios ${p.noKios} — ${p.bulan} ${p.tahun}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.darkText,
                              ),
                            ),
                            Text(
                              p.namaPedagang,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.greyText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${_formatRupiah(p.jumlah)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}