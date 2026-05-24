class UserProfile {
  final String id;
  final String nama;
  final String email;
  final String role; // 'pengguna' | 'admin'
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        nama: map['nama'] as String,
        email: map['email'] as String,
        role: map['role'] as String? ?? 'pengguna',
        avatarUrl: map['avatar_url'] as String?,
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
