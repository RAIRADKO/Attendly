import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../../providers/presensi_provider.dart';
import '../../models/mata_kuliah.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
// Hapus import loading_widget jika tidak digunakan atau pastikan file ada
// import '../../widgets/loading_widget.dart';

class PresensiScreen extends StatefulWidget {
  final MataKuliah mataKuliah;

  const PresensiScreen({Key? key, required this.mataKuliah}) : super(key: key);

  @override
  _PresensiScreenState createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  String _otp = '';
  bool _isLoading = false;
  String _statusPresensi = '';
  Color _statusColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendengarkan perubahan loading dari Provider jika diperlukan,
    // atau gunakan local state _isLoading seperti di bawah ini.
    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi - ${widget.mataKuliah.namaMk}'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Tambahkan Scroll agar tidak overflow di layar kecil
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kode Mata Kuliah: ${widget.mataKuliah.kodeMk}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nama Dosen: ${widget.mataKuliah.namaDosen ?? 'Tidak Tersedia'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Masukkan Kode OTP",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OtpTextField(
                  numberOfFields: 6,
                  borderColor: const Color(0xFF512DA8),
                  focusedBorderColor: Colors.blue,
                  showFieldAsBox: true,
                  onCodeChanged: (String code) {
                    _otp = code;
                  },
                  onSubmit: (String verificationCode) {
                    _otp = verificationCode;
                    _submitPresensi();
                  },
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: CustomButton(
                  text: _isLoading ? 'Memproses...' : 'Kirim Presensi',
                  onPressed: _isLoading ? null : _submitPresensi,
                  isLoading: _isLoading,
                ),
              ),
              if (_statusPresensi.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Card(
                    color: _statusColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _statusPresensi,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // LOGIKA SUBMIT (Client-Side Logic)
  // -------------------------------------------------------------
  Future<void> _submitPresensi() async {
    // 1. Validasi Input OTP
    if (_otp.length != 6) {
      _showStatus('Silakan masukkan OTP 6 digit', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    _showStatus('', Colors.transparent); // Reset status

    try {
      // 2. Validasi Lokasi (Wajib Aktif)
      final location = await LocationService.getCurrentLocation();

      if (location == null) {
        _showStatus('Gagal mendapatkan lokasi. Pastikan GPS aktif dan izin diberikan.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // 3. Panggil Provider (Logic Dart Langsung)
      // Fungsi ini akan melempar Exception jika gagal, jadi kita tangkap di catch block.
      await Provider.of<PresensiProvider>(context, listen: false)
          .submitPresensi(
        widget.mataKuliah.id,
        _otp,
        location.latitude,
        location.longitude,
      );

      // 4. Sukses
      _showStatus('Presensi berhasil dicatat!', Colors.green);
      
      // Opsional: Kembali ke halaman home setelah delay
      // await Future.delayed(Duration(seconds: 2));
      // Navigator.pop(context);

    } catch (e) {
      // 5. Tangkap Error dari Provider (misal: "OTP Salah", "Sudah Presensi")
      // Kita hapus prefix "Exception: " agar pesan lebih bersih di UI
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showStatus(errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStatus(String message, Color color) {
    if (!mounted) return;
    setState(() {
      _statusPresensi = message;
      _statusColor = color;
    });
  }
}