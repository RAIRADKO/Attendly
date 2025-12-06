import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class TambahMataKuliahScreen extends StatefulWidget {
  @override
  _TambahMataKuliahScreenState createState() => _TambahMataKuliahScreenState();
}

class _TambahMataKuliahScreenState extends State<TambahMataKuliahScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaMkController = TextEditingController();
  final _kodeMkController = TextEditingController();
  
  String? _selectedDosenId;
  List<User> _dosenList = [];
  bool _isLoading = false;
  bool _isFetchingDosen = true;

  @override
  void initState() {
    super.initState();
    _fetchDosen();
  }

  Future<void> _fetchDosen() async {
    try {
      final list = await DatabaseService().getAllDosen();
      if (mounted) {
        setState(() {
          _dosenList = list;
          _isFetchingDosen = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingDosen = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar dosen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Mata Kuliah'), 
        backgroundColor: Colors.purple[600],
      ),
      body: _isFetchingDosen 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nama Mata Kuliah
                    InputField(
                      controller: _namaMkController,
                      labelText: 'Nama Mata Kuliah',
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    SizedBox(height: 16),

                    // Kode MK
                    InputField(
                      controller: _kodeMkController,
                      labelText: 'Kode MK',
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    SizedBox(height: 16),

                    // Dropdown Dosen
                    DropdownButtonFormField<String>(
                      value: _selectedDosenId,
                      decoration: InputDecoration(
                        labelText: 'Dosen Pengampu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _dosenList.map((dosen) {
                        return DropdownMenuItem(
                          value: dosen.id,
                          child: Text(dosen.nama),
                        );
                      }).toList(),
                      validator: (v) => v == null ? 'Pilih dosen' : null,
                      onChanged: (val) => setState(() => _selectedDosenId = val),
                    ),
                    SizedBox(height: 24),

                    // Tombol Simpan
                    CustomButton(
                      text: _isLoading ? 'Menyimpan...' : 'Simpan Mata Kuliah',
                      isLoading: _isLoading,
                      backgroundColor: Colors.purple[600],
                      onPressed: _isLoading ? null : _submit,
                    ),
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
      await DatabaseService().addMataKuliah(
        _namaMkController.text.trim(),
        _kodeMkController.text.trim(),
        _selectedDosenId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mata Kuliah berhasil ditambahkan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}