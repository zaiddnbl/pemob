# SIPESEL — Sistem Informasi Pengelolaan Sewa Kios

## Nama dan NIM Anggota Kelompok

| Nama | NIM |
|------|-----|
| Muhammad Zaidan Nabil | 24082010007 |
| Najwa Wahida | 240820100__ |
| Hilwatul Maghfiroh | 240820100__ |
| Nayyara Qudsia | 240820100__ |
| Rinda Alisya | 240820100__ |

## Tema Aplikasi

Aplikasi Manajemen Tugas / Operasional — diimplementasikan sebagai sistem pengelolaan sewa kios dan retribusi pasar.

## Deskripsi Singkat Aplikasi

SIPESEL adalah aplikasi mobile berbasis Flutter untuk mengelola pembayaran retribusi sewa kios di Pasar Wadungasri, Sidoarjo. Aplikasi ini melibatkan tiga peran pengguna: **Pedagang** (membayar retribusi dan memantau status kios), **Admin** (mengelola data pedagang, kios, tagihan, dan verifikasi pembayaran), dan **Pengawas** (memantau aktivitas pembayaran dan menghasilkan laporan). Seluruh data aplikasi tersimpan dan diambil secara real-time dari Cloud Firestore.

## Jenis Firebase yang Digunakan

**Cloud Firestore**

Aplikasi menggunakan `firebase_core` untuk inisialisasi, `firebase_auth` untuk autentikasi pengguna, dan `cloud_firestore` untuk penyimpanan dan pengambilan data secara real-time melalui `StreamBuilder`.

## Struktur Koleksi Firebase

### 1. `users`
Menyimpan data akun pengguna (pedagang, admin, pengawas).

| Field | Tipe | Keterangan |
|-------|------|------------|
| uid | String | ID dokumen (sama dengan Firebase Auth UID) |
| nama | String | Nama lengkap pengguna |
| username | String | Username untuk login |
| email | String | Email akun |
| nomorHp | String | Nomor HP |
| gender | String | Jenis kelamin |
| role | String | `pedagang` / `admin` / `pengawas` |
| noKios | String | Nomor kios (khusus pedagang) |
| createdAt | Timestamp | Waktu akun dibuat |

### 2. `kios`
Menyimpan data kios di pasar.

| Field | Tipe | Keterangan |
|-------|------|------------|
| noKios | String | Nomor kios (contoh: A-01) |
| namaPedagang | String | Nama pedagang yang menyewa |
| jenisJualan | String | Jenis dagangan |
| hargaSewa | Number | Harga sewa per bulan |
| status | String | `aktif` / `kosong` |
| zona | String | Zona kios (A–E) |
| nomorHp | String | Nomor HP pedagang |
| deskripsi | String | Deskripsi tambahan |
| ukuranKios | String | Ukuran fisik kios |
| lokasiKios | String | Lokasi kios |
| tanggalMasuk | Timestamp | Tanggal pedagang bergabung |

### 3. `pembayaran`
Menyimpan riwayat transaksi pembayaran retribusi.

| Field | Tipe | Keterangan |
|-------|------|------------|
| noTransaksi | String | Nomor transaksi unik |
| noKios | String | Kios yang membayar |
| jenisPajak | String | `harian` / `mingguan` / `bulanan` |
| jumlah | Number | Nominal pembayaran |
| status | String | `pending` / `berhasil` / `ditolak` |
| tanggal | String | Tanggal & jam transaksi |
| metodeBayar | String | Metode pembayaran |
| namaPedagang | String | Nama pedagang |
| catatan | String | Catatan tambahan |
| alasanPenolakan | String | Alasan jika ditolak admin |

### 4. `tagihan`
Menyimpan konfigurasi harga retribusi yang dapat diubah admin.

| Field | Tipe | Keterangan |
|-------|------|------------|
| hargaHarian | Number | Tarif retribusi harian |
| hargaMingguan | Number | Tarif retribusi mingguan |
| hargaBulanan | Number | Tarif retribusi bulanan |
| updatedAt | Timestamp | Waktu terakhir diubah |

## Jumlah Data yang Digunakan

- Koleksi `kios`: 20+ dokumen kios di berbagai zona (A–E)
- Koleksi `pembayaran`: 20+ dokumen transaksi dengan berbagai status
- Koleksi `users`: data akun untuk pedagang, admin, dan pengawas
- Koleksi `tagihan`: 1 dokumen konfigurasi harga aktif

## Fitur Utama Aplikasi

### Pedagang
- Login dan registrasi dengan validasi form
- Dashboard menampilkan info kios, jatuh tempo, dan riwayat transaksi terbaru (real-time)
- Pembayaran retribusi dengan pilihan jenis (harian/mingguan/bulanan) dan metode bayar (termasuk QRIS)
- Riwayat transaksi lengkap dengan detail bukti pembayaran
- Lihat detail kios sendiri secara real-time

### Admin
- Dashboard statistik (jumlah pedagang, kios aktif, pemasukan bulanan)
- Manajemen data pengguna (CRUD) dengan sinkronisasi otomatis ke data kios
- Manajemen data kios (CRUD) dengan filter zona dan status
- Verifikasi pembayaran pedagang (approve/reject)
- Pengaturan tarif retribusi
- Laporan transaksi dengan export Excel dan PDF

### Pengawas
- Dashboard pemantauan jumlah pedagang, kios aktif, dan total retribusi
- Pencarian dan filter daftar pedagang berdasarkan nama dan status jatuh tempo
- Monitoring pembayaran real-time dengan filter status
- Statistik pemasukan per jenis retribusi
- Export laporan ke Excel dan PDF

### Fitur Teknis
- Autentikasi Firebase (login berbasis username yang dipetakan ke email)
- Data real-time menggunakan `StreamBuilder` di seluruh halaman utama
- Pencarian dan filter data
- Form dengan validasi menggunakan `GlobalKey<FormState>`
- Navigasi `BottomNavigationBar` untuk setiap role
- Foto profil tersimpan lokal menggunakan `SharedPreferences`

## Screenshot Aplikasi

*(Tempelkan screenshot berikut sebelum submit — minimal 3 halaman berbeda)*

1. Halaman Login / Dashboard Pedagang
2. Halaman Dashboard Admin
3. Halaman Dashboard Pengawas / Monitoring

## Cara Menjalankan Aplikasi

1. Clone repository ini:
   ```
   git clone <url-repository-anda>
   ```
2. Masuk ke folder project:
   ```
   cd sipesel
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Pastikan file konfigurasi Firebase (`google-services.json` untuk Android) sudah ditempatkan di `android/app/`.
5. Jalankan aplikasi:
   ```
   flutter run
   ```

## Keterangan Penggunaan AI

Dalam pengembangan proyek ini, AI (Claude oleh Anthropic) digunakan sebagai alat bantu untuk:
- Membantu debugging error pada kode Flutter
- Memberikan referensi implementasi `StreamBuilder` dan integrasi Cloud Firestore
- Menyusun struktur koleksi Firestore
- Membantu perbaikan tampilan UI agar sesuai kriteria UAS

Seluruh kode yang dihasilkan telah dipahami dan diverifikasi oleh anggota kelompok sebelum dikumpulkan.
