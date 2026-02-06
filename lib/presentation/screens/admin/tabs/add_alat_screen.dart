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
    _stokCtrl = TextEditingController(text: widget.alat?['stok_total']?.toString());
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
          setState(() => _webImage = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  Future<String?> _uploadToStorage() async {
    // Jika tidak ada perubahan gambar baru (baik di Web maupun Mobile), kembalikan URL lama
    if (_imageFile == null && _webImage == null) return _imageUrl;
    
    try {
      // Gunakan timestamp agar nama file selalu unik, mencegah masalah cache di Supabase
      final fileName = 'alat_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'public/$fileName';
      
      if (kIsWeb) {
        await supabase.storage.from('foto_alat').uploadBinary(path, _webImage!);
      } else {
        await supabase.storage.from('foto_alat').upload(path, _imageFile!);
      }
      
      // Ambil Public URL baru
      final newUrl = supabase.storage.from('foto_alat').getPublicUrl(path);
      
      // Tambahkan timestamp di akhir URL untuk mematikan Cache Image di Flutter/Browser
      return "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("Gagal upload ke storage: $e");
      return _imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.alat != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Alat" : "Tambah Alat", 
          style: const TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkblue),
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
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1E4F3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImagePreview(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.darkblue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _label("Nama"),
              _textField(_nameCtrl, "Masukkan nama barang"),
              _label("Kategori"),
              _categoryDropdown(),
              _label("Stok"),
              _textField(_stokCtrl, "10", isNumber: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkblue, 
                    padding: const EdgeInsets.all(15), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: Text(isEdit ? "Simpan Perubahan" : "Tambahkan Alat", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover, key: ValueKey(_webImage.hashCode));
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover, key: ValueKey(_imageFile!.path));
    } else if (_imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Image.network(_imageUrl!, fit: BoxFit.contain, key: ValueKey(_imageUrl)),
      );
    } else {
      return const Icon(Icons.image_outlined, size: 50, color: Colors.grey);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 15), 
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue))
  );

  Widget _textField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint, 
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      validator: (value) => value!.isEmpty ? "Harus diisi" : null,
    );
  }

  Widget _categoryDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
          value: _selectedCatId,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
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

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      try {
        final uploadedUrl = await _uploadToStorage();
        final data = {
          'nama_alat': _nameCtrl.text, 
          'stok_total': int.parse(_stokCtrl.text), 
          'kategori_id': _selectedCatId,
          'foto_url': uploadedUrl, // Menyimpan URL unik baru
        };
        
        if (widget.alat != null) {
          await supabase.from('alat').update(data).eq('id_alat', widget.alat!['id_alat']);
        } else {
          await supabase.from('alat').insert(data);
        }
        
        if (mounted) Navigator.pop(context, true); 
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
}