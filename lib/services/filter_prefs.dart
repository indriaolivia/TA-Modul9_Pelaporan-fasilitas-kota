import 'package:shared_preferences/shared_preferences.dart';

class FilterPrefs {
  static const String kunci = 'filter_status_laporan';
  static const String defaultFilter = 'Semua';

  Future<String> baca() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kunci) ?? defaultFilter;
  }

  Future<void> simpan(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kunci, filter);
  }
}