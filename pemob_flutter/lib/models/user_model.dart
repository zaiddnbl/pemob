import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nama;
  final String username;
  final String email;
  final String nomorHp;
  final String gender;
  final String role;
  final String noKios;

  UserModel({
    required this.uid,
    required this.nama,
    required this.username,
    required this.email,
    required this.nomorHp,
    required this.gender,
    required this.role,
    required this.noKios,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nama: data['nama'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      nomorHp: data['nomorHp'] ?? '',
      gender: data['gender'] ?? '',
      role: data['role'] ?? 'pedagang',
      noKios: data['noKios'] ?? '-',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nama': nama,
    'username': username,
    'email': email,
    'nomorHp': nomorHp,
    'gender': gender,
    'role': role,
    'noKios': noKios,
  };
}

class SessionUser {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static void login(UserModel user) {
    _currentUser = user;
  }

  static void logout() {
    _currentUser = null;
  }
}