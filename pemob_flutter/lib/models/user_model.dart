class UserModel {
  final int idUser;
  final String nama;
  final String username;
  final String email;
  final String nomorHp;
  final String gender;
  final String role;
  final String noKios;

  UserModel({
    required this.idUser,
    required this.nama,
    required this.username,
    required this.email,
    required this.nomorHp,
    required this.gender,
    required this.role,
    required this.noKios,
  });
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