import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/kios_model.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PengawasLaporanScreen extends StatefulWidget {
  const PengawasLaporanScreen({super.key});

  @override
  State<PengawasLaporanScreen> createState() => _PengawasLaporanScreenState();
}

class _PengawasLaporanScreenState extends State<PengawasLaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  String _selectedBulan = 'Semua';

  // Cache untuk export — diisi saat StreamBuilder update
  List<KiosModel> _kiosCache = [];
  List<PembayaranModel> _pembayaranCache = [];

  static const Color _teal = Color(0xFF1A3C34);
  static const Color _bg = Color(0xFFF5F7FA);

  final List<String> _bulanList = [
    'Semua', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PembayaranModel> _filterBulan(List<PembayaranModel> data) {
    if (_selectedBulan == 'Semua') return data;
    final idx = _bulanList.indexOf(_selectedBulan);
    return data.where((p) {
      try { return int.parse(p.tanggal.split('-')[1]) == idx; }
      catch (_) { return false; }
    }).toList();
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

  // ── Export menggunakan cache ─────────────────────────────────
  Future<void> _exportExcelKios() async {
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Pedagang & Kios'];
      sheet.appendRow([
        TextCellValue('Nama Pedagang'), TextCellValue('No Kios'),
        TextCellValue('Lokasi'), TextCellValue('Ukuran'),
        TextCellValue('Harga Sewa'), TextCellValue('Status'),
      ]);
      for (final k in _kiosCache) {
        sheet.appendRow([
          TextCellValue(k.namaPedagang.isNotEmpty ? k.namaPedagang : '-'),
          TextCellValue(k.noKios), TextCellValue(k.lokasiKios),
          TextCellValue(k.ukuranKios), TextCellValue(_formatRupiah(k.hargaSewa)),
          TextCellValue(k.statusLabel),
        ]);
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan_kios_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Excel disimpan: ${file.path}'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdfKios() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Laporan Pedagang & Kios',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Nama Pedagang', 'No Kios', 'Lokasi', 'Ukuran', 'Harga', 'Status'],
            data: _kiosCache.map((k) => [
              k.namaPedagang.isNotEmpty ? k.namaPedagang : '-',
              k.noKios, k.lokasiKios, k.ukuranKios,
              _formatRupiah(k.hargaSewa), k.statusLabel,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ));
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcelPembayaran() async {
    final filtered = _filterBulan(_pembayaranCache);
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Pembayaran'];
      sheet.appendRow([
        TextCellValue('Nama'), TextCellValue('Kios'),
        TextCellValue('No Transaksi'), TextCellValue('Jenis'),
        TextCellValue('Jumlah'), TextCellValue('Metode'), TextCellValue('Tanggal'),
      ]);
      for (final p in filtered) {
        sheet.appendRow([
          TextCellValue(p.namaPedagang), TextCellValue(p.noKios),
          TextCellValue(p.noTransaksi), TextCellValue(p.jenisPajakLabel),
          TextCellValue(_formatRupiah(p.jumlah)), TextCellValue(p.metodeBayar),
          TextCellValue(p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal),
        ]);
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan_pembayaran_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Excel disimpan: ${file.path}'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdfPembayaran() async {
    final filtered = _filterBulan(_pembayaranCache);
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Laporan Pembayaran - $_selectedBulan',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Nama', 'Kios', 'Jenis', 'Jumlah', 'Metode', 'Tanggal'],
            data: filtered.map((p) => [
              p.namaPedagang, p.noKios, p.jenisPajakLabel,
              _formatRupiah(p.jumlah), p.metodeBayar,
              p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ));
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Image.asset('assets/images/logo_biru.png',
                        height: 28,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_rounded, color: _teal, size: 28)),
                    const SizedBox(width: 8),
                    const Text('SIPESEL',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900,
                            color: _teal, letterSpacing: 1.5)),
                  ]),
                  const SizedBox(height: 14),
                  const Text('Laporan',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _teal)),
                  const Text('Data transaksi & rekap pedagang',
                      style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                  const SizedBox(height: 14),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: _teal,
                    indicatorWeight: 3,
                    labelColor: _teal,
                    unselectedLabelColor: AppTheme.greyText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Pedagang & Kios'),
                      Tab(text: 'Pembayaran'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body dengan StreamBuilder ────────────────────
            Expanded(
              child: StreamBuilder<List<KiosModel>>(
                stream: FirestoreService.streamKios(),
                builder: (context, snapKios) {
                  return StreamBuilder<List<PembayaranModel>>(
                    stream: FirestoreService.streamSemuaPembayaran(),
                    builder: (context, snapPembayaran) {

                      if (snapKios.connectionState == ConnectionState.waiting ||
                          snapPembayaran.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: _teal));
                      }

                      if (snapKios.hasError || snapPembayaran.hasError) {
                        return const Center(child: Text('Gagal memuat data'));
                      }

                      final kiosList = snapKios.data ?? [];
                      final semuaPembayaran = (snapPembayaran.data ?? [])
                          .where((p) => p.status == 'berhasil').toList();
                      final filteredPembayaran = _filterBulan(semuaPembayaran);
                      final totalPemasukan = filteredPembayaran
                          .fold(0.0, (s, p) => s + p.jumlah);

                      // Update cache untuk export
                      _kiosCache = kiosList;
                      _pembayaranCache = semuaPembayaran;

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // ── Tab 1: Pedagang & Kios ───────────
                          Column(children: [
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              child: Row(children: [
                                Expanded(child: _exportBtn(Icons.table_chart_rounded, 'Excel',
                                    AppTheme.primaryGreen, _isExporting ? null : _exportExcelKios)),
                                const SizedBox(width: 8),
                                Expanded(child: _exportBtn(Icons.picture_as_pdf_rounded, 'PDF',
                                    AppTheme.errorRed, _isExporting ? null : _exportPdfKios)),
                              ]),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: kiosList.isEmpty
                                  ? _emptyState('Belum ada data kios')
                                  : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: kiosList.length,
                                itemBuilder: (ctx, i) {
                                  final k = kiosList[i];
                                  final isAktif = k.status == 'aktif';
                                  final statusColor = isAktif
                                      ? AppTheme.primaryGreen
                                      : const Color(0xFFD97706);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: Column(children: [
                                      Container(height: 3,
                                          decoration: BoxDecoration(color: statusColor,
                                              borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(16)))),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                                color: _teal,
                                                borderRadius: BorderRadius.circular(10)),
                                            alignment: Alignment.center,
                                            child: Text(k.zona,
                                                style: const TextStyle(
                                                    color: Colors.white, fontSize: 18,
                                                    fontWeight: FontWeight.w900)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(k.noKios, style: const TextStyle(
                                                    fontSize: 13, fontWeight: FontWeight.w700,
                                                    color: _teal)),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6)),
                                                  child: Text(k.statusLabel,
                                                      style: TextStyle(fontSize: 9,
                                                          fontWeight: FontWeight.w700,
                                                          color: statusColor)),
                                                ),
                                              ]),
                                              Text(k.namaPedagang.isNotEmpty
                                                  ? k.namaPedagang : 'Kios Kosong',
                                                  style: const TextStyle(
                                                      fontSize: 11, color: AppTheme.greyText)),
                                              Text(_formatRupiah(k.hargaSewa),
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.w700,
                                                      color: _teal)),
                                            ],
                                          )),
                                        ]),
                                      ),
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ]),

                          // ── Tab 2: Pembayaran ─────────────────
                          Column(children: [
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: _teal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_formatRupiah(totalPemasukan),
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w900, color: _teal)),
                                        Text('${filteredPembayaran.length} transaksi',
                                            style: const TextStyle(fontSize: 10, color: AppTheme.greyText)),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FA),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: DropdownButton<String>(
                                      value: _selectedBulan,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.expand_more_rounded, color: _teal),
                                      style: const TextStyle(
                                          color: _teal, fontSize: 12, fontWeight: FontWeight.w600),
                                      onChanged: (v) => setState(() => _selectedBulan = v!),
                                      items: _bulanList.map((b) =>
                                          DropdownMenuItem(value: b, child: Text(b))).toList(),
                                    ),
                                  )),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: _exportBtn(Icons.table_chart_rounded, 'Excel',
                                      AppTheme.primaryGreen,
                                      _isExporting ? null : _exportExcelPembayaran)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _exportBtn(Icons.picture_as_pdf_rounded, 'PDF',
                                      AppTheme.errorRed,
                                      _isExporting ? null : _exportPdfPembayaran)),
                                ]),
                              ]),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: filteredPembayaran.isEmpty
                                  ? _emptyState('Belum ada pembayaran berhasil')
                                  : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredPembayaran.length,
                                itemBuilder: (ctx, i) {
                                  final p = filteredPembayaran[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                              color: _teal.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(10)),
                                          alignment: Alignment.center,
                                          child: Text(
                                              p.namaPedagang.isNotEmpty
                                                  ? p.namaPedagang[0].toUpperCase() : 'P',
                                              style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.w800,
                                                  color: _teal)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.namaPedagang, style: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w700,
                                                color: _teal)),
                                            Text('Kios ${p.noKios} • ${p.jenisPajakLabel}',
                                                style: const TextStyle(
                                                    fontSize: 11, color: AppTheme.greyText)),
                                            Text(p.tanggal.length >= 10
                                                ? p.tanggal.substring(0, 10) : p.tanggal,
                                                style: const TextStyle(
                                                    fontSize: 10, color: AppTheme.greyText)),
                                          ],
                                        )),
                                        Text(_formatRupiah(p.jumlah),
                                            style: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w800,
                                                color: AppTheme.primaryGreen)),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ]),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportBtn(IconData icon, String label, Color color, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );

  Widget _emptyState(String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: const Icon(Icons.description_outlined,
            size: 40, color: AppTheme.greyText),
      ),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(color: AppTheme.greyText)),
    ]),
  );
}