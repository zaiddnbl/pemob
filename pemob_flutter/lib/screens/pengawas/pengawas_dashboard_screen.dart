import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../models/pembayaran_model.dart';
import '../../theme/app_theme.dart';

class PengawasDashboardScreen extends StatefulWidget {
  const PengawasDashboardScreen({super.key});

  @override
  State<PengawasDashboardScreen> createState() =>
      _PengawasDashboardScreenState();
}

class _PengawasDashboardScreenState extends State<PengawasDashboardScreen> {
  String _filter = 'semua';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const Color _teal = Color(0xFF1A3C34);
  static const Color _bg = Color(0xFFF5F7FA);

  // ── VARIABEL STREAM BARU (TIDAK DI-RESET SAAT SETSTATE) ──
  late Stream<QuerySnapshot> _usersStream;
  late Stream<QuerySnapshot> _kiosStream;
  late Stream<QuerySnapshot> _pembayaranStream;

  @override
  void initState() {
    super.initState();

    // ── INISIALISASI STREAM HANYA SEKALI DI SINI ──
    _usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'pedagang')
        .snapshots();

    _kiosStream = FirebaseFirestore.instance
        .collection('kios')
        .where('status', isEqualTo: 'aktif')
        .snapshots();

    _pembayaranStream = FirebaseFirestore.instance
        .collection('pembayaran')
        .snapshots();

    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Kalkulasi jatuh tempo akumulatif ─────────────────────────
  DateTime? _hitungJatuhTempo(List<PembayaranModel> payments) {
    if (payments.isEmpty) return null;
    final berhasil = payments.where((p) => p.status == 'berhasil').toList();
    if (berhasil.isEmpty) return null;
    berhasil.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    DateTime? earliest;
    try {
      final parts = berhasil.first.tanggal.split(' ')[0].split('-');
      earliest = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) { return null; }
    int totalHari = 0;
    for (final p in berhasil) {
      switch (p.jenisPajak.toLowerCase()) {
        case 'harian':   totalHari += 1;  break;
        case 'mingguan': totalHari += 7;  break;
        case 'bulanan':  totalHari += 30; break;
      }
    }
    return earliest.add(Duration(days: totalHari));
  }

  String _formatRupiah(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toInt()}';
  }

  String _sisaText(DateTime? dt) {
    if (dt == null) return 'Belum bayar';
    final sisa = dt.difference(DateTime.now()).inDays;
    if (sisa < 0) return 'Nunggak ${-sisa} hari';
    if (sisa == 0) return 'Jatuh tempo hari ini!';
    return 'Sisa $sisa hari';
  }

  Color _sisaColor(DateTime? dt) {
    if (dt == null) return const Color(0xFFD97706);
    final sisa = dt.difference(DateTime.now()).inDays;
    if (sisa < 0) return AppTheme.errorRed;
    if (sisa <= 3) return const Color(0xFFD97706);
    return AppTheme.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.currentUser;
    final nama = user?.nama ?? 'User';

    // ── MENGGUNAKAN VARIABEL STREAM, BUKAN MEMBUAT BARU ──
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapUsers) {
          return StreamBuilder<QuerySnapshot>(
            stream: _kiosStream,
            builder: (context, snapKios) {
              return StreamBuilder<QuerySnapshot>(
                stream: _pembayaranStream,
                builder: (context, snapPembayaran) {

                  // Loading
                  if (snapUsers.connectionState == ConnectionState.waiting ||
                      snapPembayaran.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _teal));
                  }

                  // Data
                  final totalPedagang = snapUsers.data?.docs.length ?? 0;
                  final totalKiosAktif = snapKios.data?.docs.length ?? 0;

                  final semuaPembayaran = (snapPembayaran.data?.docs ?? [])
                      .map((d) => PembayaranModel.fromFirestore(d))
                      .toList();

                  // Total retribusi bulan ini
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  double totalRetribusi = 0;
                  for (final p in semuaPembayaran) {
                    if (p.status != 'berhasil') continue;
                    try {
                      final parts = p.tanggal.split(' ')[0].split('-');
                      final tgl = DateTime(int.parse(parts[0]),
                          int.parse(parts[1]), int.parse(parts[2]));
                      if (!tgl.isBefore(startOfMonth)) totalRetribusi += p.jumlah;
                    } catch (_) {}
                  }

                  // Build list pedagang dengan jatuh tempo
                  final pedagangDocs = snapUsers.data?.docs ?? [];
                  final pedagangList = pedagangDocs.map((doc) {
                    final u = UserModel.fromFirestore(doc);
                    final pays = semuaPembayaran
                        .where((p) => p.noKios == u.noKios).toList();
                    return _PedagangItem(
                        user: u, jatuhTempo: _hitungJatuhTempo(pays));
                  }).toList();

                  // Apply filter + search
                  List<_PedagangItem> filtered = pedagangList;
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((p) =>
                    p.user.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.user.noKios.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();
                  }
                  switch (_filter) {
                    case 'belum':
                      filtered = filtered.where((p) =>
                      p.jatuhTempo != null &&
                          p.jatuhTempo!.isAfter(DateTime.now())).toList();
                      break;
                    case 'jatuh':
                      filtered = filtered.where((p) =>
                      p.jatuhTempo == null ||
                          p.jatuhTempo!.isBefore(DateTime.now())).toList();
                      break;
                  }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── HEADER foto pasar ──────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 210,
                          child: Stack(children: [
                            Positioned.fill(
                              child: Image.asset('assets/images/foto_pasar.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: _teal)),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.72),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Image.asset('assets/images/logo_biru.png',
                                          height: 26,
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.storefront_rounded,
                                              color: Colors.white, size: 26)),
                                      const SizedBox(width: 8),
                                      const Text('SIPESEL',
                                          style: TextStyle(fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white, letterSpacing: 1.5,
                                              shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                                    ]),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('HALO $nama 👋',
                                          style: const TextStyle(fontSize: 26,
                                              fontWeight: FontWeight.w900, color: Colors.white,
                                              shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                                      const SizedBox(height: 4),
                                      const Text('Dashboard Pengawas • Pasar Wadungasri',
                                          style: TextStyle(fontSize: 12, color: Colors.white70,
                                              shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),

                        // ── STAT CARDS ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(children: [
                            _statCard('Total\nPedagang', '$totalPedagang',
                                Icons.people_rounded, _teal),
                            const SizedBox(width: 10),
                            _statCard('Total Kios\nAktif', '$totalKiosAktif',
                                Icons.storefront_rounded, const Color(0xFF1565C0)),
                            const SizedBox(width: 10),
                            _statCard('Total\nRetribusi', _formatRupiah(totalRetribusi),
                                Icons.payments_rounded, const Color(0xFF6A1B9A)),
                          ]),
                        ),

                        const SizedBox(height: 20),

                        // ── DAFTAR PEDAGANG ────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Text('daftar pedagang',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        ),

                        const SizedBox(height: 10),

                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Cari nama pedagang...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.greyText),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppTheme.greyText, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18, color: AppTheme.greyText),
                                  onPressed: () => _searchCtrl.clear())
                                  : null,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _teal, width: 1.5)),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(children: [
                            _filterChip('semua', 'semua'),
                            const SizedBox(width: 8),
                            _filterChip('belum', 'belum jatuh tempo'),
                            const SizedBox(width: 8),
                            _filterChip('jatuh', 'Jatuh tempo'),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        // Carousel pedagang
                        filtered.isEmpty
                            ? SizedBox(
                          height: 160,
                          child: Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  color: Colors.grey.shade300, size: 44),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '"$_searchQuery" tidak ditemukan'
                                    : 'Tidak ada pedagang',
                                style: const TextStyle(
                                    color: AppTheme.greyText, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )),
                        )
                            : SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final sisaColor = _sisaColor(item.jatuhTempo);
                              final sisa = _sisaText(item.jatuhTempo);
                              final initial = item.user.nama.isNotEmpty
                                  ? item.user.nama[0].toUpperCase() : 'P';

                              return GestureDetector(
                                onTap: () => _showDetailPedagang(context, item),
                                child: Container(
                                  width: 150,
                                  margin: EdgeInsets.only(
                                      right: i == filtered.length - 1 ? 0 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                        child: _PhotoWidget(
                                            uid: item.user.uid,
                                            initial: initial,
                                            width: 150, height: 115),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.user.nama,
                                                style: const TextStyle(fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1A1A1A)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text('Kios ${item.user.noKios}',
                                                style: const TextStyle(
                                                    fontSize: 10, color: AppTheme.greyText)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                  color: sisaColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                      color: sisaColor.withOpacity(0.3))),
                                              child: Text(sisa,
                                                  style: TextStyle(fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: sisaColor),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.greyText, height: 1.3)),
        ]),
      ));

  Widget _filterChip(String key, String label) {
    final isActive = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: isActive ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isActive ? _teal : Colors.grey.shade200),
            boxShadow: isActive ? [BoxShadow(
                color: _teal.withOpacity(0.2), blurRadius: 6,
                offset: const Offset(0, 2))] : []),
        child: Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.greyText)),
      ),
    );
  }

  // ✅ Popup detail pedagang saat card di carousel diklik
  void _showDetailPedagang(BuildContext context, _PedagangItem item) {
    final sisaColor = _sisaColor(item.jatuhTempo);
    final sisa = _sisaText(item.jatuhTempo);
    final initial = item.user.nama.isNotEmpty
        ? item.user.nama[0].toUpperCase() : 'P';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _PhotoWidget(
                    uid: item.user.uid, initial: initial,
                    width: 90, height: 90),
              ),
              const SizedBox(height: 12),
              Text(item.user.nama,
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800, color: _teal)),
              Text('@${item.user.username}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: sisaColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sisaColor.withOpacity(0.3))),
                child: Text(sisa, style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: sisaColor)),
              ),
              const SizedBox(height: 20),
              _detailRow('Nomor Kios', item.user.noKios),
              _detailRow('Email', item.user.email),
              _detailRow('No. HP',
                  item.user.nomorHp.isNotEmpty ? item.user.nomorHp : '-'),
              _detailRow('Jenis Kelamin',
                  item.user.gender.isNotEmpty ? item.user.gender : '-'),
              _detailRow('Jatuh Tempo', item.jatuhTempo != null
                  ? _formatTanggalIndo(item.jatuhTempo!) : 'Belum ada'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
      ],
    ),
  );

  String _formatTanggalIndo(DateTime dt) {
    final bulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }
}

// ── Widget foto profil pedagang ──────────────────────────────────
class _PhotoWidget extends StatefulWidget {
  final String uid, initial;
  final double width, height;
  const _PhotoWidget({required this.uid, required this.initial,
    required this.width, required this.height});
  @override
  State<_PhotoWidget> createState() => _PhotoWidgetState();
}

class _PhotoWidgetState extends State<_PhotoWidget> {
  File? _photo;
  bool _loaded = false;
  static const Color _teal = Color(0xFF1A3C34);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_photo_${widget.uid}');
      if (path != null) {
        final f = File(path);
        if (await f.exists() && mounted) setState(() => _photo = f);
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Container(width: widget.width, height: widget.height,
          color: _teal.withOpacity(0.06),
          child: const Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: _teal, strokeWidth: 2))));
    }
    if (_photo != null) {
      return Image.file(_photo!, width: widget.width, height: widget.height,
          fit: BoxFit.cover);
    }
    return Container(width: widget.width, height: widget.height,
        color: _teal.withOpacity(0.08),
        child: Center(child: CircleAvatar(radius: 28, backgroundColor: _teal,
            child: Text(widget.initial, style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)))));
  }
}

class _PedagangItem {
  final UserModel user;
  final DateTime? jatuhTempo;
  _PedagangItem({required this.user, this.jatuhTempo});
}