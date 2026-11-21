import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/laporan_fasilitas.dart';
import '../services/filter_prefs.dart';
import '../services/laporan_repository.dart';

class HomePage extends StatefulWidget {
  final String filterAwal;
  const HomePage({super.key, required this.filterAwal});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = LaporanRepository();
  final _prefs = FilterPrefs();

  late String _filter;
  static const _opsiFilter = ['Semua', ...LaporanRepository.daftarStatus];

  @override
  void initState() {
    super.initState();
    _filter = _opsiFilter.contains(widget.filterAwal)
        ? widget.filterAwal
        : FilterPrefs.defaultFilter;
  }

  Future<void> _gantiFilter(String nilai) async {
    setState(() => _filter = nilai);
    await _prefs.simpan(nilai); 
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Baru':
        return Colors.red;
      case 'Diproses':
        return Colors.orange;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _ikonJenis(String jenis) {
    final j = jenis.toLowerCase();
    if (j.contains('lampu')) return Icons.lightbulb_outline;
    if (j.contains('trotoar')) return Icons.directions_walk;
    if (j.contains('sampah')) return Icons.delete_outline;
    return Icons.report_problem_outlined;
  }

  Future<void> _dialogTambah() async {
    final formKey = GlobalKey<FormState>();
    final kodeC = TextEditingController();
    final jenisC = TextEditingController();
    final lokasiC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Laporan'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: kodeC,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kode (unik)',
                      hintText: 'contoh: SC01',
                    ),
                    validator: _repo.validasiKode,
                  ),
                  TextFormField(
                    controller: jenisC,
                    decoration: const InputDecoration(
                      labelText: 'Jenis',
                      hintText: 'contoh: Lampu jalan mati',
                    ),
                    validator: (v) => _repo.validasiTeks(v, 'Jenis'),
                  ),
                  TextFormField(
                    controller: lokasiC,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      hintText: 'contoh: Jl. Melati',
                    ),
                    validator: (v) => _repo.validasiTeks(v, 'Lokasi'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final error = await _repo.tambah(
                  kode: kodeC.text,
                  jenis: jenisC.text,
                  lokasi: lokasiC.text,
                );
                if (!ctx.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                Navigator.pop(ctx);
                _snack('Laporan ${kodeC.text.trim().toUpperCase()} ditambahkan');
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    kodeC.dispose();
    jenisC.dispose();
    lokasiC.dispose();
  }

  Future<void> _konfirmasiHapus(LaporanFasilitas item) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: Text(
          'Laporan ${item.kode} (${item.jenis}, ${item.lokasi}) '
          'akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await _repo.hapus(item.kode);
      _snack('Laporan ${item.kode} dihapus');
    }
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelaporan Fasilitas Kota')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _dialogTambah,
        icon: const Icon(Icons.add),
        label: const Text('Lapor'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _opsiFilter.map((opsi) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opsi),
                    selected: _filter == opsi,
                    onSelected: (_) => _gantiFilter(opsi),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter aktif: $_filter',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          const Divider(height: 16),

          Expanded(
            child: ValueListenableBuilder<Box<LaporanFasilitas>>(
              valueListenable: _repo.box.listenable(),
              builder: (context, box, _) {
                final semua = box.values.toList()
                  ..sort((a, b) => a.kode.compareTo(b.kode));
                final tampil = _filter == 'Semua'
                    ? semua
                    : semua.where((e) => e.status == _filter).toList();

                if (tampil.isEmpty) {
                  return Center(
                    child: Text(
                      semua.isEmpty
                          ? 'Belum ada laporan.\nTekan tombol "Lapor".'
                          : 'Tidak ada laporan berstatus "$_filter".',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: tampil.length,
                  itemBuilder: (context, i) {
                    final item = tampil[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _warnaStatus(item.status).withOpacity(0.15),
                          child: Icon(_ikonJenis(item.jenis),
                              color: _warnaStatus(item.status)),
                        ),
                        title: Text('${item.kode} - ${item.jenis}'),
                        subtitle: Text(item.lokasi),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Ubah status',
                              initialValue: item.status,
                              onSelected: (s) async {
                                await _repo.ubahStatus(item.kode, s);
                                _snack('${item.kode} diubah menjadi $s');
                              },
                              itemBuilder: (_) => LaporanRepository
                                  .daftarStatus
                                  .map((s) =>
                                      PopupMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              child: Chip(
                                label: Text(item.status),
                                backgroundColor:
                                    _warnaStatus(item.status).withOpacity(0.15),
                                labelStyle: TextStyle(
                                    color: _warnaStatus(item.status)),
                                side: BorderSide.none,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Hapus',
                              onPressed: () => _konfirmasiHapus(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}