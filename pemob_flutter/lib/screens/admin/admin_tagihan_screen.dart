import 'package:flutter/material.dart';
import '../../models/tagihan_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminTagihanScreen extends StatefulWidget {
  const AdminTagihanScreen({super.key});

  @override
  State<AdminTagihanScreen> createState() => _AdminTagihanScreenState();
}

class _AdminTagihanScreenState extends State<AdminTagihanScreen> {
  TagihanModel? _tagihan;
  bool _isLoading = true;
  bool _isSaving = false;

  final _harianCtrl = TextEditingController();
  final _mingguanCtrl = TextEditingController();
  final _bulananCtrl = TextEditingController();

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void initState() {
    super.initState();
    _loadTagihan();
  }

  @override
  void dispose() {
    _harianCtrl.dispose();
    _mingguanCtrl.dispose();
    _bulananCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTagihan() async {
    setState(() => _isLoading = true);
    final tagihan = await FirestoreService.getTagihan();
    if (mounted) {
      setState(() {
        _tagihan = tagihan;
        _harianCtrl.text =
            tagihan?.hargaHarian.toInt().toString() ?? '5000';
        _mingguanCtrl.text =
            tagihan?.hargaMingguan.toInt().toString() ?? '35000';
        _bulananCtrl.text =
            tagihan?.hargaBulanan.toInt().toString() ?? '150000';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTagihan() async {
    if (_tagihan == null) return;
    setState(() => _isSaving = true);

    final harian =
        double.tryParse(_harianCtrl.text.trim()) ?? 0;
    final mingguan =
        double.tryParse(_mingguanCtrl.text.trim()) ?? 0;
    final bulanan =
        double.tryParse(_bulananCtrl.text.trim()) ?? 0;

    if (harian <= 0 || mingguan <= 0 || bulanan <= 0) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua harga harus lebih dari 0'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final success = await FirestoreService.updateTagihan(
      id: _tagihan!.id,
      hargaHarian: harian,
      hargaMingguan: mingguan,
      hargaBulanan: bulanan,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Harga retribusi berhasil diupdate ✅'
            : 'Gagal mengupdate harga'),
        backgroundColor:
            success ? AppTheme.accentGreen : AppTheme.errorRed,
      ),
    );

    if (success) _loadTagihan();
  }

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Manajemen Tagihan',
            style: TextStyle(
                color: _navyDark,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: _navyDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _navyDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.accentYellow, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Perubahan harga akan langsung berlaku di halaman pembayaran semua pedagang.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Harga saat ini
                  const Text('Harga Retribusi Saat Ini',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _navyDark)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _currentCard(
                          Icons.today_rounded,
                          'Harian',
                          _formatRupiah(
                              _tagihan?.hargaHarian ?? 5000),
                          const Color(0xFF1B6B3A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _currentCard(
                          Icons.date_range_rounded,
                          'Mingguan',
                          _formatRupiah(
                              _tagihan?.hargaMingguan ?? 35000),
                          const Color(0xFF1A3C34),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _currentCard(
                          Icons.calendar_month_rounded,
                          'Bulanan',
                          _formatRupiah(
                              _tagihan?.hargaBulanan ?? 150000),
                          const Color(0xFF0F4C35),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Form edit
                  const Text('Edit Harga Retribusi',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _navyDark)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputHarga(
                          controller: _harianCtrl,
                          label: 'Harga Harian',
                          icon: Icons.today_rounded,
                          color: const Color(0xFF1B6B3A),
                        ),
                        const SizedBox(height: 14),
                        _inputHarga(
                          controller: _mingguanCtrl,
                          label: 'Harga Mingguan',
                          icon: Icons.date_range_rounded,
                          color: _navyDark,
                        ),
                        const SizedBox(height: 14),
                        _inputHarga(
                          controller: _bulananCtrl,
                          label: 'Harga Bulanan',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFF0F4C35),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSaving ? null : _saveTagihan,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.save_rounded,
                                    size: 18, color: Colors.white),
                            label: Text(
                                _isSaving
                                    ? 'Menyimpan...'
                                    : 'SIMPAN PERUBAHAN',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navyDark,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Catatan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.accentYellow
                              .withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                color: AppTheme.accentYellow,
                                size: 18),
                            SizedBox(width: 6),
                            Text('Catatan',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _navyDark)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Harian: pedagang membayar per 1 hari\n'
                          '• Mingguan: pedagang membayar per 7 hari\n'
                          '• Bulanan: pedagang membayar per 30 hari\n'
                          '• Jatuh tempo pedagang otomatis terupdate setelah pembayaran',
                          style: TextStyle(
                              fontSize: 12,
                              color: _navyDark,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _currentCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.accentYellow,
                  fontSize: 13,
                  fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _inputHarga({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color, size: 20),
          prefixText: 'Rp ',
          prefixStyle: TextStyle(
              color: color, fontWeight: FontWeight.w700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}