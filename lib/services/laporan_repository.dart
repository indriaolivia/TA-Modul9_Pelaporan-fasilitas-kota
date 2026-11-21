import 'package:hive/hive.dart';
import '../models/laporan_fasilitas.dart';

class LaporanRepository {
  static const String boxName = 'laporanFasilitasBox';
  static const List<String> daftarStatus = ['Baru', 'Diproses', 'Selesai'];

  Box<LaporanFasilitas> get box => Hive.box<LaporanFasilitas>(boxName);

  static String normalisasiKode(String kode) => kode.trim().toUpperCase();

  String? validasiKode(String? value) {
    final kode = normalisasiKode(value ?? '');
    if (kode.isEmpty) return 'Kode tidak boleh kosong';
    if (box.containsKey(kode)) return 'Kode $kode sudah digunakan';
    return null;
  }

  String? validasiTeks(String? value, String namaField) {
    if (value == null || value.trim().isEmpty) {
      return '$namaField tidak boleh kosong';
    }
    return null;
  }

  Future<String?> tambah({
    required String kode,
    required String jenis,
    required String lokasi,
  }) async {
    final kodeFix = normalisasiKode(kode);
    if (kodeFix.isEmpty) return 'Kode tidak boleh kosong';
    if (jenis.trim().isEmpty) return 'Jenis tidak boleh kosong';
    if (lokasi.trim().isEmpty) return 'Lokasi tidak boleh kosong';
    if (box.containsKey(kodeFix)) return 'Kode $kodeFix sudah digunakan';

    await box.put(
      kodeFix, 
      LaporanFasilitas(
        kode: kodeFix,
        jenis: jenis.trim(),
        lokasi: lokasi.trim(),
        status: 'Baru',
      ),
    );
    return null;
  }

  Future<void> ubahStatus(String kode, String statusBaru) async {
    final lama = box.get(kode);
    if (lama == null) return;
    await box.put(kode, lama.copyWith(status: statusBaru));
  }

  Future<void> hapus(String kode) => box.delete(kode);
}

