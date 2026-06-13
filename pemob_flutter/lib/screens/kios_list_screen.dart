import 'package:flutter/material.dart';
import '../models/kios_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kios_card.dart';
import 'kios_detail_screen.dart';

class KiosListScreen extends StatefulWidget {
  const KiosListScreen({super.key});

  @override
  State<KiosListScreen> createState() => _KiosListScreenState();
}

class _KiosListScreenState extends State<KiosListScreen> {
  final _searchController = TextEditingController();
  String _filterZona = 'Semua';
  String _filterStatus = 'Semua';

  final List<String> _zonaList = ['Semua', 'A', 'B', 'C', 'D', 'E'];
  final List<String> _statusList = ['Semua', 'aktif', 'kosong'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KiosModel> _applyFilter(List<KiosModel> all) {
    final q = _searchController.text.toLowerCase();
    return all.where((k) {
      final matchSearch = q.isEmpty ||
          k.noKios.toLowerCase().contains(q) ||
          k.namaPedagang.toLowerCase().contains(q) ||
          k.jenisJualan.toLowerCase().contains(q);
      final matchZona = _filterZona == 'Semua' || k.zona == _filterZona;
      final matchStatus =
          _filterStatus == 'Semua' || k.status == _filterStatus;
      return matchSearch && matchZona && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Daftar Kios Pasar'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Search & Filter ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari kios, pedagang, atau jenis jualan...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Zona
                Row(
                  children: [
                    const Text(
                      'Zona: ',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.greyText),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _zonaList.map((z) {
                            final isSelected = _filterZona == z;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _filterZona = z),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  z,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.greyText,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Filter Status
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.greyText),
                    ),
                    ..._statusList.map((s) {
                      final isSelected = _filterStatus == s;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filterStatus = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentGreen
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentGreen
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            s == 'aktif'
                                ? 'Aktif'
                                : s == 'kosong'
                                    ? 'Kosong'
                                    : s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.greyText,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── List Kios dari Firestore ─────────────────────
          Expanded(
            child: StreamBuilder<List<KiosModel>>(
              stream: FirestoreService.streamKios(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: AppTheme.primaryGreen),
                        SizedBox(height: 14),
                        Text(
                          'Memuat data kios...',
                          style:
                              TextStyle(color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 52, color: AppTheme.errorRed),
                        const SizedBox(height: 12),
                        const Text(
                          'Gagal memuat data',
                          style: TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                              color: AppTheme.greyText, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allKios = snapshot.data ?? [];
                final filtered = _applyFilter(allKios);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 52, color: AppTheme.greyText),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada kios ditemukan',
                          style: TextStyle(color: AppTheme.greyText),
                        ),
                        if (_searchController.text.isNotEmpty ||
                            _filterZona != 'Semua' ||
                            _filterStatus != 'Semua')
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _filterZona = 'Semua';
                                _filterStatus = 'Semua';
                              });
                            },
                            child: const Text('Reset Filter'),
                          ),
                      ],
                    ),
                  );
                }

                // Tampilkan menggunakan GridView.builder
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Info jumlah
                      Row(
                        children: [
                          Text(
                            'Menampilkan ${filtered.length} dari ${allKios.length} kios',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.greyText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final kios = filtered[index];
                            return KiosCard(
                              kios: kios,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        KiosDetailScreen(kios: kios),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
