import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math'; // Needed for Random in case logic needs it, though using service
import '../../providers/sesi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../models/mata_kuliah.dart';
import '../../widgets/loading_widget.dart';

class SesiPresensiScreen extends StatefulWidget {
  final MataKuliah mataKuliah;

  const SesiPresensiScreen({Key? key, required this.mataKuliah}) : super(key: key);

  @override
  _SesiPresensiScreenState createState() => _SesiPresensiScreenState();
}

class _SesiPresensiScreenState extends State<SesiPresensiScreen> {
  String _currentOtp = '...';
  int _timeLeft = 30;
  Timer? _timer;
  bool _isSesiActive = false;
  String _secretKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSesi();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sesi Presensi Aktif'),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.stop_circle_outlined),
            tooltip: 'Tutup Sesi',
            onPressed: _closeSesi,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Info
            Text(
              widget.mataKuliah.namaMk,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.mataKuliah.kodeMk,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // OTP Container Gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[600]!, Colors.purple[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Kode OTP Saat Ini:',
                    style: TextStyle(
                      color: Colors.purple[100],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      _currentOtp,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: Colors.purple[100], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Berubah dalam $_timeLeft detik',
                        style: TextStyle(
                          color: Colors.purple[100],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bagikan kode ini kepada mahasiswa',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Live Attendees Section
            Consumer<SesiProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.presensiList.isEmpty) {
                  return LoadingWidget(message: 'Menyiapkan sesi...');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mahasiswa Hadir',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total: ${provider.presensiList.length}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    if (provider.presensiList.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                              SizedBox(height: 8),
                              Text('Belum ada mahasiswa presensi', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: provider.presensiList.length,
                        itemBuilder: (context, index) {
                          final presensi = provider.presensiList[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(Icons.check, color: Colors.green),
                              ),
                              title: Text(presensi.namaMahasiswa, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Waktu: ${presensi.waktuPresensi.toString().substring(11, 16)}'),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _closeSesi,
              icon: Icon(Icons.stop_circle),
              label: Text('Tutup Sesi Presensi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSesi() {
    setState(() {
      _isSesiActive = true;
      _secretKey = OtpService.generateSecretKey();
    });

    _updateOtp();
    _startTimer();
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<SesiProvider>(context, listen: false)
          .createSesiPresensi(widget.mataKuliah.id, user.id, _secretKey);
    }
  }

  void _updateOtp() {
    if (_secretKey.isNotEmpty) {
      final otp = OtpService.generateOTP(_secretKey);
      setState(() {
        _currentOtp = otp;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
      });

      if (_timeLeft <= 0) {
        _updateOtp();
        _timeLeft = 30;
      }
    });
  }

  void _closeSesi() {
    setState(() {
      _isSesiActive = false;
    });
    
    final provider = Provider.of<SesiProvider>(context, listen: false);
    final sesi = provider.currentSesi;
    if (sesi != null) {
      provider.tutupSesi(sesi.id);
    }
    
    Navigator.pop(context);
  }
}