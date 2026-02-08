import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class EditAlatScreen extends StatefulWidget {
  final Map<String, dynamic> alat;
  const EditAlatScreen({super.key, required this.alat});

  @override
  State<EditAlatScreen> createState() => _EditAlatScreenState();
}

class _EditAlatScreenState extends State<EditAlatScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl, _stokCtrl;
  int? _selectedCatId;
  
  File? _imageFile;
  Uint8List? _webImage;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Mengisi data awal dari widget.alat yang dikirim AlatTab
    _nameCtrl = TextEditingController(text: widget.alat['nama_alat']);
    _stokCtrl = TextEditingController(text: widget.alat['stok_total'].toString());
    _selectedCatId = widget.alat['kategori_id'];
    _imageUrl = widget.alat['foto_url'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  Future<String?> _uploadImage() async {
    // Jika tidak ada perubahan gambar, return URL lama
    if (_imageFile == null && _webImage == null) return _imageUrl;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'public/alat_$timestamp.jpg'; 
      final storage = supabase.storage.from('produk_images');

      if (kIsWeb) {
        await storage.uploadBinary(fileName, _webImage!);
      } else {
        await storage.upload(fileName, _imageFile!);
      }
      return storage.getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Gagal upload: $e");
      return _imageUrl; // Fallback ke URL lama
    }
  }

  void _updateData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        final finalUrl = await _uploadImage();
        
        await supabase.from('alat').update({
          'nama_alat': _nameCtrl.text.trim(),
          'stok_total': int.tryParse(_stokCtrl.text) ?? 0,
          'kategori_id': _selectedCatId,
          'foto_url': finalUrl,
        }).eq('id_alat', widget.alat['id_alat']);

        if (mounted) {
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(content: Text("Berhasil diperbarui"), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Alat", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.darkblue)),
      ),
      body: _isUploading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 150, height: 150,
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: _buildPreview(),
                              ),
                            ),
                            const Positioned(
                              bottom: 5, right: 5, 
                              child: CircleAvatar(backgroundColor: AppColors.darkblue, radius: 18, child: Icon(Icons.edit, color: Colors.white, size: 18))
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _label("Nama"),
                    _inputField(_nameCtrl, "Nama Alat"),
                    _label("Kategori"),
                    _categoryDropdown(),
                    _label("Stok"),
                    _inputField(_stokCtrl, "Jumlah Stok", isNumber: true),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkblue, 
                          padding: const EdgeInsets.all(15), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreview() {
    if (_webImage != null) return Image.memory(_webImage!, fit: BoxFit.cover);
    if (_imageFile != null) return Image.file(_imageFile!, fit: BoxFit.cover);
    if (_imageUrl != null && _imageUrl!.isNotEmpty) return Image.network(_imageUrl!, fit: BoxFit.contain);
    return const Icon(Icons.camera_alt, size: 50);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)));

  Widget _inputField(TextEditingController c, String h, {bool isNumber = false}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.isEmpty ? "Tidak boleh kosong" : null,
      decoration: InputDecoration(hintText: h, filled: true, fillColor: const Color(0xFFF5F8FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
    );
  }

  Widget _categoryDropdown() {
     return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']).order('nama_kategori'),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
          value: _selectedCatId,
          hint: const Text("Pilih Kategori"),
          validator: (v) => v == null ? "Pilih kategori" : null,
          decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF5F8FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          items: list.map((e) => DropdownMenuItem<int>(value: e['id_kategori'], child: Text(e['nama_kategori']))).toList(),
          onChanged: (v) => setState(() => _selectedCatId = v),
        );
      },
    );
  }
}