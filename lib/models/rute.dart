import 'halte.dart';

class TitikRute {
  final int urutan;
  final double latitude;
  final double longitude;

  const TitikRute({
    required this.urutan,
    required this.latitude,
    required this.longitude,
  });

  factory TitikRute.fromMap(Map<String, dynamic> map) => TitikRute(
        urutan: (map['urutan'] as num).toInt(),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
}

class RuteHalte {
  final int urutan;
  final double? jarakMeter;
  final Halte halte;

  const RuteHalte({
    required this.urutan,
    this.jarakMeter,
    required this.halte,
  });

  factory RuteHalte.fromMap(Map<String, dynamic> map) => RuteHalte(
        urutan: (map['urutan'] as num).toInt(),
        jarakMeter: map['jarak_meter'] != null
            ? (map['jarak_meter'] as num).toDouble()
            : null,
        halte: Halte.fromMap(map['halte'] as Map<String, dynamic>),
      );
}

class Rute {
  final int id;
  final String kode;
  final String nama;
  final String statusOperasi; // 'aktif' | 'tidak_aktif'
  final Halte? terminalAwal;
  final Halte? terminalAkhir;

  const Rute({
    required this.id,
    required this.kode,
    required this.nama,
    this.statusOperasi = 'aktif',
    this.terminalAwal,
    this.terminalAkhir,
  });

  factory Rute.fromMap(Map<String, dynamic> map) => Rute(
        id: (map['id'] as num).toInt(),
        kode: map['kode'] as String,
        nama: map['nama'] as String,
        statusOperasi: map['status_operasi'] as String? ?? 'aktif',
        terminalAwal: map['terminal_awal'] != null
            ? Halte.fromMap(map['terminal_awal'] as Map<String, dynamic>)
            : null,
        terminalAkhir: map['terminal_akhir'] != null
            ? Halte.fromMap(map['terminal_akhir'] as Map<String, dynamic>)
            : null,
      );

  @override
  String toString() => 'Rute(id: $id, kode: $kode, nama: $nama)';
}
