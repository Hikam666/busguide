import '../models/halte.dart';
import '../models/perjalanan.dart';

/// Tempat penyimpanan sementara (memory-only) untuk men-support 
/// Navigasi Bebas dengan titik Custom yang tidak bisa di-save ke Supabase (Foreign Key limit).
class TempCache {
  static Halte? customTujuanNavigasi;
  static Perjalanan? inMemoryPerjalanan;
}
