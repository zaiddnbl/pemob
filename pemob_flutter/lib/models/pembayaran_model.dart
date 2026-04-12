class PembayaranModel {
  final int idPembayaran;
  final String noKios;
  final String namaPedagang;
  final String bulan;
  final int tahun;
  final double jumlah;
  final String status; // 'lunas', 'belum', 'telat'
  final String tanggalBayar;
  final String metodeBayar;

  PembayaranModel({
    required this.idPembayaran,
    required this.noKios,
    required this.namaPedagang,
    required this.bulan,
    required this.tahun,
    required this.jumlah,
    required this.status,
    required this.tanggalBayar,
    required this.metodeBayar,
  });

  String get statusLabel {
    switch (status) {
      case 'lunas':
        return 'Lunas';
      case 'telat':
        return 'Terlambat';
      default:
        return 'Belum Bayar';
    }
  }
}

final List<PembayaranModel> dummyPembayaran = [
  PembayaranModel(idPembayaran: 1, noKios: 'A-01', namaPedagang: 'Budi Santoso', bulan: 'April', tahun: 2025, jumlah: 500000, status: 'lunas', tanggalBayar: '2025-04-03', metodeBayar: 'Transfer'),
  PembayaranModel(idPembayaran: 2, noKios: 'A-02', namaPedagang: 'Siti Aminah', bulan: 'April', tahun: 2025, jumlah: 450000, status: 'belum', tanggalBayar: '-', metodeBayar: '-'),
  PembayaranModel(idPembayaran: 3, noKios: 'B-01', namaPedagang: 'Ahmad Yusuf', bulan: 'April', tahun: 2025, jumlah: 600000, status: 'lunas', tanggalBayar: '2025-04-05', metodeBayar: 'Tunai'),
  PembayaranModel(idPembayaran: 4, noKios: 'B-02', namaPedagang: 'Dewi Lestari', bulan: 'April', tahun: 2025, jumlah: 550000, status: 'telat', tanggalBayar: '-', metodeBayar: '-'),
  PembayaranModel(idPembayaran: 5, noKios: 'C-01', namaPedagang: 'Hendra Gunawan', bulan: 'April', tahun: 2025, jumlah: 480000, status: 'lunas', tanggalBayar: '2025-04-02', metodeBayar: 'QRIS'),
  PembayaranModel(idPembayaran: 6, noKios: 'C-02', namaPedagang: 'Rina Marlina', bulan: 'April', tahun: 2025, jumlah: 520000, status: 'belum', tanggalBayar: '-', metodeBayar: '-'),
  PembayaranModel(idPembayaran: 7, noKios: 'A-03', namaPedagang: 'Wahyu Prasetyo', bulan: 'Maret', tahun: 2025, jumlah: 500000, status: 'lunas', tanggalBayar: '2025-03-04', metodeBayar: 'Transfer'),
  PembayaranModel(idPembayaran: 8, noKios: 'A-04', namaPedagang: 'Fitri Handayani', bulan: 'Maret', tahun: 2025, jumlah: 450000, status: 'lunas', tanggalBayar: '2025-03-07', metodeBayar: 'Tunai'),
  PembayaranModel(idPembayaran: 9, noKios: 'D-01', namaPedagang: 'Bambang Susilo', bulan: 'Maret', tahun: 2025, jumlah: 700000, status: 'telat', tanggalBayar: '-', metodeBayar: '-'),
  PembayaranModel(idPembayaran: 10, noKios: 'D-02', namaPedagang: 'Nurul Hidayah', bulan: 'Maret', tahun: 2025, jumlah: 650000, status: 'lunas', tanggalBayar: '2025-03-10', metodeBayar: 'QRIS'),
  PembayaranModel(idPembayaran: 11, noKios: 'B-03', namaPedagang: 'Agus Setiawan', bulan: 'Februari', tahun: 2025, jumlah: 600000, status: 'lunas', tanggalBayar: '2025-02-05', metodeBayar: 'Transfer'),
  PembayaranModel(idPembayaran: 12, noKios: 'C-03', namaPedagang: 'Maya Kusuma', bulan: 'Februari', tahun: 2025, jumlah: 480000, status: 'belum', tanggalBayar: '-', metodeBayar: '-'),
];