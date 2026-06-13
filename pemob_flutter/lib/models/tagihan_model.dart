import 'package:cloud_firestore/cloud_firestore.dart';
import 'pembayaran_model.dart';

class TagihanModel {
  final String id;
  final double hargaHarian;
  final double hargaMingguan;
  final double hargaBulanan;
  final DateTime? updatedAt;

  TagihanModel({
    this.id = '',
    required this.hargaHarian,
    required this.hargaMingguan,
    required this.hargaBulanan,
    this.updatedAt,
  });

  factory TagihanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TagihanModel(
      id: doc.id,
      hargaHarian: (data['hargaHarian'] as num?)?.toDouble() ?? 5000,
      hargaMingguan: (data['hargaMingguan'] as num?)?.toDouble() ?? 35000,
      hargaBulanan: (data['hargaBulanan'] as num?)?.toDouble() ?? 150000,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'hargaHarian': hargaHarian,
    'hargaMingguan': hargaMingguan,
    'hargaBulanan': hargaBulanan,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Update global hargaPajak map dari pembayaran_model.dart
  void applyToGlobal() {
    hargaPajak['harian'] = hargaHarian;
    hargaPajak['mingguan'] = hargaMingguan;
    hargaPajak['bulanan'] = hargaBulanan;
  }
}