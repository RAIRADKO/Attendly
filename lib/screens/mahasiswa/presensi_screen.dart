import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../../providers/presensi_provider.dart';
import '../../models/mata_kuliah.dart';
import '../../services/location_service.dart';

class PresensiScreen extends StatefulWidget {
  final MataKuliah mataKuliah;

  const PresensiScreen({Key? key, required this.mataKuliah}) : super(key: key);

  @override
  _PresensiScreenState createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  String _otp = '';
  bool _isLoading = false;
  bool _isLocationLoading = true;
  String _statusPresensi = '';
  Color _statusColor = Colors.grey;
  
  // Mock lokasi untuk tampilan
  double? _lat;
  double? _long;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _lat = loc?.latitude;
        _long = loc?.longitude;
        _isLocationLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Presensi Kuliah'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Info Mata Kuliah
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mataKuliah.namaMk,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kode: ${widget.mataKuliah.kodeMk}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        widget.mataKuliah.namaDosen ?? '-',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Location Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Anda',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _isLocationLoading
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mengambil lokasi...'),
                                ],
                              )
                            : Text(
                                '${_lat?.toStringAsFixed(6) ?? '-'}, ${_long?.toStringAsFixed(6) ?? '-'}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                        SizedBox(height: 4),
                        Text(
                          'Lokasi wajib aktif untuk presensi',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // OTP Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Masukkan Kode OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: Colors.blue,
                      focusedBorderColor: Colors.blue[800]!,
                      showFieldAsBox: true,
                      fieldWidth: 40,
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      onCodeChanged: (String code) {
                        _otp = code;
                      },
                      onSubmit: (String verificationCode) {
                        _otp = verificationCode;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    Text(
                      'Minta kode 6 digit kepada dosen pengampu',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(height: 24),

                    // Status Message
                    if (_statusPresensi.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _statusColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: _statusColor),
                            SizedBox(width: 8),
                            Expanded(child: Text(_statusPresensi, style: TextStyle(color: _statusColor))),
                          ],
                        ),
                      ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPresensi,
                      child: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text('Kirim Presensi'),
                              ],
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Info Bottom
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Perhatian:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildInfoItem('Kode OTP berubah secara berkala'),
                  _buildInfoItem('Pastikan kode yang dimasukkan sesuai'),
                  _buildInfoItem('Anda hanya bisa melakukan presensi sekali per sesi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _submitPresensi() async {
    if (_otp.length != 6) {
      _showStatus('Silakan masukkan OTP 6 digit', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    _showStatus('', Colors.transparent);

    try {
      if (_lat == null || _long == null) {
        await _initLocation();
        if (_lat == null) {
          _showStatus('Gagal mendapatkan lokasi. Cek GPS.', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      await Provider.of<PresensiProvider>(context, listen: false)
          .submitPresensi(
        widget.mataKuliah.id,
        _otp,
        _lat!,
        _long!,
      );

      _showStatus('Presensi berhasil dicatat!', Colors.green);
      
    } catch (e) {
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