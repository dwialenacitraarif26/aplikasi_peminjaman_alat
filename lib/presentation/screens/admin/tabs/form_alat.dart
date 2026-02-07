import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormAlat extends StatefulWidget {
  final Map<String, dynamic>? alat;
  const FormAlat({super.key, this.alat});

  @override
  State<FormAlat> createState() => _FormAlatState();
}

class _FormAlatState extends State<FormAlat> {
  final supabase = Supabase.instance.client;
  final namaCtrl = TextEditingController();
  final stokCtrl = TextEditingController();
  int? kategoriId;

  @override
  void initState() {
    super.initState();
    if (widget.alat != null) {
      namaCtrl.text = widget.alat!['nama_alat'];
      stokCtrl.text = widget.alat!['stok_total'].toString();
      kategoriId = widget.alat!['kategori_id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: namaCtrl,
            decoration: const InputDecoration(labelText: 'Nama Alat'),
          ),
          TextField(
            controller: stokCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stok'),
          ),

          const SizedBox(height: 10),

          /// DROPDOWN KATEGORI
          StreamBuilder(
            stream: supabase
                .from('kategori')
                .stream(primaryKey: ['id_kategori']),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              return DropdownButtonFormField<int>(
                value: kategoriId,
                hint: const Text('Pilih Kategori'),
                items: list
                    .map<DropdownMenuItem<int>>(
                      (e) => DropdownMenuItem(
                        value: e['id_kategori'],
                        child: Text(e['nama_kategori']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => kategoriId = v),
              );
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _simpan,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    final data = {
      'nama_alat': namaCtrl.text,
      'stok_total': int.parse(stokCtrl.text),
      'kategori_id': kategoriId,
    };

    if (widget.alat == null) {
      await supabase.from('alat').insert(data);
    } else {
      await supabase
          .from('alat')
          .update(data)
          .eq('id_alat', widget.alat!['id_alat']);
    }

    if (mounted) Navigator.pop(context);
  }
}
