## 1. Nama aplikasi : SIPESEL (Sistem Pembayaran Retribusi Elektronik)
## 2. Nama dan NPM anggota kelompok :
   - Muhammad Zaidan Nabil       24082010007
   - Najwa Wahida Almaira K      24082010020
   - Hilwatul Maghfiroh          24082010029
   - Rinda Alisya Putri          24082010031
   - Nayyara Ramadhana Qudsia    24082010034
     
## 3. Tema aplikasi :
    Aplikasi Manajemen Tugas / Operasional — diimplementasikan sebagai sistem pengelolaan sewa kios dan retribusi pasar.
   
## 4. Deskripsi singkat aplikasi :
   SIPESEL adalah aplikasi mobile berbasis Flutter untuk mengelola pembayaran retribusi sewa kios di Pasar Wadungasri, 
   Sidoarjo. Aplikasi ini melibatkan tiga peran pengguna: **Pedagang** (membayar retribusi dan memantau status kios), 
   **Admin** (mengelola data pedagang, kios, tagihan, dan verifikasi pembayaran), dan **Pengawas** (memantau aktivitas 
   pembayaran dan menghasilkan laporan). Seluruh data aplikasi tersimpan dan diambil secara real-time dari Cloud Firestore.
   
## 5. Jenis Firebase yang digunakan: 
    **Cloud Firestore**
    Aplikasi menggunakan `firebase_core` untuk inisialisasi, `firebase_auth` untuk autentikasi pengguna, 
    dan `cloud_firestore` untuk penyimpanan dan pengambilan data secara real-time melalui `StreamBuilder`.

## 6. Struktur koleksi atau node Firebase.

### 1. `users` - Menyimpan data akun pengguna (pedagang, admin, pengawas).
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

### 2. `kios` - Menyimpan data kios di pasar.
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

### 3. `pembayaran` Menyimpan riwayat transaksi pembayaran retribusi.
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

### 4. `tagihan` - Menyimpan konfigurasi harga retribusi yang dapat diubah admin.
| Field | Tipe | Keterangan |
|-------|------|------------|
| hargaHarian | Number | Tarif retribusi harian |
| hargaMingguan | Number | Tarif retribusi mingguan |
| hargaBulanan | Number | Tarif retribusi bulanan |
| updatedAt | Timestamp | Waktu terakhir diubah |

## 5. Jumlah Data yang Digunakan
- Koleksi `kios`: 20+ dokumen kios di berbagai zona (A–E)
- Koleksi `pembayaran`: 20+ dokumen transaksi dengan berbagai status
- Koleksi `users`: data akun untuk pedagang, admin, dan pengawas
- Koleksi `tagihan`: 1 dokumen konfigurasi harga aktif

## 6. Fitur utama aplikasi
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

## 9. Screenshot minimal 3 halaman.
  - Halaman Login <img width="714" height="1599" alt="WhatsApp Image 2026-06-18 at 22 56 57" src="https://github.com/user-attachments/assets/3cf5fe25-c3f7-45bb-bc6d-5723de2be79a" />
  - Dashboard Pengawas <img width="714" height="1599" alt="WhatsApp Image 2026-06-18 at 22 56 57 (1)" src="https://github.com/user-attachments/assets/3ead1fad-57df-4bc0-b97a-3db8bd890d54" />
  - Pembayaran Retribusi <img width="720" height="1612" alt="WhatsApp Image 2026-06-18 at 22 56 58" src="https://github.com/user-attachments/assets/bad1a422-5507-4c3e-be5f-492dbf5dab46" />
  - Tambah User by Admin <img width="720" height="1612" alt="WhatsApp Image 2026-06-18 at 22 56 58 (1)" src="https://github.com/user-attachments/assets/ef0f9eb1-7e80-42fa-8d31-145c84f37514" />

## 10. Cara menjalankan aplikasi
    1. Clone repository ini: 
    https://github.com/zaiddnbl/pemob.git 
    2. Masuk ke folder project: 
    cd sipesel
    3. Install dependencies:
    flutter pub get
    4. Pastikan file konfigurasi Firebase (`google-services.json` untuk Android) sudah ditempatkan di `android/app/`.
    5. Jalankan aplikasi:
    flutter run

## Keterangan Penggunaan AI
  Dalam pengembangan proyek ini, AI (Claude oleh Anthropic) digunakan sebagai alat bantu untuk:
  - Membantu debugging error pada kode Flutter
  - Memberikan referensi implementasi `StreamBuilder` dan integrasi Cloud Firestore
  - Menyusun struktur koleksi Firestore
  - Membantu perbaikan tampilan UI agar sesuai kriteria UAS
  
  Seluruh kode yang dihasilkan telah dipahami dan diverifikasi oleh anggota kelompok sebelum dikumpulkan.
