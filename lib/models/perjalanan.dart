import 'halte.dart';
import 'rute.dart';

class RiwayatPerjalanan {
  final int id;
  final int idPerjalanan;
  final int? durasiMenit;
  final int? estimasiBiaya;
  final String? catatan;

  const RiwayatPerjalanan({
    required this.id,
    required this.idPerjalanan,
    this.durasiMenit,
    this.estimasiBiaya,
    this.catatan,
  });

  factory RiwayatPerjalanan.fromMap(Map<String, dynamic> map) =>
      RiwayatPerjalanan(
        id: (map['id'] as num).toInt(),
        idPerjalanan: (map['id_perjalanan'] as num).toInt(),
        durasiMenit: map['durasi_menit'] != null
            ? (map['durasi_menit'] as num).toInt()
            : null,
        estimasiBiaya: map['estimasi_biaya'] != null
            ? (map['estimasi_biaya'] as num).toInt()
            : null,
        catatan: map['catatan'] as String?,
      );

  /// Format durasi: 75 menit -> '1j 15m'
  String? get durasiLabel {
    if (durasiMenit == null) return null;
    final jam = durasiMenit! ~/ 60;
    final sisa = durasiMenit! % 60;
    if (jam > 0 && sisa > 0) return '${jam}j ${sisa}m';
    if (jam > 0) return '${jam}j';
    return '${sisa}m';
  }
}

class Perjalanan {
  final int id;
  final String status; // 'aktif' | 'selesai' | 'dibatalkan'
  final DateTime waktuMulai;
  final DateTime? waktuSelesai;
  final bool alarmAktif;
  final double? jarak;
  final Rute? rute;
  final Halte? halteAsal;
  final Halte? halteTujuan;
  final List<RiwayatPerjalanan> riwayat;

  const Perjalanan({
    required this.id,
    required this.status,
    required this.waktuMulai,
    this.waktuSelesai,
    required this.alarmAktif,
    this.jarak,
    this.rute,
    this.halteAsal,
    this.halteTujuan,
    this.riwayat = const [],
  });

  Perjalanan copyWith({
    bool? alarmAktif,
  }) {
    return Perjalanan(
      id: id,
      status: status,
      waktuMulai: waktuMulai,
      waktuSelesai: waktuSelesai,
      alarmAktif: alarmAktif ?? this.alarmAktif,
      jarak: jarak,
      rute: rute,
      halteAsal: halteAsal,
      halteTujuan: halteTujuan,
      riwayat: riwayat,
    );
  }

  factory Perjalanan.fromMap(Map<String, dynamic> map) {
    // Parse riwayat_perjalanan (bisa List atau Map)
    List<RiwayatPerjalanan> riwayat = [];
    final rawRiwayat = map['riwayat_perjalanan'];
    if (rawRiwayat is List) {
      riwayat = rawRiwayat
          .whereType<Map<String, dynamic>>()
          .map(RiwayatPerjalanan.fromMap)
          .toList();
    } else if (rawRiwayat is Map<String, dynamic>) {
      riwayat = [RiwayatPerjalanan.fromMap(rawRiwayat)];
    }

    return Perjalanan(
      id: (map['id'] as num).toInt(),
      status: map['status'] as String? ?? 'aktif',
      waktuMulai: DateTime.parse(map['waktu_mulai'] as String).toLocal(),
      waktuSelesai: map['waktu_selesai'] != null
          ? DateTime.parse(map['waktu_selesai'] as String).toLocal()
          : null,
      alarmAktif: map['alarm_aktif'] as bool? ?? false,
      jarak: map['jarak'] != null ? (map['jarak'] as num).toDouble() : null,
      rute: map['rute'] != null
          ? Rute.fromMap(map['rute'] as Map<String, dynamic>)
          : null,
      halteAsal: map['halte_asal'] != null
          ? Halte.fromMap(map['halte_asal'] as Map<String, dynamic>)
          : null,
      halteTujuan: map['halte_tujuan'] != null
          ? Halte.fromMap(map['halte_tujuan'] as Map<String, dynamic>)
          : null,
      riwayat: riwayat,
    );
  }

  /// Trip ID display: 'TR-000001'
  String get tripId => 'TR-${id.toString().padLeft(6, '0')}';

  /// Nama PO dari nested data
  String get namaPO {
    try {
      return rute?.kode ?? 'Bus';
    } catch (_) {
      return 'Bus';
    }
  }

  /// Format waktu mulai untuk display
  String get waktuMulaiFormatted => _formatDateTime(waktuMulai);
  String get waktuSelesaiFormatted =>
      waktuSelesai != null ? _formatDateTime(waktuSelesai!) : '-';

  static String _formatDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} • $hour:$min WIB';
  }

  @override
  String toString() => 'Perjalanan(id: $id, status: $status)';
}
