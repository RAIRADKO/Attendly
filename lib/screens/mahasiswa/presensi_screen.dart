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

class _PresensiScreenState extends State<PresensiScreen> with SingleTickerProviderStateMixin {
  String _otp = '';
  bool _isLoading = false;
  bool _isLocationLoading = true;
  String _statusPresensi = '';
  Color _statusColor = Colors.grey;
  
  double? _lat;
  double? _long;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        title: Text('Presensi Kuliah', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Info Card dengan Gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school, color: Colors.white, size: 32),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.mataKuliah.namaMk,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.mataKuliah.kodeMk,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.3), height: 1),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, color: Colors.white.withOpacity(0.9), size: 18),
                        SizedBox(width: 8),
                        Text(
                          widget.mataKuliah.namaDosen ?? 'Dosen belum ditentukan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Location Info Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on, color: Colors.blue[600], size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Anda',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          _isLocationLoading
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600]),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Mengambil lokasi...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_lat?.toStringAsFixed(6) ?? '-'}, ${_long?.toStringAsFixed(6) ?? '-'}',
                                      style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Lokasi diperlukan untuk verifikasi',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // OTP Input Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.blue[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Masukkan Kode OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: Colors.grey[300]!,
                      focusedBorderColor: Colors.blue[600]!,
                      enabledBorderColor: Colors.grey[300]!,
                      showFieldAsBox: true,
                      fieldWidth: 45,
                      borderRadius: BorderRadius.circular(12),
                      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      onCodeChanged: (String code) => _otp = code,
                      onSubmit: (String verificationCode) => _otp = verificationCode,
                    ),
                    
                    SizedBox(height: 20),
                    
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Minta kode 6 digit kepada dosen pengampu',
                              style: TextStyle(color: Colors.amber[900], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),

                    // Status Message
                    if (_statusPresensi.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _statusColor == Colors.green ? Icons.check_circle_outline : Icons.error_outline,
                              color: _statusColor,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusPresensi,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitPresensi,
                        icon: _isLoading 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(Icons.check_circle, size: 22),
                        label: Text(_isLoading ? 'Memproses...' : 'Kirim Presensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Info Bottom
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Perhatian',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoItem('Kode OTP berubah secara berkala'),
                    _buildInfoItem('Pastikan kode yang dimasukkan sesuai'),
                    _buildInfoItem('Anda hanya bisa melakukan presensi sekali per sesi'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
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
          .submitPresensi(widget.mataKuliah.id, _otp, _lat!, _long!);

      _showStatus('✓ Presensi berhasil dicatat!', Colors.green);
      
      // Auto navigate back after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
      
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showStatus(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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