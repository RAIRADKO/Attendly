import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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
  String _currentOtp = '';
  int _timeLeft = 30;
  Timer? _timer;
  bool _isSesiActive = false;
  String _secretKey = '';

  @override
  void initState() {
    super.initState();
    // Gunakan microtask atau postFrameCallback untuk memulai sesi
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
        title: Text('Sesi Presensi - ${widget.mataKuliah.namaMk}'),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: _closeSesi,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'OTP Saat Ini',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentOtp.isNotEmpty ? _currentOtp : 'Menghitung...',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Berlaku selama $_timeLeft detik',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Consumer<SesiProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return LoadingWidget();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mahasiswa Hadir (${provider.presensiList.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: provider.presensiList.length,
                          itemBuilder: (context, index) {
                            final presensi = provider.presensiList[index];
                            return Card(
                              child: ListTile(
                                title: Text(presensi.namaMahasiswa),
                                subtitle: Text(presensi.waktuPresensi.toString()),
                                trailing: Icon(Icons.check_circle, color: Colors.green),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
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
      _secretKey = OtpService.generateSecretKey(); // Generate kunci baru
    });

    _updateOtp();
    _startTimer();
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      // PERBAIKAN: Kirim _secretKey yang baru di-generate
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