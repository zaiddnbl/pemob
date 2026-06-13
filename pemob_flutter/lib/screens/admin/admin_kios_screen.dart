import 'package:flutter/material.dart';
import '../../models/kios_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminKiosScreen extends StatefulWidget {
  const AdminKiosScreen({super.key});

  @override
  State<AdminKiosScreen> createState() => _AdminKiosScreenState();
}

class _AdminKiosScreenState extends State<AdminKiosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'semua';

  static const Color _navyDark = Color(0xFF1A3C34);
  static const Color _bgGrey = Color(0xFFF4F6F5);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<KiosModel> _applyFilter(List<KiosModel> all) {
    return all.where((k) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty ||
          k.noKios.toLowerCase().contains(q) ||
          k.namaPedagang.toLowerCase().contains(q) ||
          k.lokasiKios.toLowerCase().contains(q);
      final matchStatus =
          _filterStatus == 'semua' || k.status == _filterStatus;
      return matchQ && matchStatus;
    }).toList();
  }

  void _showFormKios({KiosModel? kios}) {
    final noKiosCtrl = TextEditingController(text: kios?.noKios ?? '');
    final lokasiCtrl =
    TextEditingController(text: kios?.lokasiKios ?? '');
    final ukuranCtrl =
    TextEditingController(text: kios?.ukuranKios ?? '3x3m');
    final hargaCtrl = TextEditingController(
        text: kios?.hargaSewa.toInt().toString() ?? '');
    final zonaCtrl = TextEditingController(text: kios?.zona ?? '');
    String selectedStatus = kios?.status ?? 'kosong';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  kios == null
                      ? 'Tambah Kios Baru'
                      : 'Edit Kios ${kios.noKios}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _navyDark),
                ),
                const SizedBox(height: 20),
                _buildInput(noKiosCtrl, 'Nomor Kios (mis: A-01)',
                    Icons.tag_rounded,
                    enabled: kios == null),
                const SizedBox(height: 10),
                _buildInput(zonaCtrl, 'Zona (mis: A)', Icons.map_outlined),
                const SizedBox(height: 10),
                _buildInput(lokasiCtrl, 'Lokasi Kios',
                    Icons.location_on_outlined),
                const SizedBox(height: 10),
                _buildInput(ukuranCtrl, 'Ukuran (mis: 3x3m)',
                    Icons.square_foot_rounded),
                const SizedBox(height: 10),
                _buildInput(hargaCtrl, 'Harga Retribusi/Bulan (Rp)',
                    Icons.payments_outlined,
                    type: TextInputType.number),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info_outline,
                          color: _navyDark, size: 20),
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'kosong', child: Text('Kosong')),
                      DropdownMenuItem(
                          value: 'aktif', child: Text('Aktif')),
                    ],
                    onChanged: (v) =>
                        setModalState(() => selectedStatus = v!),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newKios = KiosModel(
                        id: kios?.id ?? '',
                        noKios: noKiosCtrl.text.trim(),
                        namaPedagang: kios?.namaPedagang ?? '',
                        jenisJualan: kios?.jenisJualan ?? '-',
                        hargaSewa:
                        double.tryParse(hargaCtrl.text.trim()) ??
                            0,
                        status: selectedStatus,
                        zona: zonaCtrl.text.trim(),
                        lokasiKios: lokasiCtrl.text.trim(),
                        ukuranKios: ukuranCtrl.text.trim(),
                      );
                      if (kios == null) {
                        await FirestoreService.tambahKios(newKios);
                      } else {
                        await FirestoreService.updateKios(
                            kios.id, newKios);
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(kios == null
                              ? 'Kios berhasil ditambahkan ✅'
                              : 'Kios berhasil diupdate ✅'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyDark,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                        kios == null ? 'TAMBAH KIOS' : 'SIMPAN',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
        bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? _bgGrey : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _navyDark, size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manajemen Kios',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _navyDark)),
                        Text('Data kios Pasar Wadungasri',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyText)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showFormKios(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Tambah',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Cari kios, pedagang, lokasi...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppTheme.greyText),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppTheme.greyText, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 13),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                Row(
                  children: [
                    _chip('semua', 'Semua'),
                    const SizedBox(width: 8),
                    _chip('aktif', 'Aktif'),
                    const SizedBox(width: 8),
                    _chip('kosong', 'Kosong'),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<KiosModel>>(
              stream: FirestoreService.streamKios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _navyDark));
                }

                final allKios = snapshot.data ?? [];
                final filtered = _applyFilter(allKios);

                // Summary di atas list
                final aktif = allKios
                    .where((k) => k.status == 'aktif')
                    .length;
                final kosong = allKios
                    .where((k) => k.status == 'kosong')
                    .length;

                return Column(
                  children: [
                    // Summary bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          _summaryBadge(
                              'Total', '${allKios.length}', _navyDark),
                          const SizedBox(width: 8),
                          _summaryBadge('Aktif', '$aktif',
                              AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          _summaryBadge('Kosong', '$kosong',
                              const Color(0xFFD97706)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                          child: Text('Tidak ada kios',
                              style: TextStyle(
                                  color: AppTheme.greyText)))
                          : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final k = filtered[index];
                          final isAktif = k.status == 'aktif';
                          final statusColor = isAktif
                              ? AppTheme.primaryGreen
                              : const Color(0xFFD97706);

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 8,
                                    offset:
                                    const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Top accent bar
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius:
                                    const BorderRadius
                                        .vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Zona badge
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration:
                                        BoxDecoration(
                                          color: _navyDark,
                                          borderRadius:
                                          BorderRadius
                                              .circular(12),
                                        ),
                                        alignment:
                                        Alignment.center,
                                        child: Text(
                                          k.zona,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight:
                                            FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  k.noKios,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                    FontWeight
                                                        .w800,
                                                    color:
                                                    _navyDark,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal:
                                                      8,
                                                      vertical:
                                                      2),
                                                  decoration:
                                                  BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(
                                                        0.1),
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        6),
                                                  ),
                                                  child: Text(
                                                    k.statusLabel,
                                                    style: TextStyle(
                                                        fontSize:
                                                        9,
                                                        fontWeight:
                                                        FontWeight
                                                            .w700,
                                                        color:
                                                        statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              k.lokasiKios
                                                  .isNotEmpty
                                                  ? k.lokasiKios
                                                  : '-',
                                              style:
                                              const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme
                                                    .greyText,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  k.ukuranKios,
                                                  style:
                                                  const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .greyText,
                                                  ),
                                                ),
                                                const Text(
                                                    ' • ',
                                                    style: TextStyle(
                                                        color:
                                                        AppTheme
                                                            .greyText)),
                                                Text(
                                                  _formatRupiah(
                                                      k.hargaSewa),
                                                  style:
                                                  const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                    FontWeight
                                                        .w700,
                                                    color:
                                                    _navyDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isAktif &&
                                                k.namaPedagang
                                                    .isNotEmpty)
                                              Text(
                                                k.namaPedagang,
                                                style:
                                                const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme
                                                      .primaryGreen,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color:
                                            AppTheme.greyText),
                                        shape:
                                        RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius
                                                .circular(
                                                12)),
                                        onSelected: (v) {
                                          if (v == 'edit')
                                            _showFormKios(
                                                kios: k);
                                          else if (v == 'hapus')
                                            _hapusKios(k);
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: const [
                                                Icon(
                                                    Icons
                                                        .edit_outlined,
                                                    size: 16,
                                                    color:
                                                    _navyDark),
                                                SizedBox(
                                                    width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'hapus',
                                            child: Row(
                                              children: const [
                                                Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 16,
                                                    color:
                                                    Colors.red),
                                                SizedBox(
                                                    width: 8),
                                                Text('Hapus',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _navyDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.greyText),
        ),
      ),
    );
  }

  Widget _summaryBadge(String label, String value, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _hapusKios(KiosModel kios) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kios'),
        content: Text('Hapus kios ${kios.noKios}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService.deleteKios(kios.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Kios dihapus'),
                    backgroundColor: Colors.red),
              );
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}