import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class EditPenggunaScreen extends StatefulWidget {
  final Map<String, dynamic> user; // Menerima data user yang dipilih

  const EditPenggunaScreen({super.key, required this.user});

  @override
  State<EditPenggunaScreen> createState() => _EditPenggunaScreenState();
}

class _EditPenggunaScreenState extends State<EditPenggunaScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  
  String? _selectedRole;
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'petugas', 'peminjam'];

  @override
  void initState() {
    super.initState();
    // Mengisi data awal sesuai data user yang diklik
    _namaController = TextEditingController(text: widget.user['nama']);
    _emailController = TextEditingController(text: widget.user['email']);
    _selectedRole = widget.user['role']?.toString().toLowerCase();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate() || _selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      // Melakukan update pada tabel users berdasarkan id_user
      await supabase.from('users').update({
        'nama': _namaController.text.trim(),
        'role': _selectedRole,
      }).eq('id_user', widget.user['id_user']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Pengguna Berhasil Diperbarui")),
        );
      }
    } catch (e) {
      debugPrint("Error Update: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Pengguna",
          style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Icon(Icons.account_circle_outlined, size: 130, color: AppColors.darkblue),
              ),
              const SizedBox(height: 30),

              _buildLabel("Nama"),
              _buildTextField(_namaController, "Nama Pengguna"),

              const SizedBox(height: 15),
              _buildLabel("Email"),
              // Email biasanya tidak diedit karena terkait dengan Auth, maka dibuat readOnly
              _buildTextField(_emailController, "Email", readOnly: true),

              const SizedBox(height: 15),
              _buildLabel("Sebagai"),
              _buildDropdownField(),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: _inputDecoration(hint).copyWith(
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        filled: readOnly,
      ),
      validator: (val) => val == null || val.isEmpty ? "Wajib diisi" : null,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: _inputDecoration(""),
      items: _roles.map((r) => DropdownMenuItem(
        value: r, 
        child: Text(r[0].toUpperCase() + r.substring(1))
      )).toList(),
      onChanged: (val) => setState(() => _selectedRole = val),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkblue),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkblue, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkblue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}