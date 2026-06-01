class UserProfile {
  final String id;
  final String nama;
  final String email;
  final String role; // 'pengguna' | 'admin'
  final String? avatarUrl;
  final String? noHp;
  final String? alamat;
  final String statusAkun;
  final DateTime? lastLogin;

  const UserProfile({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.noHp,
    this.alamat,
    this.statusAkun = 'aktif',
    this.lastLogin,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        nama: map['nama'] as String,
        email: map['email'] as String,
        role: map['role'] as String? ?? 'pengguna',
        avatarUrl: map['avatar_url'] as String?,
        noHp: map['no_hp'] as String?,
        alamat: map['alamat'] as String?,
        statusAkun: map['status_akun'] as String? ?? 'aktif',
        lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login'] as String).toLocal() : null,
      );

  bool get isAdmin => role == 'admin';

  /// Inisial dari nama: 'Muhammad Hikam' -> 'MH'
  String get initials {
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nama[0].toUpperCase();
  }

  @override
  String toString() => 'UserProfile(id: $id, nama: $nama, role: $role)';
}
