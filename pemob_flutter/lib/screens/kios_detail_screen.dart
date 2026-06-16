import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kios_model.dart';
import '../theme/app_theme.dart';

class KiosDetailScreen extends StatelessWidget {
  final KiosModel kios;

  const KiosDetailScreen({super.key, required this.kios});

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  String _formatTanggal(DateTime? dt) {
    if (dt == null) return '-';
    final bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ StreamBuilder — data selalu realtime dari Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kios')
          .where('noKios', isEqualTo: kios.noKios)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // Pakai data terbaru dari stream, fallback ke kios yang dikirim
        KiosModel liveKios = kios;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          liveKios = KiosModel.fromFirestore(snapshot.data!.docs.first);
        }

        final statusColor = liveKios.status == 'aktif'
            ? AppTheme.primaryGreen
            : const Color(0xFFE65100);

        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: AppTheme.primaryGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text(liveKios.zona,
                                style: const TextStyle(fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.accentYellow)),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Kios ${liveKios.noKios}',
                                style: const TextStyle(fontSize: 20,
                                    fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor, width: 1)),
                              child: Text(liveKios.statusLabel,
                                  style: TextStyle(
                                      color: liveKios.status == 'aktif'
                                          ? AppTheme.accentYellow
                                          : Colors.white70,
                                      fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Harga sewa
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          const Text('Harga Sewa / Bulan',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_formatRupiah(liveKios.hargaSewa),
                              style: const TextStyle(color: AppTheme.accentYellow,
                                  fontSize: 28, fontWeight: FontWeight.w900)),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Info kios
                      _buildInfoCard('Informasi Kios', [
                        _buildRow(Icons.storefront_rounded, 'No. Kios', liveKios.noKios),
                        _buildRow(Icons.map_outlined, 'Zona', 'Zona ${liveKios.zona}'),
                        _buildRow(Icons.category_outlined, 'Jenis Jualan',
                            liveKios.jenisJualan.isNotEmpty ? liveKios.jenisJualan : '-'),
                        // ✅ Status dari Firestore realtime
                        _buildRow(Icons.info_outline_rounded, 'Status', liveKios.statusLabel),
                        // ✅ Tanggal bergabung dari tanggalMasuk
                        _buildRow(Icons.calendar_today_outlined, 'Bergabung',
                            _formatTanggal(liveKios.tanggalMasuk)),
                      ]),

                      const SizedBox(height: 16),

                      // Info pedagang — hanya kalau aktif
                      if (liveKios.status == 'aktif') ...[
                        _buildInfoCard('Informasi Pedagang', [
                          _buildRow(Icons.person_outline_rounded, 'Nama',
                              liveKios.namaPedagang.isNotEmpty ? liveKios.namaPedagang : '-'),
                          _buildRow(Icons.phone_outlined, 'Nomor HP',
                              liveKios.nomorHp.isNotEmpty ? liveKios.nomorHp : '-'),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Deskripsi
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                              blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Deskripsi Kios',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen)),
                          const SizedBox(height: 10),
                          Text(liveKios.deskripsi.isNotEmpty
                              ? liveKios.deskripsi
                              : 'Tidak ada deskripsi tersedia.',
                              style: const TextStyle(fontSize: 13,
                                  color: AppTheme.greyText, height: 1.5)),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('KEMBALI'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
      ),
      const Divider(height: 1),
      ...rows,
    ]),
  );

  Widget _buildRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 20, color: AppTheme.primaryGreen),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 13, color: AppTheme.greyText))),
      Text(value, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: AppTheme.darkText)),
    ]),
  );
}