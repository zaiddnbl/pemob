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
  bool _isLoading = false;
  List<KiosModel> _kiosList = [];
  List<PembayaranModel> _pembayaranList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      FirestoreService.getKios(),
      FirestoreService.getPembayaranByStatus('berhasil'),
    ]);
    if (mounted) {
      setState(() {
        _kiosList = results[0] as List<KiosModel>;
        _pembayaranList = results[1] as List<PembayaranModel>;
        _isLoading = false;
      });
    }
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

  Future<void> _exportExcelKios() async {
    final excel = Excel.createExcel();
    final sheet = excel['Pedagang & Kios'];

    // Header
    sheet.appendRow([
      TextCellValue('Nama Pedagang'),
      TextCellValue('No Kios'),
      TextCellValue('Lokasi Kios'),
      TextCellValue('Ukuran Kios'),
      TextCellValue('Harga Sewa/Bulan'),
      TextCellValue('Status'),
    ]);

    for (final k in _kiosList) {
      sheet.appendRow([
        TextCellValue(k.namaPedagang.isNotEmpty ? k.namaPedagang : '-'),
        TextCellValue(k.noKios),
        TextCellValue(k.lokasiKios),
        TextCellValue(k.ukuranKios),
        TextCellValue(_formatRupiah(k.hargaSewa)),
        TextCellValue(k.statusLabel),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan_kios.xlsx');
    await file.writeAsBytes(excel.encode()!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel disimpan: ${file.path}'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _exportPdfKios() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Laporan Pedagang & Kios',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nama Pedagang', 'No Kios', 'Lokasi', 'Ukuran', 'Harga Sewa', 'Status'
            ],
            data: _kiosList.map((k) => [
              k.namaPedagang.isNotEmpty ? k.namaPedagang : '-',
              k.noKios,
              k.lokasiKios,
              k.ukuranKios,
              _formatRupiah(k.hargaSewa),
              k.statusLabel,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<void> _exportExcelPembayaran() async {
    final excel = Excel.createExcel();
    final sheet = excel['Pembayaran Berhasil'];

    sheet.appendRow([
      TextCellValue('Nama Pedagang'),
      TextCellValue('No Kios'),
      TextCellValue('No Transaksi'),
      TextCellValue('Jenis Pembayaran'),
      TextCellValue('Jumlah'),
      TextCellValue('Metode'),
      TextCellValue('Tanggal'),
    ]);

    for (final p in _pembayaranList) {
      sheet.appendRow([
        TextCellValue(p.namaPedagang),
        TextCellValue(p.noKios),
        TextCellValue(p.noTransaksi),
        TextCellValue(p.jenisPajakLabel),
        TextCellValue(_formatRupiah(p.jumlah)),
        TextCellValue(p.metodeBayar),
        TextCellValue(p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan_pembayaran.xlsx');
    await file.writeAsBytes(excel.encode()!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel disimpan: ${file.path}'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _exportPdfPembayaran() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Laporan Pembayaran Berhasil',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Nama Pedagang', 'No Kios', 'No Transaksi',
              'Jenis', 'Jumlah', 'Metode', 'Tanggal'
            ],
            data: _pembayaranList.map((p) => [
              p.namaPedagang,
              p.noKios,
              p.noTransaksi,
              p.jenisPajakLabel,
              _formatRupiah(p.jumlah),
              p.metodeBayar,
              p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Laporan'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pedagang & Kios'),
            Tab(text: 'Pembayaran'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Pedagang & Kios ──────────────
          Column(
            children: [
              // Export buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportExcelKios,
                        icon: const Icon(Icons.table_chart_rounded,
                            size: 16, color: AppTheme.primaryGreen),
                        label: const Text('Export Excel',
                            style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportPdfKios,
                        icon: const Icon(Icons.picture_as_pdf_rounded,
                            size: 16, color: AppTheme.errorRed),
                        label: const Text('Export PDF',
                            style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.errorRed),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _kiosList.isEmpty
                    ? const Center(
                    child: Text('Belum ada data kios',
                        style: TextStyle(
                            color: AppTheme.greyText)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _kiosList.length,
                  itemBuilder: (context, index) {
                    final k = _kiosList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color:
                              Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                k.namaPedagang.isNotEmpty
                                    ? k.namaPedagang
                                    : 'Kios Kosong',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText),
                              ),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: (k.status == 'aktif'
                                      ? AppTheme.primaryGreen
                                      : AppTheme.errorRed)
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(k.statusLabel,
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight:
                                        FontWeight.w700,
                                        color: k.status == 'aktif'
                                            ? AppTheme.primaryGreen
                                            : AppTheme.errorRed)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _laporanRow('No Kios', k.noKios),
                          _laporanRow('Lokasi', k.lokasiKios),
                          _laporanRow('Ukuran', k.ukuranKios),
                          _laporanRow('Harga Sewa/Bulan',
                              _formatRupiah(k.hargaSewa)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Tab 2: Pembayaran ───────────────────
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportExcelPembayaran,
                        icon: const Icon(Icons.table_chart_rounded,
                            size: 16, color: AppTheme.primaryGreen),
                        label: const Text('Export Excel',
                            style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportPdfPembayaran,
                        icon: const Icon(Icons.picture_as_pdf_rounded,
                            size: 16, color: AppTheme.errorRed),
                        label: const Text('Export PDF',
                            style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.errorRed),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _pembayaranList.isEmpty
                    ? const Center(
                    child: Text('Belum ada pembayaran berhasil',
                        style: TextStyle(
                            color: AppTheme.greyText)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pembayaranList.length,
                  itemBuilder: (context, index) {
                    final p = _pembayaranList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color:
                              Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(p.namaPedagang,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkText)),
                          const SizedBox(height: 6),
                          _laporanRow('No Kios', p.noKios),
                          _laporanRow('No Transaksi',
                              p.noTransaksi),
                          _laporanRow('Jenis', p.jenisPajakLabel),
                          _laporanRow('Jumlah',
                              _formatRupiah(p.jumlah)),
                          _laporanRow('Metode', p.metodeBayar),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _laporanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.greyText)),
          ),
          Expanded(
            child: Text(': $value',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText)),
          ),
        ],
      ),
    );
  }
}