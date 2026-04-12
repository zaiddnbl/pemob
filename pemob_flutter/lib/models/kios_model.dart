class KiosModel {
  final String noKios;
  final String namaPedagang;
  final String jenisJualan;
  final double hargaSewa;
  final String status; // 'aktif', 'kosong', 'nonaktif'
  final String zona;

  KiosModel({
    required this.noKios,
    required this.namaPedagang,
    required this.jenisJualan,
    required this.hargaSewa,
    required this.status,
    required this.zona,
  });

  String get statusLabel {
    switch (status) {
      case 'aktif':
        return 'Aktif';
      case 'kosong':
        return 'Kosong';
      default:
        return 'Nonaktif';
    }
  }
}

final List<KiosModel> dummyKios = [
  KiosModel(noKios: 'A-01', namaPedagang: 'Budi Santoso', jenisJualan: 'Sembako', hargaSewa: 500000, status: 'aktif', zona: 'A'),
  KiosModel(noKios: 'A-02', namaPedagang: 'Siti Aminah', jenisJualan: 'Sayur & Buah', hargaSewa: 450000, status: 'aktif', zona: 'A'),
  KiosModel(noKios: 'A-03', namaPedagang: 'Wahyu Prasetyo', jenisJualan: 'Daging & Ikan', hargaSewa: 500000, status: 'aktif', zona: 'A'),
  KiosModel(noKios: 'A-04', namaPedagang: 'Fitri Handayani', jenisJualan: 'Bumbu Dapur', hargaSewa: 450000, status: 'aktif', zona: 'A'),
  KiosModel(noKios: 'B-01', namaPedagang: 'Ahmad Yusuf', jenisJualan: 'Pakaian', hargaSewa: 600000, status: 'aktif', zona: 'B'),
  KiosModel(noKios: 'B-02', namaPedagang: 'Dewi Lestari', jenisJualan: 'Aksesoris', hargaSewa: 550000, status: 'aktif', zona: 'B'),
  KiosModel(noKios: 'B-03', namaPedagang: 'Agus Setiawan', jenisJualan: 'Sepatu & Sandal', hargaSewa: 600000, status: 'aktif', zona: 'B'),
  KiosModel(noKios: 'B-04', namaPedagang: '', jenisJualan: '-', hargaSewa: 550000, status: 'kosong', zona: 'B'),
  KiosModel(noKios: 'C-01', namaPedagang: 'Hendra Gunawan', jenisJualan: 'Elektronik', hargaSewa: 480000, status: 'aktif', zona: 'C'),
  KiosModel(noKios: 'C-02', namaPedagang: 'Rina Marlina', jenisJualan: 'Mainan Anak', hargaSewa: 520000, status: 'aktif', zona: 'C'),
  KiosModel(noKios: 'C-03', namaPedagang: 'Maya Kusuma', jenisJualan: 'Alat Tulis', hargaSewa: 480000, status: 'aktif', zona: 'C'),
  KiosModel(noKios: 'D-01', namaPedagang: 'Bambang Susilo', jenisJualan: 'Warung Makan', hargaSewa: 700000, status: 'aktif', zona: 'D'),
  KiosModel(noKios: 'D-02', namaPedagang: 'Nurul Hidayah', jenisJualan: 'Jajanan Pasar', hargaSewa: 650000, status: 'aktif', zona: 'D'),
  KiosModel(noKios: 'D-03', namaPedagang: '', jenisJualan: '-', hargaSewa: 650000, status: 'kosong', zona: 'D'),
];