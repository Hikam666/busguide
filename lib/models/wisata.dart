class Wisata {
  final int id;
  final String nama;
  final String? alamat;
  final String? kota;
  final String? deskripsi;
  final int? tarif;
  final String? jamBuka; // stored as String from DB time type
  final String? jamTutup;
  final String? fotoUrl;

  const Wisata({
    required this.id,
    required this.nama,
    this.alamat,
    this.kota,
    this.deskripsi,
    this.tarif,
    this.jamBuka,
    this.jamTutup,
    this.fotoUrl,
  });

  factory Wisata.fromMap(Map<String, dynamic> map) => Wisata(
        id: (map['id'] as num).toInt(),
        nama: map['nama'] as String,
        alamat: map['alamat'] as String?,
        kota: map['kota'] as String?,
        deskripsi: map['deskripsi'] as String?,
        tarif: map['tarif'] != null ? (map['tarif'] as num).toInt() : null,
        jamBuka: map['jam_buka'] as String?,
        jamTutup: map['jam_tutup'] as String?,
        fotoUrl: map['foto_url'] as String?,
      );

  /// Format tarif: 25000 -> '25.000'
  String get tarifFormatted {
    if (tarif == null) return '-';
    return tarif!.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  String toString() => 'Wisata(id: $id, nama: $nama)';
}
