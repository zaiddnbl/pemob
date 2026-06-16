import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/pembayaran_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminLaporanScreen extends StatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  State<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends State<AdminLaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBulan = 'Semua';

  // Cache untuk export
  List<PembayaranModel> _dataCache = [];

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
    final bulanIdx = _bulanList.indexOf(_selectedBulan);
    return data.where((p) {
      try { return int.parse(p.tanggal.split('-')[1]) == bulanIdx; }
      catch (_) { return false; }
    }).toList();
  }

  Map<String, Map<String, dynamic>> _groupByUser(List<PembayaranModel> data) {
    final map = <String, Map<String, dynamic>>{};
    for (final p in data) {
      if (!map.containsKey(p.noKios)) {
        map[p.noKios] = {
          'namaPedagang': p.namaPedagang,
          'noKios': p.noKios,
          'total': 0.0,
          'jumlahTransaksi': 0,
        };
      }
      map[p.noKios]!['total'] = (map[p.noKios]!['total'] as double) + p.jumlah;
      map[p.noKios]!['jumlahTransaksi'] =
          (map[p.noKios]!['jumlahTransaksi'] as int) + 1;
    }
    return map;
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

  Future<void> _exportExcel(bool perUser) async {
    final filtered = _filterBulan(_dataCache);
    final grouped = _groupByUser(filtered);
    final excel = Excel.createExcel();
    final sheetName = perUser ? 'Laporan Per User' : 'Laporan Semua';
    final sheet = excel[sheetName];

    if (perUser) {
      sheet.appendRow([
        TextCellValue('Nama Pedagang'), TextCellValue('No Kios'),
        TextCellValue('Jumlah Transaksi'), TextCellValue('Total Pembayaran'),
      ]);
      for (final entry in grouped.entries) {
        final d = entry.value;
        sheet.appendRow([
          TextCellValue(d['namaPedagang']), TextCellValue(d['noKios']),
          TextCellValue('${d['jumlahTransaksi']}x'), TextCellValue(_formatRupiah(d['total'])),
        ]);
      }
    } else {
      sheet.appendRow([
        TextCellValue('Nama Pedagang'), TextCellValue('No Kios'),
        TextCellValue('No Transaksi'), TextCellValue('Jenis'),
        TextCellValue('Jumlah'), TextCellValue('Metode'),
        TextCellValue('Status'), TextCellValue('Tanggal'),
      ]);
      for (final p in filtered) {
        sheet.appendRow([
          TextCellValue(p.namaPedagang), TextCellValue(p.noKios),
          TextCellValue(p.noTransaksi), TextCellValue(p.jenisPajakLabel),
          TextCellValue(_formatRupiah(p.jumlah)), TextCellValue(p.metodeBayar),
          TextCellValue(p.statusLabel),
          TextCellValue(p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal),
        ]);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan_admin_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Excel disimpan: ${file.path}'),
      backgroundColor: AppTheme.primaryGreen,
    ));
  }

  Future<void> _exportPdf(bool perUser) async {
    final filtered = _filterBulan(_dataCache);
    final grouped = _groupByUser(filtered);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) {
        if (perUser) {
          return [
            pw.Text('Laporan Pembayaran Per User - $_selectedBulan',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Nama Pedagang', 'No Kios', 'Jumlah Transaksi', 'Total'],
              data: grouped.values.map((d) => [
                d['namaPedagang'], d['noKios'],
                '${d['jumlahTransaksi']}x', _formatRupiah(d['total']),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
            ),
          ];
        } else {
          return [
            pw.Text('Laporan Seluruh Pembayaran - $_selectedBulan',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Nama', 'Kios', 'Jenis', 'Jumlah', 'Metode', 'Status', 'Tanggal'],
              data: filtered.map((p) => [
                p.namaPedagang, p.noKios, p.jenisPajakLabel,
                _formatRupiah(p.jumlah), p.metodeBayar, p.statusLabel,
                p.tanggal.length >= 10 ? p.tanggal.substring(0, 10) : p.tanggal,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
            ),
          ];
        }
      },
    ));
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
            Tab(text: 'Semua Pembayaran'),
            Tab(text: 'Per User'),
          ],
        ),
      ),
      body: StreamBuilder<List<PembayaranModel>>(
        stream: FirestoreService.streamSemuaPembayaran(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.errorRed)));
          }

          final semuaData = snapshot.data ?? [];
          // Update cache untuk export
          _dataCache = semuaData;

          final filteredData = _filterBulan(semuaData);
          final groupedByUser = _groupByUser(filteredData);

          return Column(
            children: [
              // Filter bulan
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text('Filter: ',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedBulan,
                        isExpanded: true,
                        underline: const SizedBox(),
                        onChanged: (v) => setState(() => _selectedBulan = v!),
                        items: _bulanList.map((b) =>
                            DropdownMenuItem(value: b, child: Text(b))).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Export buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TabBuilder(
                  controller: _tabController,
                  builder: (isPerUser) => Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportExcel(isPerUser),
                        icon: const Icon(Icons.table_chart_rounded,
                            size: 14, color: AppTheme.primaryGreen),
                        label: const Text('Excel',
                            style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportPdf(isPerUser),
                        icon: const Icon(Icons.picture_as_pdf_rounded,
                            size: 14, color: AppTheme.errorRed),
                        label: const Text('PDF',
                            style: TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorRed),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 1: Semua pembayaran ──────────
                    filteredData.isEmpty
                        ? const Center(child: Text('Tidak ada data',
                        style: TextStyle(color: AppTheme.greyText)))
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final p = filteredData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.namaPedagang,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppTheme.darkText)),
                                Text('Kios ${p.noKios} • ${p.jenisPajakLabel} • ${p.metodeBayar}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.greyText)),
                                Text(p.tanggal.length >= 10
                                    ? p.tanggal.substring(0, 10) : p.tanggal,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppTheme.greyText)),
                              ],
                            )),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_formatRupiah(p.jumlah),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryGreen)),
                              Text(p.statusLabel,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppTheme.greyText)),
                            ]),
                          ]),
                        );
                      },
                    ),

                    // ── Tab 2: Per user ──────────────────
                    groupedByUser.isEmpty
                        ? const Center(child: Text('Tidak ada data',
                        style: TextStyle(color: AppTheme.greyText)))
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: groupedByUser.length,
                      itemBuilder: (context, index) {
                        final entry = groupedByUser.entries.elementAt(index);
                        final d = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                                left: BorderSide(
                                    color: AppTheme.primaryGreen, width: 4)),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['namaPedagang'],
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppTheme.darkText)),
                                Text('Kios ${d['noKios']}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.greyText)),
                                Text('${d['jumlahTransaksi']} transaksi di bulan ini',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.greyText)),
                              ],
                            )),
                            Text(_formatRupiah(d['total']),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryGreen)),
                          ]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Helper widget untuk detect tab index
class TabBuilder extends StatefulWidget {
  final TabController controller;
  final Widget Function(bool isSecondTab) builder;

  const TabBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<TabBuilder> createState() => _TabBuilderState();
}

class _TabBuilderState extends State<TabBuilder> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(widget.controller.index == 1);
  }
}