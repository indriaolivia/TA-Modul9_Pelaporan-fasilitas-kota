import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/laporan_fasilitas.dart';
import 'pages/home_page.dart';
import 'services/filter_prefs.dart';
import 'services/laporan_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LaporanFasilitasAdapter());
  await Hive.openBox<LaporanFasilitas>(LaporanRepository.boxName);

  final filterAwal = await FilterPrefs().baca();

  runApp(MyApp(filterAwal: filterAwal));
}

class MyApp extends StatelessWidget {
  final String filterAwal;
  const MyApp({super.key, required this.filterAwal});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelaporan Fasilitas Kota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: HomePage(filterAwal: filterAwal),
    );
  }
}