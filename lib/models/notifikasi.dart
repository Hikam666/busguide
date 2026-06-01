class Notifikasi {
  final int id;
  final int idPerjalanan;
  final String? idPengguna;
  final String? judul;
  final String pesan;
  final String tipe; // 'alarm' | 'info' | 'selesai'
  final DateTime tanggalKirim;
  final bool statusBaca;
  final int? thresholdJarak;

  const Notifikasi({
    required this.id,
    required this.idPerjalanan,
    this.idPengguna,
    this.judul,
    required this.pesan,
    required this.tipe,
    required this.tanggalKirim,
    this.statusBaca = false,
    this.thresholdJarak,
  });

  factory Notifikasi.fromMap(Map<String, dynamic> map) => Notifikasi(
        id: (map['id'] as num).toInt(),
        idPerjalanan: (map['id_perjalanan'] as num).toInt(),
        idPengguna: map['id_pengguna'] as String?,
        judul: map['judul'] as String?,
        pesan: map['pesan'] as String,
        tipe: map['tipe'] as String,
        tanggalKirim: DateTime.parse(map['tanggal_kirim'] as String).toLocal(),
        statusBaca: map['status_baca'] as bool? ?? false,
        thresholdJarak: map['threshold_jarak'] != null ? (map['threshold_jarak'] as num).toInt() : null,
      );

  @override
  String toString() => 'Notifikasi(id: $id, tipe: $tipe)';
}
