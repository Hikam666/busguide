class Notifikasi {
  final int id;
  final int idPerjalanan;
  final String pesan;
  final String tipe; // 'alarm' | 'info' | 'selesai'
  final DateTime dikirimAt;

  const Notifikasi({
    required this.id,
    required this.idPerjalanan,
    required this.pesan,
    required this.tipe,
    required this.dikirimAt,
  });

  factory Notifikasi.fromMap(Map<String, dynamic> map) => Notifikasi(
        id: (map['id'] as num).toInt(),
        idPerjalanan: (map['id_perjalanan'] as num).toInt(),
        pesan: map['pesan'] as String,
        tipe: map['tipe'] as String,
        dikirimAt:
            DateTime.parse(map['dikirim_at'] as String).toLocal(),
      );

  @override
  String toString() => 'Notifikasi(id: $id, tipe: $tipe)';
}
