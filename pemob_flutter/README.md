# SIPESEL — Sistem Informasi Pembayaran Pajak Pasar

## Anggota Kelompok

| Nama | NIM |
|------|-----|
| Muhammad Zaidan Nabil | 24082010007 |

## Tema Aplikasi

**E-Commerce / Sistem Manajemen** — Sistem Pengelolaan Sewa Kios dan Pembayaran Pajak Pasar Wadungasri, Sidoarjo.

## Deskripsi Singkat

SIPESEL adalah aplikasi mobile Flutter yang memudahkan pedagang pasar dalam melakukan pembayaran pajak kios secara digital. Aplikasi menampilkan daftar kios pasar secara real-time dari Firebase, memungkinkan pedagang memilih jenis pembayaran (harian, mingguan, bulanan), dan menyimpan transaksi langsung ke Cloud Firestore. Terdapat tiga peran pengguna: Pedagang, Pengawas, dan Admin.

## Firebase yang Digunakan

**Cloud Firestore**

## Struktur Koleksi Firebase

### Koleksi `kios`
Menyimpan data seluruh kios di pasar.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `noKios` | String | Nomor kios (contoh: A-01) |
| `namaPedagang` | String | Nama pemilik/penyewa kios |
| `jenisJualan` | String | Kategori dagangan |
| `hargaSewa` | Number | Harga sewa per bulan (Rupiah) |
| `status` | String | `aktif`, `kosong`, atau `nonaktif` |
| `zona` | String | Zona kios (A, B, C, D, E) |
| `nomorHp` | String | Nomor telepon pedagang |
| `deskripsi` | String | Deskripsi lengkap kios |
| `tanggalMasuk` | Timestamp | Tanggal pedagang bergabung |

### Koleksi `pembayaran`
Menyimpan riwayat transaksi pembayaran pajak.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `noTransaksi` | String | ID transaksi unik |
| `noKios` | String | Referensi nomor kios |
| `jenisPajak` | String | `harian`, `mingguan`, `bulanan` |
| `jumlah` | Number | Nominal pembayaran (Rupiah) |
| `status` | String | `pending`, `berhasil`, `gagal` |
| `tanggal` | String | Tanggal dan waktu transaksi |
| `metodeBayar` | String | DANA, Transfer, QRIS, Virtual Account |
| `namaPedagang` | String | Nama pedagang saat transaksi |
| `catatan` | String | Catatan opsional dari pedagang |
| `createdAt` | Timestamp | Timestamp server saat data dibuat |

## Jumlah Data

- **Kios**: 25 data (5 zona × 5 kios per zona)
- **Pembayaran**: Bertambah dinamis setiap pedagang melakukan transaksi

## Fitur Utama

1. **Login & Register** — Autentikasi pengguna dengan form validasi
2. **Dashboard** — Ringkasan tagihan, transaksi terakhir dari Firestore (FutureBuilder + loading/error state)
3. **Daftar Kios** — Menampilkan 25+ kios dari Firestore secara real-time menggunakan `StreamBuilder` + `GridView.builder` + filter zona & status + pencarian
4. **Detail Kios** — Halaman detail lengkap per kios dengan navigasi dari daftar
5. **Pembayaran Pajak** — Form pembayaran dengan validasi, data langsung tersimpan ke Cloud Firestore
6. **Riwayat Pembayaran** — Daftar transaksi real-time dari Firestore + `StreamBuilder` + filter status + pencarian
7. **Detail Transaksi** — Halaman detail pembayaran per item
8. **Profil** — Informasi akun + pengaturan notifikasi (setState) + daftar kios dari Firestore
9. **Auto-seed** — Data 25 kios otomatis diisi ke Firestore saat pertama kali aplikasi dijalankan

## Screenshot

> *(Tambahkan screenshot minimal 3 halaman setelah menjalankan aplikasi)*
> 
> 1. Screenshot halaman Daftar Kios
> 2. Screenshot halaman Detail Kios  
> 3. Screenshot halaman Riwayat Pembayaran
> 4. Screenshot halaman Dashboard

## Cara Menjalankan Aplikasi

### Prasyarat
- Flutter SDK ≥ 3.0.0
- Android Studio / VS Code
- Akun Firebase (Google)

### Setup Firebase

1. Buat project baru di [Firebase Console](https://console.firebase.google.com)
2. Tambahkan aplikasi Android:
   - Package name: `com.example.sipesel`
   - Download `google-services.json`
   - Letakkan di `android/app/google-services.json`
3. Aktifkan **Cloud Firestore** di Firebase Console (mode test)
4. Buat index composite di Firestore (jika diminta):
   - Koleksi `pembayaran`: field `noKios` (ASC) + `tanggal` (DESC)

### Menjalankan

```bash
# Clone / extract project
cd sipesel

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### Catatan
- Data 25 kios akan otomatis diisi ke Firestore saat aplikasi pertama kali dijalankan
- Gunakan akun dummy untuk login (sesuaikan dengan backend PHP atau buat akun baru via halaman Register)
- Login menggunakan API PHP (`lib/services/api_service.dart`) — pastikan server XAMPP berjalan dan URL disesuaikan

## Teknologi

- **Framework**: Flutter 3.x
- **Database**: Cloud Firestore (Firebase)
- **Backend Auth**: PHP REST API (XAMPP)
- **State Management**: setState + StreamBuilder + FutureBuilder
- **Package**: `firebase_core`, `cloud_firestore`, `http`, `intl`

---

*Dikembangkan untuk UAS Pemrograman Mobile — Universitas Pembangunan Nasional "Veteran" Jawa Timur*

> **Catatan AI**: Sebagian kode dikembangkan dengan bantuan AI (Claude) sebagai alat bantu untuk struktur Firebase service, model Firestore, dan seed data. Seluruh kode dipahami dan dapat dijelaskan oleh pengembang.
