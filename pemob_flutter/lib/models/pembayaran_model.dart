// Harga pajak per jenis
const Map<String, double> hargaPajak = {
  'harian': 5000,
  'mingguan': 35000,
  'bulanan': 150000,
};

class PembayaranModel {
  final String noTransaksi;
  final String noKios;
  final String jenisPajak; // 'harian', 'mingguan', 'bulanan'
  final double jumlah;
  final String status; // 'berhasil', 'pending', 'gagal'
  final String tanggal; // format: '2026-04-13 07:39:07'
  final String metodeBayar;

  PembayaranModel({
    required this.noTransaksi,
    required this.noKios,
    required this.jenisPajak,
    required this.jumlah,
    required this.status,
    required this.tanggal,
    required this.metodeBayar,
  });

  String get statusLabel {
    switch (status) {
      case 'berhasil':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'gagal':
        return 'Gagal';
      default:
        return 'Pending';
    }
  }

  String get jenisPajakLabel {
    switch (jenisPajak) {
      case 'harian':
        return 'Harian';
      case 'mingguan':
        return 'Mingguan';
      case 'bulanan':
        return 'Bulanan';
      default:
        return jenisPajak;
    }
  }
}

// Dummy data — sesuai web (5 transaksi, 2 pending, 1 berhasil, 2 gagal)
final List<PembayaranModel> dummyPembayaran = [
  PembayaranModel(
    noTransaksi: 'TRX-20260413-152847',
    noKios: 'k-321',
    jenisPajak: 'harian',
    jumlah: 5000,
    status: 'pending',
    tanggal: '2026-04-13 07:39:07',
    metodeBayar: 'DANA',
  ),
  PembayaranModel(
    noTransaksi: 'TRX-20260412-587324',
    noKios: 'k-321',
    jenisPajak: 'harian',
    jumlah: 5000,
    status: 'pending',
    tanggal: '2026-04-12 08:42:34',
    metodeBayar: 'DANA',
  ),
  PembayaranModel(
    noTransaksi: 'TRX-20260411-234561',
    noKios: 'k-321',
    jenisPajak: 'mingguan',
    jumlah: 35000,
    status: 'berhasil',
    tanggal: '2026-04-11 09:15:00',
    metodeBayar: 'Transfer',
  ),
  PembayaranModel(
    noTransaksi: 'TRX-20260404-891234',
    noKios: 'k-321',
    jenisPajak: 'harian',
    jumlah: 5000,
    status: 'gagal',
    tanggal: '2026-04-04 10:00:00',
    metodeBayar: 'DANA',
  ),
  PembayaranModel(
    noTransaksi: 'TRX-20260401-456789',
    noKios: 'k-321',
    jenisPajak: 'harian',
    jumlah: 5000,
    status: 'gagal',
    tanggal: '2026-04-01 08:00:00',
    metodeBayar: 'QRIS',
  ),
];