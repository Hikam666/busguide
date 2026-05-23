class Halte {
  final int id;
  final String nama;
  final String tipe; // 'halte' | 'terminal'
  final String? alamat;
  final double latitude;
  final double longitude;
  final double? jarakMeter; // computed field saat tampil dengan jarak

  const Halte({
    required this.id,
    required this.nama,
    required this.tipe,
    this.alamat,
    required this.latitude,
    required this.longitude,
    this.jarakMeter,
  });

  factory Halte.fromMap(Map<String, dynamic> map) => Halte(
        id: (map['id'] as num).toInt(),
        nama: map['nama'] as String,
        tipe: map['tipe'] as String,
        alamat: map['alamat'] as String?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'tipe': tipe,
        'alamat': alamat,
        'latitude': latitude,
        'longitude': longitude,
      };

  Halte withJarak(double jarak) => Halte(
        id: id,
        nama: nama,
        tipe: tipe,
        alamat: alamat,
        latitude: latitude,
        longitude: longitude,
        jarakMeter: jarak,
      );

  @override
  String toString() => 'Halte(id: $id, nama: $nama)';
}
