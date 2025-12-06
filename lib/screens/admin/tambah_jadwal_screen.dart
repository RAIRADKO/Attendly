import 'package:flutter/material.dart';
import '../../models/mata_kuliah.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';

class TambahJadwalScreen extends StatefulWidget {
  @override
  _TambahJadwalScreenState createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedMkId;
  String _selectedHari = 'Senin';
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  
  List<MataKuliah> _mkList = [];
  bool _isLoading = false;
  bool _isFetching = true;

  final List<String> _hariList = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await DatabaseService().getAllMataKuliah();
      if (mounted) {
        setState(() {
          _mkList = data;
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  Future<void> _selectTime(bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) _jamMulai = picked;
        else _jamSelesai = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Jadwal Kuliah'),
        backgroundColor: Colors.purple[600],
      ),
      body: _isFetching 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown MK
                    DropdownButtonFormField<int>(
                      value: _selectedMkId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Mata Kuliah',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _mkList.map((mk) {
                        return DropdownMenuItem(
                          value: mk.id,
                          child: Text('${mk.namaMk} (${mk.kodeMk})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMkId = val),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    ),
                    SizedBox(height: 16),

                    // Dropdown Hari
                    DropdownButtonFormField<String>(
                      value: _selectedHari,
                      decoration: InputDecoration(
                        labelText: 'Hari',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _hariList.map((hari) {
                        return DropdownMenuItem(value: hari, child: Text(hari));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedHari = val!),
                    ),
                    SizedBox(height: 16),

                    // Input Jam Mulai & Selesai
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Jam Mulai',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                _jamMulai != null ? _formatTime(_jamMulai!) : 'Pilih Jam',
                                style: TextStyle(
                                  color: _jamMulai != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Jam Selesai',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: Icon(Icons.access_time_filled),
                              ),
                              child: Text(
                                _jamSelesai != null ? _formatTime(_jamSelesai!) : 'Pilih Jam',
                                style: TextStyle(
                                  color: _jamSelesai != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Validasi manual visual untuk jam
                    if (_jamMulai == null || _jamSelesai == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 12),
                        child: Text(
                          'Jam wajib diisi',
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),

                    SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: _isLoading ? 'Menyimpan...' : 'Simpan Jadwal',
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
    if (_jamMulai == null || _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jam mulai dan selesai harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseService().addJadwal(
        _selectedMkId!,
        _selectedHari,
        _formatTime(_jamMulai!),
        _formatTime(_jamSelesai!),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jadwal berhasil ditambahkan!')),
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