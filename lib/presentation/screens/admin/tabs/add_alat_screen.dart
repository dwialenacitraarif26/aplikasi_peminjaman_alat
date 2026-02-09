import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class AddAlatScreen extends StatefulWidget {
  final Map<String, dynamic>? alat;
  const AddAlatScreen({super.key, this.alat});

  @override
  State<AddAlatScreen> createState() => _AddAlatScreenState();
}

class _AddAlatScreenState extends State<AddAlatScreen> {
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
    _nameCtrl = TextEditingController(text: widget.alat?['nama_alat']);
    _stokCtrl = TextEditingController(text: widget.alat?['stok_total']);
    _selectedCatId = widget.alat?['kategori_id'];
    _imageUrl = widget.alat?['foto_url'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }
Future<String?> _uploadToStorage() async {
  if (_imageFile == null && _webImage == null) return _imageUrl;
  
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Deteksi ekstensi asli
    String ext = 'png'; 
    if (!kIsWeb && _imageFile != null) {
      ext = _imageFile!.path.split('.').last.toLowerCase();
    }

    // NAMA FILE: Langsung tanpa folder 'public/' karena policy sudah diubah
    final fileName = 'public/alat_$timestamp.$ext'; 
    final storage = supabase.storage.from('produk_images');

    final fileOptions = FileOptions(
      contentType: 'image/$ext', 
      upsert: true
    );

    // Proses Upload
    if (kIsWeb) {
      await storage.uploadBinary(fileName, _webImage!, fileOptions: fileOptions);
    } else {
      await storage.upload(fileName, _imageFile!, fileOptions: fileOptions);
    }
    
    // PENTING: Ambil URL Publik lengkap untuk disimpan di tabel database
    final String rawUrl = storage.getPublicUrl(fileName);
    
    // Tambahkan t=timestamp untuk menghindari cache lama di aplikasi
    return "$rawUrl?t=$timestamp";
  } catch (e) {
    debugPrint("Gagal upload: $e");
    return _imageUrl;
  }
}

void _saveData() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isUploading = true);
    
    // Simpan context messenger sebelum Navigator.pop
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final finalImageUrl = await _uploadToStorage();
      bool isEdit = widget.alat != null;
      
      final data = {
        'nama_alat': _nameCtrl.text.trim(), 
        'stok_total': int.parse(_stokCtrl.text), 
        'kategori_id': _selectedCatId,
        'foto_url': finalImageUrl, // URL lengkap hasil upload
      };
      
      if (isEdit) {
        await supabase.from('alat').update(data).eq('id_alat', widget.alat!['id_alat']);
      } else {
        await supabase.from('alat').insert(data);
      }
      
      if (mounted) {
        Navigator.pop(context); // Tutup halaman
        
        // Tampilkan snackbar di halaman daftar (AlatTab)
        messenger.showSnackBar(
          SnackBar(
            content: Text(isEdit ? "Alat berhasil diubah" : "Alat berhasil ditambah"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan data"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.alat != null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isUploading 
      ? const Center(child: CircularProgressIndicator(color: AppColors.darkblue))
      : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
                      ),
                      Expanded(
                        child: Text(
                          isEdit ? "Edit Alat" : "Tambah Alat",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkblue),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// UPLOAD BOX PREVIEW
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.darkblue.withValues(alpha: 0.1)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  _label("Nama"),
                  _textField(_nameCtrl, "Masukkan nama barang"),
                  
                  _label("Kategori"),
                  _categoryDropdown(),
                  
                  _label("Stok"),
                  _textField(_stokCtrl, "0", isNumber: true),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkblue, 
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(
                        isEdit ? "Simpan Perubahan" : "Tambahkan", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(_imageUrl!, fit: BoxFit.contain);
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 50, color: AppColors.darkblue),
          SizedBox(height: 8),
        ],
      );
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 15), 
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 16))
  );

  Widget _textField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkblue)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkblue)),
      ),
      validator: (value) => value == null || value.isEmpty ? "Harus diisi" : null,
    );
  }

  Widget _categoryDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']).order('nama_kategori'),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
          value: _selectedCatId,
          hint: const Text("--- Pilih Kategori ---"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkblue)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkblue)),
          ),
          items: list.map((e) => DropdownMenuItem<int>(
            value: e['id_kategori'], 
            child: Text(e['nama_kategori']))
          ).toList(),
          onChanged: (val) => setState(() => _selectedCatId = val),
          validator: (value) => value == null ? "Pilih kategori" : null,
        );
      },
    );
  }
}