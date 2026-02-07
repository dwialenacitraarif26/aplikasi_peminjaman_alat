import 'package:flutter/material.dart';

class EditAlatScreen extends StatelessWidget {
  final Map<String, dynamic> alat;

  const EditAlatScreen({super.key, required this.alat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Alat")),
      body: Center(
        child: Text("Edit: ${alat['nama_alat']}"),
      ),
    );
  }
}

