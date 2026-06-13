import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
//  api_service.dart
//  Letakkan di: lib/services/api_service.dart
//
//  ⚠️  GANTI baseUrl dengan IP komputer kamu!
//      Cek di CMD: ipconfig → IPv4 Address
//      Contoh: 'http://192.168.1.5/sipesel_api'
//
//      Jika pakai emulator Android bawaan (AVD):
//      gunakan 'http://10.0.2.2/sipesel_api'
// ============================================================

class ApiService {
  // ── Ganti IP ini sesuai komputer kamu ──────────────────────
  static const String baseUrl = 'http://172.20.10.3/sipesel_api';
  // ────────────────────────────────────────────────────────────

  static const Duration _timeout = Duration(seconds: 10);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── Login ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            headers: _headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Register ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String username,
    required String email,
    required String password,
    String nomorHp = '',
    String gender = 'Laki-laki',
    String role = 'pedagang',
    String noKios = '-',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register.php'),
            headers: _headers,
            body: jsonEncode({
              'nama': nama,
              'username': username,
              'email': email,
              'password': password,
              'nomorHp': nomorHp,
              'gender': gender,
              'role': role,
              'noKios': noKios,
            }),
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Ambil semua kios ──────────────────────────────────────
  static Future<Map<String, dynamic>> getKios() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/kios.php'), headers: _headers)
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Ambil satu kios ───────────────────────────────────────
  static Future<Map<String, dynamic>> getKiosById(String noKios) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/kios.php?noKios=$noKios'),
            headers: _headers,
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Ambil riwayat pembayaran per kios ─────────────────────
  static Future<Map<String, dynamic>> getPembayaran(String noKios) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/pembayaran.php?noKios=$noKios'),
            headers: _headers,
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Kirim pembayaran baru ─────────────────────────────────
  static Future<Map<String, dynamic>> buatPembayaran({
    required String noKios,
    required String jenisPajak,
    required double jumlah,
    required String metodeBayar,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/pembayaran.php'),
            headers: _headers,
            body: jsonEncode({
              'noKios': noKios,
              'jenisPajak': jenisPajak,
              'jumlah': jumlah,
              'metodeBayar': metodeBayar,
            }),
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Ambil profil user ─────────────────────────────────────
  static Future<Map<String, dynamic>> getProfil(int idUser) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/profil.php?idUser=$idUser'),
            headers: _headers,
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ── Update profil user ────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfil({
    required int idUser,
    required String nama,
    required String nomorHp,
    required String gender,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/profil.php'),
            headers: _headers,
            body: jsonEncode({
              'idUser': idUser,
              'nama': nama,
              'nomorHp': nomorHp,
              'gender': gender,
            }),
          )
          .timeout(_timeout);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }
}
