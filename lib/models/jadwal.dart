class Jadwal {
  final int id;
  final int idRute;
  final int idBus;
  final String jamBerangkat; // stored as String (time type from DB)
  final List<String> hari;
  final String status;

  const Jadwal({
    required this.id,
    required this.idRute,
    required this.idBus,
    required this.jamBerangkat,
    this.hari = const [],
    this.status = 'aktif',
  });

  factory Jadwal.fromMap(Map<String, dynamic> map) => Jadwal(
        id: (map['id'] as num).toInt(),
        idRute: (map['id_rute'] as num).toInt(),
        idBus: (map['id_bus'] as num).toInt(),
        jamBerangkat: map['jam_berangkat'] as String,
        hari: (map['hari'] as List?)?.cast<String>() ?? [],
        status: map['status'] as String? ?? 'aktif',
      );

  @override
  String toString() => 'Jadwal(id: $id, jam: $jamBerangkat)';
}
