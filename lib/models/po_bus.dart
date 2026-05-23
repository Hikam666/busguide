class Bus {
  final int id;
  final int idPo;
  final String nomorPolisi;
  final String? tipe; // 'ekonomi' | 'bisnis' | 'eksekutif'
  final int? kapasitas;
  final List<String> fasilitas;
  final String status;

  const Bus({
    required this.id,
    required this.idPo,
    required this.nomorPolisi,
    this.tipe,
    this.kapasitas,
    this.fasilitas = const [],
    this.status = 'aktif',
  });

  factory Bus.fromMap(Map<String, dynamic> map) => Bus(
        id: (map['id'] as num).toInt(),
        idPo: (map['id_po'] as num).toInt(),
        nomorPolisi: map['nomor_polisi'] as String,
        tipe: map['tipe'] as String?,
        kapasitas:
            map['kapasitas'] != null ? (map['kapasitas'] as num).toInt() : null,
        fasilitas: (map['fasilitas'] as List?)?.cast<String>() ?? [],
        status: map['status'] as String? ?? 'aktif',
      );

  /// Capitalize tipe: 'eksekutif' -> 'Eksekutif'
  String get tipeLabel {
    if (tipe == null || tipe!.isEmpty) return '-';
    return tipe![0].toUpperCase() + tipe!.substring(1);
  }

  @override
  String toString() => 'Bus(id: $id, nomorPolisi: $nomorPolisi)';
}

class PoBus {
  final int id;
  final String nama;
  final String? tagline;
  final String? deskripsi;
  final String? logoUrl;

  const PoBus({
    required this.id,
    required this.nama,
    this.tagline,
    this.deskripsi,
    this.logoUrl,
  });

  factory PoBus.fromMap(Map<String, dynamic> map) => PoBus(
        id: (map['id'] as num).toInt(),
        nama: map['nama'] as String,
        tagline: map['tagline'] as String?,
        deskripsi: map['deskripsi'] as String?,
        logoUrl: map['logo_url'] as String?,
      );

  @override
  String toString() => 'PoBus(id: $id, nama: $nama)';
}
