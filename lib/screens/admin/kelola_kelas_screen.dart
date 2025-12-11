import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/mata_kuliah.dart';
import '../../models/user.dart';

class KelolaKelasScreen extends StatefulWidget {
  @override
  State<KelolaKelasScreen> createState() => _KelolaKelasScreenState();
}

class _KelolaKelasScreenState extends State<KelolaKelasScreen> {
  final DatabaseService _db = DatabaseService();
  
  List<MataKuliah> _mataKuliahList = [];
  List<User> _allMahasiswa = [];
  Set<String> _enrolledIds = {};
  
  MataKuliah? _selectedMK;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final mkList = await _db.getAllMataKuliah();
      final mahasiswaList = await _db.getAllMahasiswa();
      
      setState(() {
        _mataKuliahList = mkList;
        _allMahasiswa = mahasiswaList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal memuat data: $e');
    }
  }

  Future<void> _loadEnrolledMahasiswa() async {
    if (_selectedMK == null) return;
    
    try {
      final enrolled = await _db.getEnrolledMahasiswa(_selectedMK!.id);
      setState(() {
        _enrolledIds = enrolled.map((e) => e['mahasiswa_id'] as String).toSet();
      });
    } catch (e) {
      _showError('Gagal memuat data enrollment: $e');
    }
  }

  Future<void> _toggleEnrollment(User mahasiswa) async {
    if (_selectedMK == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      if (_enrolledIds.contains(mahasiswa.id)) {
        await _db.unenrollMahasiswa(_selectedMK!.id, mahasiswa.id);
        setState(() => _enrolledIds.remove(mahasiswa.id));
        _showSuccess('${mahasiswa.nama} dihapus dari kelas');
      } else {
        await _db.enrollMahasiswa(_selectedMK!.id, mahasiswa.id);
        setState(() => _enrolledIds.add(mahasiswa.id));
        _showSuccess('${mahasiswa.nama} ditambahkan ke kelas');
      }
    } catch (e) {
      _showError('Gagal mengubah enrollment: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
        backgroundColor: Colors.purple[600],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Mata Kuliah
                  const Text('Pilih Mata Kuliah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<MataKuliah>(
                      value: _selectedMK,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Pilih mata kuliah...'),
                      items: _mataKuliahList.map((mk) => DropdownMenuItem(
                        value: mk,
                        child: Text('${mk.namaMk} (${mk.kodeMk})'),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedMK = value);
                        _loadEnrolledMahasiswa();
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info
                  if (_selectedMK != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mahasiswa terdaftar: ${_enrolledIds.length} dari ${_allMahasiswa.length}',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // List Mahasiswa
                    const Text('Daftar Mahasiswa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: _allMahasiswa.isEmpty
                          ? const Center(child: Text('Tidak ada mahasiswa terdaftar'))
                          : ListView.builder(
                              itemCount: _allMahasiswa.length,
                              itemBuilder: (context, index) {
                                final mhs = _allMahasiswa[index];
                                final isEnrolled = _enrolledIds.contains(mhs.id);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isEnrolled ? Colors.green[100] : Colors.grey[200],
                                      child: Icon(
                                        isEnrolled ? Icons.check : Icons.person,
                                        color: isEnrolled ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    title: Text(mhs.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('NIM: ${mhs.nim ?? "-"}'),
                                    trailing: _isSaving
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Switch(
                                            value: isEnrolled,
                                            activeColor: Colors.green,
                                            onChanged: (_) => _toggleEnrollment(mhs),
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ] else
                    const Expanded(
                      child: Center(
                        child: Text('Pilih mata kuliah untuk mengelola mahasiswa', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
