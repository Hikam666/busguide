import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/detail_po_bus_controller.dart';
import '../models/po_bus.dart';
import '../core/theme/app_colors.dart';

class DetailPoBusScreen extends StatefulWidget {
  final int idPoBus;
  const DetailPoBusScreen({super.key, required this.idPoBus});

  @override
  State<DetailPoBusScreen> createState() => _DetailPoBusScreenState();
}

class _DetailPoBusScreenState extends State<DetailPoBusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailPoBusController>().loadData(widget.idPoBus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Consumer<DetailPoBusController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (ctrl.error != null) {
            return _BagianError(
                pesan: ctrl.error!,
                onRetry: () => ctrl.loadData(widget.idPoBus));
          }
          return _buildContent(ctrl.poBus!, ctrl.armadaList);
        },
      ),
    );
  }

  Widget _buildContent(PoBus po, List<Bus> armadaList) {
    // 1. Group buses by type for "Kelas bus"
    final Map<String, List<Bus>> groupedBuses = {};
    for (var bus in armadaList) {
      final tipe = bus.tipe ?? 'ekonomi';
      groupedBuses.putIfAbsent(tipe, () => []).add(bus);
    }
    if (groupedBuses.isEmpty) {
      groupedBuses['eksekutif'] = [];
      groupedBuses['bisnis'] = [];
    }

    final sortedKeys = [
      if (groupedBuses.containsKey('eksekutif')) 'eksekutif',
      if (groupedBuses.containsKey('bisnis')) 'bisnis',
      if (groupedBuses.containsKey('ekonomi')) 'ekonomi',
      ...groupedBuses.keys.where((k) => k != 'eksekutif' && k != 'bisnis' && k != 'ekonomi')
    ];

    // 2. Gather unique facilities for "Fasilitas armada"
    final List<String> allFacilities = [];
    for (var bus in armadaList) {
      for (var f in bus.fasilitas) {
        if (!allFacilities.contains(f)) {
          allFacilities.add(f);
        }
      }
    }
    if (po.fasilitas != null) {
      for (var f in po.fasilitas!.split(',')) {
        final trimmed = f.trim();
        if (trimmed.isNotEmpty && !allFacilities.contains(trimmed)) {
          allFacilities.add(trimmed);
        }
      }
    }
    if (allFacilities.length < 4) {
      final defaults = ['AC', 'WiFi', 'Toilet', 'Meal Service'];
      for (var d in defaults) {
        if (!allFacilities.contains(d)) {
          allFacilities.add(d);
        }
      }
    }

    // 3. Serviced routes
    final routes = _getPoRoutes(po.nama);

    return CustomScrollView(
      slivers: [
        const _SliverHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centered circular logo avatar with overlapping verified badge
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: po.logoUrl != null
                                  ? Image.network(
                                      po.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const _LogoPlaceholder(),
                                    )
                                  : const _LogoPlaceholder(),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        po.nama.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (po.tagline != null && po.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          po.tagline!,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Grey card for description & contact details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (po.deskripsi != null)
                        Text(
                          po.deskripsi!,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (po.kontak != null && po.kontak!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF4B5563)),
                                    const SizedBox(width: 6),
                                    Text(
                                      po.kontak!,
                                      style: const TextStyle(
                                        fontFamily: 'DMSans',
                                        fontSize: 12,
                                        color: Color(0xFF4B5563),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language_rounded, size: 14, color: Color(0xFF4B5563)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${po.nama.toLowerCase().replaceAll(' ', '')}-indah.co.id',
                                    style: const TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 12,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Kelas Bus Section
                Row(
                  children: [
                    const Icon(Icons.airline_seat_recline_normal_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Kelas bus',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: sortedKeys.map((key) {
                      final isFirst = sortedKeys.indexOf(key) == 0;
                      return _buildClassCard(key, isFirst);
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Fasilitas Armada Section
                Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Fasilitas armada',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: allFacilities.map((f) {
                    final width = (MediaQuery.of(context).size.width - 48 - 12) / 2;
                    return Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getArmadaFacilityIcon(f),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BagianError extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _BagianError({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFF6B7280), size: 40),
          const SizedBox(height: 12),
          Text(pesan,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  const _SliverHeader();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFF9FAFC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'BusGuide',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.directions_bus_rounded,
        color: Color(0xFF9CA3AF), size: 48);
  }
}

Widget _buildClassCard(String type, bool isPrimary) {
  String label = '';
  String price = '';
  String desc = '';

  switch (type.toLowerCase()) {
    case 'eksekutif':
      label = 'FIRST CLASS';
      price = 'Rp 525rb';
      desc = 'Sleeper Seat & Personal Screen';
      break;
    case 'bisnis':
      label = 'SUPER TOP';
      price = 'Rp 385rb';
      desc = 'Seat 2-1 & Leg Rest';
      break;
    case 'ekonomi':
      label = 'ECONOMY';
      price = 'Rp 180rb';
      desc = 'AC & Seat 2-2 & Toilet';
      break;
    default:
      label = type.toUpperCase();
      price = 'Rp 250rb';
      desc = 'AC & WiFi & Reclining Seat';
  }

  final accentColor = isPrimary ? AppColors.primary : const Color(0xFF1A1A2E);
  final borderColor = isPrimary ? AppColors.primary : const Color(0xFFE5E7EB);
  final borderWidth = isPrimary ? 1.5 : 1.0;

  return Container(
    width: 170,
    height: 110,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isPrimary ? AppColors.primary : const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

IconData _getArmadaFacilityIcon(String facility) {
  final lower = facility.toLowerCase();
  if (lower.contains('ac')) return Icons.ac_unit_rounded;
  if (lower.contains('wifi')) return Icons.wifi_rounded;
  if (lower.contains('toilet') || lower.contains('wc')) return Icons.wc_rounded;
  if (lower.contains('meal') || lower.contains('makan') || lower.contains('service')) return Icons.flatware_rounded;
  if (lower.contains('charger') || lower.contains('usb')) return Icons.power_rounded;
  if (lower.contains('tv') || lower.contains('lcd')) return Icons.tv_rounded;
  if (lower.contains('selimut')) return Icons.bed_rounded;
  return Icons.star_border_rounded;
}

List<Map<String, String>> _getPoRoutes(String poName) {
  final name = poName.toLowerCase();
  if (name.contains('akas')) {
    return [
      {'asal': 'Malang', 'tujuan': 'Surabaya', 'jadwal': 'Berangkat 07:00, 11:30, 16:00'},
      {'asal': 'Malang', 'tujuan': 'Probolinggo', 'jadwal': 'Berangkat 08:30, 14:00, 18:30'},
    ];
  } else if (name.contains('arjuna')) {
    return [
      {'asal': 'Batu', 'tujuan': 'Kota Malang', 'jadwal': 'Berangkat 07:00, 15:30, 19:00'},
      {'asal': 'Batu', 'tujuan': 'Selecta', 'jadwal': 'Berangkat 08:30, 20:00'},
    ];
  } else if (name.contains('damri')) {
    return [
      {'asal': 'Malang', 'tujuan': 'Bandara Juanda', 'jadwal': 'Berangkat 04:00, 06:00, 08:00, 10:00'},
      {'asal': 'Malang', 'tujuan': 'Surabaya', 'jadwal': 'Berangkat 05:30, 12:00, 17:30'},
    ];
  } else if (name.contains('lestari')) {
    return [
      {'asal': 'Malang', 'tujuan': 'Kepanjen', 'jadwal': 'Berangkat 06:00, 09:30, 13:00, 18:00'},
      {'asal': 'Malang', 'tujuan': 'Blitar', 'jadwal': 'Berangkat 07:30, 14:30'},
    ];
  } else if (name.contains('tentrem')) {
    return [
      {'asal': 'Malang', 'tujuan': 'Surabaya', 'jadwal': 'Berangkat 05:00, 08:00, 11:00, 14:00, 17:00'},
      {'asal': 'Malang', 'tujuan': 'Jember', 'jadwal': 'Berangkat 06:30, 13:30, 19:00'},
    ];
  } else {
    return [
      {'asal': 'Batu', 'tujuan': 'Kota Malang', 'jadwal': 'Berangkat 07:00, 15:30, 19:00'},
      {'asal': 'Batu', 'tujuan': 'Selecta', 'jadwal': 'Berangkat 08:30, 20:00'},
    ];
  }
}