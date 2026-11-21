import 'package:hive/hive.dart';

class LaporanFasilitas {
  final String kode;
  final String jenis;
  final String lokasi;
  final String status; 

  const LaporanFasilitas({
    required this.kode,
    required this.jenis,
    required this.lokasi,
    required this.status,
  });

  LaporanFasilitas copyWith({String? jenis, String? lokasi, String? status}) {
    return LaporanFasilitas(
      kode: kode, 
      jenis: jenis ?? this.jenis,
      lokasi: lokasi ?? this.lokasi,
      status: status ?? this.status,
    );
  }
}

class LaporanFasilitasAdapter extends TypeAdapter<LaporanFasilitas> {
  @override
  final int typeId = 0;

  @override
  LaporanFasilitas read(BinaryReader reader) {
    return LaporanFasilitas(
      kode: reader.readString(),
      jenis: reader.readString(),
      lokasi: reader.readString(),
      status: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, LaporanFasilitas obj) {
    writer
      ..writeString(obj.kode)
      ..writeString(obj.jenis)
      ..writeString(obj.lokasi)
      ..writeString(obj.status);
  }
}
