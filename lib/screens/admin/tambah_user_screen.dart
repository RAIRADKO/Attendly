import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class TambahUserScreen extends StatefulWidget {
  @override
  _TambahUserScreenState createState() => _TambahUserScreenState();
}

class _TambahUserScreenState extends State<TambahUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomorIndukController = TextEditingController(); 
  
  String _selectedRole = 'mahasiswa';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah User'), backgroundColor: Colors.purple[600]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['mahasiswa', 'dosen'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val!;
                    _nomorIndukController.clear();
                  });
                },
              ),
              SizedBox(height: 16),
              InputField(controller: _namaController, labelText: 'Nama Lengkap', validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 16),
              InputField(controller: _emailController, labelText: 'Email', keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Email tidak valid' : null),
              SizedBox(height: 16),
              InputField(controller: _passwordController, labelText: 'Password', obscureText: true, validator: (v) => v!.length < 6 ? 'Min 6 karakter' : null),
              SizedBox(height: 16),
              InputField(controller: _nomorIndukController, labelText: _selectedRole == 'mahasiswa' ? 'NIM' : 'NIDN', validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 24),
              CustomButton(text: 'Simpan User', isLoading: _isLoading, backgroundColor: Colors.purple[600], onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final newUser = User(
        id: '', 
        email: _emailController.text.trim(),
        nama: _namaController.text.trim(),
        role: _selectedRole,
        nim: _selectedRole == 'mahasiswa' ? _nomorIndukController.text.trim() : null,
        nidn: _selectedRole == 'dosen' ? _nomorIndukController.text.trim() : null,
      );
      await DatabaseService().addUser(newUser, _passwordController.text);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User berhasil ditambahkan!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}