import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Pastikan package ini ada di pubspec.yaml
import '../../services/database_service.dart';

class LaporanScreen extends StatefulWidget {
  @override
  _LaporanScreenState createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Presensi'),
        backgroundColor: Colors.purple[600],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unduh Laporan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.table_chart, color: Colors.green[700], size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Semua Presensi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Format: CSV (Kompatibel dengan Excel)',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Laporan ini mencakup seluruh data presensi mahasiswa, termasuk nama, NIM, mata kuliah, waktu kehadiran, dan lokasi.',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isExporting 
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(Icons.download),
                        label: Text(
                          _isExporting ? 'Sedang Mengekspor...' : 'Ekspor ke CSV',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isExporting ? null : _exportToCSV,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      // 1. Ambil Data Raw dari Database
      final data = await DatabaseService().getAllPresensiRaw();
      
      if (data.isEmpty) {
        throw Exception("Tidak ada data presensi untuk diekspor.");
      }

      // 2. Susun Header CSV
      String csvContent = "No,Nama Mahasiswa,NIM,Mata Kuliah,Kode MK,Waktu Presensi,Status,Latitude,Longitude\n";

      // 3. Loop Data dan Tambahkan Baris
      int index = 1;
      for (var item in data) {
        // Ambil data dari hasil join (nested JSON)
        final nama = item['users']?['nama'] ?? '-';
        final nim = item['users']?['nim'] ?? '-';
        final mk = item['absen_sesi']?['mata_kuliah']?['nama_mk'] ?? '-';
        final kodeMk = item['absen_sesi']?['mata_kuliah']?['kode_mk'] ?? '-';
        final waktu = item['waktu_presensi'] ?? '-';
        final status = item['status'] ?? '-';
        final lat = item['latitude'] ?? 0;
        final long = item['longitude'] ?? 0;

        // Bersihkan data string dari koma agar format CSV tidak rusak
        final cleanNama = nama.toString().replaceAll(',', ' ');
        final cleanMk = mk.toString().replaceAll(',', ' ');

        csvContent += "$index,$cleanNama,$nim,$cleanMk,$kodeMk,$waktu,$status,$lat,$long\n";
        index++;
      }

      // 4. Simpan File ke Penyimpanan Lokal
      final directory = await getApplicationDocumentsDirectory();
      final fileName = "Laporan_Presensi_${DateTime.now().millisecondsSinceEpoch}.csv";
      final path = "${directory.path}/$fileName";
      
      final file = File(path);
      await file.writeAsString(csvContent);

      // 5. Feedback ke User
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil diekspor ke: $path'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK', 
              textColor: Colors.white, 
              onPressed: () {},
            ),
          ),
        );
      }
      
      print("CSV Exported to: $path");

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}