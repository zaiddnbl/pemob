import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kios_model.dart';
import '../models/pembayaran_model.dart';
import '../models/tagihan_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference get _kiosRef => _db.collection('kios');
  static CollectionReference get _pembayaranRef => _db.collection('pembayaran');
  static CollectionReference get _usersRef => _db.collection('users');
  static CollectionReference get _jatuhTempoRef => _db.collection('jatuh_tempo');
  static CollectionReference get _notifikasiRef => _db.collection('notifikasi');
  static CollectionReference get _tagihanRef => _db.collection('tagihan');

  // ══════════════════════════════════════════════════════════
  //  TAGIHAN (harga retribusi)
  // ══════════════════════════════════════════════════════════

  static Future<TagihanModel?> getTagihan() async {
    try {
      final snap = await _tagihanRef.limit(1).get();
      if (snap.docs.isEmpty) {
        // Buat default jika belum ada
        final def = TagihanModel(
          hargaHarian: 5000,
          hargaMingguan: 35000,
          hargaBulanan: 150000,
        );
        final doc = await _tagihanRef.add(def.toFirestore());
        return TagihanModel(
          id: doc.id,
          hargaHarian: def.hargaHarian,
          hargaMingguan: def.hargaMingguan,
          hargaBulanan: def.hargaBulanan,
        );
      }
      return TagihanModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  static Stream<TagihanModel?> streamTagihan() {
    return _tagihanRef.limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return TagihanModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<bool> updateTagihan({
    required String id,
    required double hargaHarian,
    required double hargaMingguan,
    required double hargaBulanan,
  }) async {
    try {
      await _tagihanRef.doc(id).update({
        'hargaHarian': hargaHarian,
        'hargaMingguan': hargaMingguan,
        'hargaBulanan': hargaBulanan,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update global map
      hargaPajak['harian'] = hargaHarian;
      hargaPajak['mingguan'] = hargaMingguan;
      hargaPajak['bulanan'] = hargaBulanan;
      return true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  //  USERS
  // ══════════════════════════════════════════════════════════

  static Future<bool> saveUser(UserModel user) async {
    try {
      // ✅ Tambahkan createdAt saat pertama kali simpan user
      await _usersRef.doc(user.uid).set({
        ...user.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Jika pedagang, set tanggalMasuk di kios
      if (user.role == 'pedagang' && user.noKios.isNotEmpty && user.noKios != '-') {
        final snapKios = await _kiosRef
            .where('noKios', isEqualTo: user.noKios)
            .limit(1)
            .get();
        if (snapKios.docs.isNotEmpty) {
          await snapKios.docs.first.reference.update({
            'status': 'aktif',
            'namaPedagang': user.nama,
            'nomorHp': user.nomorHp,
            'tanggalMasuk': FieldValue.serverTimestamp(),
          });
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getEmailByUsername(String username) async {
    try {
      final snap = await _usersRef
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data() as Map<String, dynamic>;
      return data['email'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateProfil({
    required String uid,
    required String nama,
    required String nomorHp,
    required String gender,
    required String email,
  }) async {
    try {
      await _usersRef.doc(uid).update({
        'nama': nama,
        'nomorHp': nomorHp,
        'gender': gender,
        'email': email,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin: ambil semua user berdasarkan role
  static Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snap =
      await _usersRef.where('role', isEqualTo: role).get();
      return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<UserModel>> streamUsersByRole(String role) {
    return _usersRef
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  static Future<bool> updateUser({
    required String uid,
    required String nama,
    required String email,
    required String nomorHp,
    required String noKios,
    String? oldNoKios, // kios lama untuk dikosongkan
  }) async {
    try {
      // 1. Update data user — HANYA field yang berubah, tidak overwrite semua
      await _usersRef.doc(uid).update({
        'nama': nama,
        'email': email,
        'nomorHp': nomorHp,
        'noKios': noKios,
      });

      // 2. Sinkronisasi kios jika noKios berubah
      if (oldNoKios != null && oldNoKios != noKios && oldNoKios != '-') {
        // Kosongkan kios lama
        final snapLama = await _kiosRef
            .where('noKios', isEqualTo: oldNoKios)
            .limit(1)
            .get();
        if (snapLama.docs.isNotEmpty) {
          await snapLama.docs.first.reference.update({
            'status': 'kosong',
            'namaPedagang': '',
            'nomorHp': '',
          });
        }
      }

      // 3. Aktifkan kios baru dengan nama pedagang
      if (noKios.isNotEmpty && noKios != '-') {
        final userDoc = await _usersRef.doc(uid).get();
        final namaUser = (userDoc.data() as Map<String, dynamic>?)?['nama'] ?? nama;
        final nomorHpUser = (userDoc.data() as Map<String, dynamic>?)?['nomorHp'] ?? nomorHp;

        final snapBaru = await _kiosRef
            .where('noKios', isEqualTo: noKios)
            .limit(1)
            .get();
        if (snapBaru.docs.isNotEmpty) {
          await snapBaru.docs.first.reference.update({
            'status': 'aktif',
            'namaPedagang': namaUser,
            'nomorHp': nomorHpUser,
          });
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Hitung total pedagang
  static Future<int> getTotalPedagang() async {
    try {
      final snap =
      await _usersRef.where('role', isEqualTo: 'pedagang').get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ══════════════════════════════════════════════════════════
  //  KIOS
  // ══════════════════════════════════════════════════════════

  static Stream<List<KiosModel>> streamKios() {
    return _kiosRef
        .orderBy('zona')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => KiosModel.fromFirestore(d)).toList());
  }

  static Future<List<KiosModel>> getKios() async {
    try {
      final snap = await _kiosRef.orderBy('zona').get();
      return snap.docs.map((d) => KiosModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<KiosModel>> getKiosKosong() async {
    try {
      final snap = await _kiosRef
          .where('status', isEqualTo: 'kosong')
          .orderBy('zona')
          .get();
      return snap.docs.map((d) => KiosModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> getTotalKiosAktif() async {
    try {
      final snap =
      await _kiosRef.where('status', isEqualTo: 'aktif').get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<KiosModel?> getKiosByNo(String noKios) async {
    try {
      final snap = await _kiosRef
          .where('noKios', isEqualTo: noKios)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return KiosModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> tambahKios(KiosModel kios) async {
    try {
      await _kiosRef.add(kios.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateKios(String id, KiosModel kios) async {
    try {
      await _kiosRef.doc(id).update(kios.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteKios(String id) async {
    try {
      await _kiosRef.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateStatusKios({
    required String noKios,
    required String status,
    required String namaPedagang,
  }) async {
    try {
      final snap = await _kiosRef
          .where('noKios', isEqualTo: noKios)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({
        'status': status,
        'namaPedagang': namaPedagang,
      });
    } catch (e) {
      // silent
    }
  }

  // ══════════════════════════════════════════════════════════
  //  JATUH TEMPO
  // ══════════════════════════════════════════════════════════

  static Future<DateTime?> getJatuhTempo(String noKios) async {
    try {
      final doc = await _jatuhTempoRef.doc(noKios).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      if (data['jatuhTempo'] == null) return null;
      return (data['jatuhTempo'] as Timestamp).toDate();
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, DateTime?>> getAllJatuhTempo() async {
    try {
      final snap = await _jatuhTempoRef.get();
      final map = <String, DateTime?>{};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final noKios = data['noKios'] as String? ?? doc.id;
        if (data['jatuhTempo'] != null) {
          map[noKios] = (data['jatuhTempo'] as Timestamp).toDate();
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  static Future<void> updateJatuhTempo({
    required String noKios,
    required String jenisPajak,
  }) async {
    try {
      DateTime current = await getJatuhTempo(noKios) ?? DateTime.now();
      if (current.isBefore(DateTime.now())) current = DateTime.now();

      DateTime newJatuhTempo;
      switch (jenisPajak) {
        case 'harian':
          newJatuhTempo = current.add(const Duration(days: 1));
          break;
        case 'mingguan':
          newJatuhTempo = current.add(const Duration(days: 7));
          break;
        case 'bulanan':
          newJatuhTempo =
              DateTime(current.year, current.month + 1, current.day);
          break;
        default:
          newJatuhTempo = current.add(const Duration(days: 1));
      }

      await _jatuhTempoRef.doc(noKios).set({
        'noKios': noKios,
        'jatuhTempo': Timestamp.fromDate(newJatuhTempo),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // silent
    }
  }

  // ══════════════════════════════════════════════════════════
  //  NOTIFIKASI
  // ══════════════════════════════════════════════════════════

  static Future<void> buatNotifikasiVerifikasi({
    required String noKios,
    required String noTransaksi,
    required String jenisPajak,
    required double jumlah,
  }) async {
    try {
      final label = jenisPajak == 'harian'
          ? 'Harian'
          : jenisPajak == 'mingguan'
          ? 'Mingguan'
          : 'Bulanan';
      await _notifikasiRef.add({
        'noKios': noKios,
        'judul': 'Pembayaran Dikonfirmasi ✅',
        'pesan':
        'Pembayaran $label kios $noKios sebesar Rp ${jumlah.toInt()} telah diverifikasi oleh admin.',
        'noTransaksi': noTransaksi,
        'tipe': 'verifikasi',
        'dibaca': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // silent
    }
  }

  static Future<void> buatNotifikasiPenolakan({
    required String noKios,
    required String noTransaksi,
    required String alasan,
  }) async {
    try {
      await _notifikasiRef.add({
        'noKios': noKios,
        'judul': 'Pembayaran Ditolak ❌',
        'pesan': 'Pembayaran kios $noKios ditolak. Alasan: $alasan',
        'noTransaksi': noTransaksi,
        'tipe': 'penolakan',
        'dibaca': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // silent
    }
  }

  static Future<void> buatNotifikasiAdmin({
    required String noKios,
    required String pesan,
  }) async {
    try {
      await _notifikasiRef.add({
        'noKios': noKios,
        'judul': 'Pengingat dari Admin',
        'pesan': pesan,
        'tipe': 'admin',
        'dibaca': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // silent
    }
  }

  static Stream<List<Map<String, dynamic>>> streamNotifikasi(String noKios) {
    return _notifikasiRef
        .where('noKios', isEqualTo: noKios)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {...data, 'id': d.id};
    }).toList());
  }

  static Future<void> tandaiDibaca(String notifId) async {
    try {
      await _notifikasiRef.doc(notifId).update({'dibaca': true});
    } catch (e) {
      // silent
    }
  }

  static Stream<int> streamJumlahBelumDibaca(String noKios) {
    return _notifikasiRef
        .where('noKios', isEqualTo: noKios)
        .where('dibaca', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ══════════════════════════════════════════════════════════
  //  PEMBAYARAN
  // ══════════════════════════════════════════════════════════

  static Stream<List<PembayaranModel>> streamPembayaranByKios(String noKios) {
    return _pembayaranRef
        .where('noKios', isEqualTo: noKios)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => PembayaranModel.fromFirestore(d)).toList());
  }

  static Future<List<PembayaranModel>> getPembayaranByKios(
      String noKios) async {
    try {
      final snap = await _pembayaranRef
          .where('noKios', isEqualTo: noKios)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => PembayaranModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<PembayaranModel>> streamSemuaPembayaran() {
    return _pembayaranRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => PembayaranModel.fromFirestore(d)).toList());
  }

  static Future<List<PembayaranModel>> getSemuaPembayaran() async {
    try {
      final snap = await _pembayaranRef
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => PembayaranModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<PembayaranModel>> getPembayaranByStatus(
      String status) async {
    try {
      final snap = await _pembayaranRef
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => PembayaranModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> tambahPembayaran(PembayaranModel pembayaran) async {
    try {
      await _pembayaranRef.add(pembayaran.toFirestore());
      await updateJatuhTempo(
        noKios: pembayaran.noKios,
        jenisPajak: pembayaran.jenisPajak,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin: approve pembayaran
  static Future<bool> approvePembayaran(String id) async {
    try {
      await _pembayaranRef.doc(id).update({'status': 'berhasil'});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin: reject pembayaran
  static Future<bool> rejectPembayaran({
    required String id,
    required String alasan,
  }) async {
    try {
      await _pembayaranRef.doc(id).update({
        'status': 'ditolak',
        'alasanPenolakan': alasan,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Statistik untuk dashboard
  static Future<Map<String, dynamic>> getStatistikBulanIni() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final snap = await _pembayaranRef
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double totalMasuk = 0;
      int berhasil = 0, pending = 0, ditolak = 0;
      for (final doc in snap.docs) {
        final p = PembayaranModel.fromFirestore(doc);
        if (p.status == 'berhasil') {
          totalMasuk += p.jumlah;
          berhasil++;
        } else if (p.status == 'pending') {
          pending++;
        } else if (p.status == 'ditolak') {
          ditolak++;
        }
      }

      return {
        'totalMasuk': totalMasuk,
        'berhasil': berhasil,
        'pending': pending,
        'ditolak': ditolak,
        'total': snap.docs.length,
      };
    } catch (e) {
      return {
        'totalMasuk': 0.0,
        'berhasil': 0,
        'pending': 0,
        'ditolak': 0,
        'total': 0,
      };
    }
  }

  // ══════════════════════════════════════════════════════════
  //  SEED DATA
  // ══════════════════════════════════════════════════════════

  static Future<bool> isKiosSeeded() async {
    final snap = await _kiosRef.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  static Future<void> seedKios() async {
    final seeded = await isKiosSeeded();
    if (seeded) return;

    final List<Map<String, dynamic>> data = [
      {'noKios': 'A-01', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 500000.0, 'status': 'kosong', 'zona': 'A', 'nomorHp': '', 'deskripsi': 'Kios zona A', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok A No.01', 'tanggalMasuk': null},
      {'noKios': 'A-02', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 450000.0, 'status': 'kosong', 'zona': 'A', 'nomorHp': '', 'deskripsi': 'Kios zona A', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok A No.02', 'tanggalMasuk': null},
      {'noKios': 'A-03', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 550000.0, 'status': 'kosong', 'zona': 'A', 'nomorHp': '', 'deskripsi': 'Kios zona A', 'ukuranKios': '4x4m', 'lokasiKios': 'Lantai 1 Blok A No.03', 'tanggalMasuk': null},
      {'noKios': 'A-04', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 400000.0, 'status': 'kosong', 'zona': 'A', 'nomorHp': '', 'deskripsi': 'Kios zona A', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok A No.04', 'tanggalMasuk': null},
      {'noKios': 'A-05', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 420000.0, 'status': 'kosong', 'zona': 'A', 'nomorHp': '', 'deskripsi': 'Kios zona A', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok A No.05', 'tanggalMasuk': null},
      {'noKios': 'B-01', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 600000.0, 'status': 'kosong', 'zona': 'B', 'nomorHp': '', 'deskripsi': 'Kios zona B', 'ukuranKios': '4x4m', 'lokasiKios': 'Lantai 1 Blok B No.01', 'tanggalMasuk': null},
      {'noKios': 'B-02', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 550000.0, 'status': 'kosong', 'zona': 'B', 'nomorHp': '', 'deskripsi': 'Kios zona B', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok B No.02', 'tanggalMasuk': null},
      {'noKios': 'B-03', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 580000.0, 'status': 'kosong', 'zona': 'B', 'nomorHp': '', 'deskripsi': 'Kios zona B', 'ukuranKios': '3x4m', 'lokasiKios': 'Lantai 1 Blok B No.03', 'tanggalMasuk': null},
      {'noKios': 'B-04', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 550000.0, 'status': 'kosong', 'zona': 'B', 'nomorHp': '', 'deskripsi': 'Kios zona B', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok B No.04', 'tanggalMasuk': null},
      {'noKios': 'B-05', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 500000.0, 'status': 'kosong', 'zona': 'B', 'nomorHp': '', 'deskripsi': 'Kios zona B', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 1 Blok B No.05', 'tanggalMasuk': null},
      {'noKios': 'C-01', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 650000.0, 'status': 'kosong', 'zona': 'C', 'nomorHp': '', 'deskripsi': 'Kios zona C', 'ukuranKios': '4x5m', 'lokasiKios': 'Lantai 2 Blok C No.01', 'tanggalMasuk': null},
      {'noKios': 'C-02', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 520000.0, 'status': 'kosong', 'zona': 'C', 'nomorHp': '', 'deskripsi': 'Kios zona C', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 2 Blok C No.02', 'tanggalMasuk': null},
      {'noKios': 'C-03', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 480000.0, 'status': 'kosong', 'zona': 'C', 'nomorHp': '', 'deskripsi': 'Kios zona C', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 2 Blok C No.03', 'tanggalMasuk': null},
      {'noKios': 'C-04', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 600000.0, 'status': 'kosong', 'zona': 'C', 'nomorHp': '', 'deskripsi': 'Kios zona C', 'ukuranKios': '4x4m', 'lokasiKios': 'Lantai 2 Blok C No.04', 'tanggalMasuk': null},
      {'noKios': 'C-05', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 520000.0, 'status': 'kosong', 'zona': 'C', 'nomorHp': '', 'deskripsi': 'Kios zona C', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 2 Blok C No.05', 'tanggalMasuk': null},
      {'noKios': 'D-01', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 700000.0, 'status': 'kosong', 'zona': 'D', 'nomorHp': '', 'deskripsi': 'Kios zona D', 'ukuranKios': '5x5m', 'lokasiKios': 'Lantai 2 Blok D No.01', 'tanggalMasuk': null},
      {'noKios': 'D-02', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 650000.0, 'status': 'kosong', 'zona': 'D', 'nomorHp': '', 'deskripsi': 'Kios zona D', 'ukuranKios': '4x4m', 'lokasiKios': 'Lantai 2 Blok D No.02', 'tanggalMasuk': null},
      {'noKios': 'D-03', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 600000.0, 'status': 'kosong', 'zona': 'D', 'nomorHp': '', 'deskripsi': 'Kios zona D', 'ukuranKios': '3x4m', 'lokasiKios': 'Lantai 2 Blok D No.03', 'tanggalMasuk': null},
      {'noKios': 'D-04', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 650000.0, 'status': 'kosong', 'zona': 'D', 'nomorHp': '', 'deskripsi': 'Kios zona D', 'ukuranKios': '4x4m', 'lokasiKios': 'Lantai 2 Blok D No.04', 'tanggalMasuk': null},
      {'noKios': 'D-05', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 680000.0, 'status': 'kosong', 'zona': 'D', 'nomorHp': '', 'deskripsi': 'Kios zona D', 'ukuranKios': '4x5m', 'lokasiKios': 'Lantai 2 Blok D No.05', 'tanggalMasuk': null},
      {'noKios': 'E-01', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 450000.0, 'status': 'kosong', 'zona': 'E', 'nomorHp': '', 'deskripsi': 'Kios zona E', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 3 Blok E No.01', 'tanggalMasuk': null},
      {'noKios': 'E-02', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 500000.0, 'status': 'kosong', 'zona': 'E', 'nomorHp': '', 'deskripsi': 'Kios zona E', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 3 Blok E No.02', 'tanggalMasuk': null},
      {'noKios': 'E-03', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 480000.0, 'status': 'kosong', 'zona': 'E', 'nomorHp': '', 'deskripsi': 'Kios zona E', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 3 Blok E No.03', 'tanggalMasuk': null},
      {'noKios': 'E-04', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 450000.0, 'status': 'kosong', 'zona': 'E', 'nomorHp': '', 'deskripsi': 'Kios zona E', 'ukuranKios': '3x3m', 'lokasiKios': 'Lantai 3 Blok E No.04', 'tanggalMasuk': null},
      {'noKios': 'E-05', 'namaPedagang': '', 'jenisJualan': '-', 'hargaSewa': 530000.0, 'status': 'kosong', 'zona': 'E', 'nomorHp': '', 'deskripsi': 'Kios zona E', 'ukuranKios': '3x4m', 'lokasiKios': 'Lantai 3 Blok E No.05', 'tanggalMasuk': null},
    ];

    final batch = _db.batch();
    for (final item in data) {
      final ref = _kiosRef.doc();
      batch.set(ref, item);
    }
    await batch.commit();
  }
}