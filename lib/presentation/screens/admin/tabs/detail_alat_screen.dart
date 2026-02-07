import 'package:flutter/material.dart';

class DetailAlatScreen extends StatelessWidget {
  final Map<String, dynamic> alat;

  const DetailAlatScreen({super.key, required this.alat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Alat")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alat['nama_alat'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("Stok: ${alat['stok_total']}"),
            const SizedBox(height: 10),
            if (alat['foto_url'] != null)
              Image.network(alat['foto_url']),
          ],
        ),
      ),
    );
  }
}
