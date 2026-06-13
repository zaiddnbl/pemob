import 'package:cloud_firestore/cloud_firestore.dart';

// Harga default — akan di-override dari Firestore koleksi 'tagihan'
Map<String, double> hargaPajak = {
  'harian': 5000,
  'mingguan': 35000,
  'bulanan': 150000,
};

class PembayaranModel {
  final String id;
  final String noTransaksi;
  final String noKios;
  final String jenisPajak;
  final double jumlah;
  final String status;
  final String tanggal;
  final String metodeBayar;
  final String namaPedagang;
  final String catatan;
  final String alasanPenolakan;

  PembayaranModel({
    this.id = '',
    required this.noTransaksi,
    required this.noKios,
    required this.jenisPajak,
    required this.jumlah,
    required this.status,
    required this.tanggal,
    required this.metodeBayar,
    this.namaPedagang = '',
    this.catatan = '',
    this.alasanPenolakan = '',
  });

  String get statusLabel {
    switch (status) {
      case 'berhasil': return 'Berhasil';
      case 'pending': return 'Menunggu Verifikasi';
      case 'ditolak': return 'Ditolak';
      default: return 'Pending';
    }
  }

  String get jenisPajakLabel {
    switch (jenisPajak) {
      case 'harian': return 'Harian';
      case 'mingguan': return 'Mingguan';
      case 'bulanan': return 'Bulanan';
      default: return jenisPajak;
    }
  }

  factory PembayaranModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PembayaranModel(
      id: doc.id,
      noTransaksi: data['noTransaksi'] ?? '',
      noKios: data['noKios'] ?? '',
      jenisPajak: data['jenisPajak'] ?? 'harian',
      jumlah: (data['jumlah'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'pending',
      tanggal: data['tanggal'] ?? '',
      metodeBayar: data['metodeBayar'] ?? '',
      namaPedagang: data['namaPedagang'] ?? '',
      catatan: data['catatan'] ?? '',
      alasanPenolakan: data['alasanPenolakan'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'noTransaksi': noTransaksi,
    'noKios': noKios,
    'jenisPajak': jenisPajak,
    'jumlah': jumlah,
    'status': status,
    'tanggal': tanggal,
    'metodeBayar': metodeBayar,
    'namaPedagang': namaPedagang,
    'catatan': catatan,
    'alasanPenolakan': alasanPenolakan,
    'createdAt': FieldValue.serverTimestamp(),
  };
}