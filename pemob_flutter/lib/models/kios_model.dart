import 'package:cloud_firestore/cloud_firestore.dart';

class KiosModel {
  final String id;
  final String noKios;
  final String namaPedagang;
  final String jenisJualan;
  final double hargaSewa;
  final String status;
  final String zona;
  final String nomorHp;
  final String deskripsi;
  final String ukuranKios;
  final String lokasiKios;
  final DateTime? tanggalMasuk;

  KiosModel({
    this.id = '',
    required this.noKios,
    required this.namaPedagang,
    required this.jenisJualan,
    required this.hargaSewa,
    required this.status,
    required this.zona,
    this.nomorHp = '',
    this.deskripsi = '',
    this.ukuranKios = '3x3m',
    this.lokasiKios = '',
    this.tanggalMasuk,
  });

  String get statusLabel {
    switch (status) {
      case 'aktif': return 'Aktif';
      case 'kosong': return 'Kosong';
      default: return 'Nonaktif';
    }
  }

  factory KiosModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KiosModel(
      id: doc.id,
      noKios: data['noKios'] ?? '',
      namaPedagang: data['namaPedagang'] ?? '',
      jenisJualan: data['jenisJualan'] ?? '',
      hargaSewa: (data['hargaSewa'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'kosong',
      zona: data['zona'] ?? '',
      nomorHp: data['nomorHp'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      ukuranKios: data['ukuranKios'] ?? '3x3m',
      lokasiKios: data['lokasiKios'] ?? '',
      tanggalMasuk: data['tanggalMasuk'] != null
          ? (data['tanggalMasuk'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'noKios': noKios,
    'namaPedagang': namaPedagang,
    'jenisJualan': jenisJualan,
    'hargaSewa': hargaSewa,
    'status': status,
    'zona': zona,
    'nomorHp': nomorHp,
    'deskripsi': deskripsi,
    'ukuranKios': ukuranKios,
    'lokasiKios': lokasiKios,
    'tanggalMasuk': tanggalMasuk != null
        ? Timestamp.fromDate(tanggalMasuk!)
        : null,
  };
}