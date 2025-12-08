import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/sesi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/otp_service.dart';
import '../../models/mata_kuliah.dart';
import '../../widgets/loading_widget.dart';
import '../../config/supabase_config.dart';

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
  int _otpChangeCount = 0; // Counter untuk tracking berapa kali OTP berubah

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
    return WillPopScope(
      onWillPop: () async {
        // Konfirmasi sebelum keluar
        return await _confirmCloseSesi();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sesi Presensi Aktif'),
          backgroundColor: Colors.purple[700],
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmCloseSesi()) {
                _closeSesi();
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.stop_circle_outlined),
              tooltip: 'Tutup Sesi',
              onPressed: () async {
                if (await _confirmCloseSesi()) {
                  _closeSesi();
                }
              },
            ),
            // Debug button (hapus di production)
            IconButton(
              icon: Icon(Icons.bug_report),
              tooltip: 'Test OTP',
              onPressed: _testOTP,
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
                textAlign: TextAlign.center,
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
                      child: Column(
                        children: [
                          Text(
                            'Bagikan kode ini kepada mahasiswa',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'OTP #${_otpChangeCount + 1} • Sesi ID: ${Provider.of<SesiProvider>(context, listen: false).currentSesi?.id ?? '-'}',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Live Attendees Section
              Consumer<SesiProvider>(
                builder: (context, provider, child) {
                  final sesiId = provider.currentSesi?.id ?? 0;
                  
                  if (sesiId == 0) {
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
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: SupabaseConfig.instance
                                .from('absensi')
                                .stream(primaryKey: ['id'])
                                .eq('sesi_id', sesiId)
                                .order('waktu_presensi', ascending: false),
                            builder: (context, countSnapshot) {
                              final count = countSnapshot.hasData ? countSnapshot.data!.length : 0;
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total: $count',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: SupabaseConfig.instance
                            .from('absensi')
                            .stream(primaryKey: ['id'])
                            .eq('sesi_id', sesiId)
                            .order('waktu_presensi', ascending: false),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return LoadingWidget();
                          
                          final data = snapshot.data!;
                          
                          if (data.isEmpty) {
                            return Center(
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
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final presensi = data[index];
                              final waktuPresensi = DateTime.parse(presensi['waktu_presensi']);
                              final status = presensi['status'] ?? 'hadir';
                              
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _getMahasiswaName(presensi['mahasiswa_id']),
                                builder: (context, nameSnapshot) {
                                  final namaMahasiswa = nameSnapshot.hasData 
                                      ? nameSnapshot.data!['nama'] ?? 'Mahasiswa ID: ${presensi['mahasiswa_id']}'
                                      : 'Mahasiswa ID: ${presensi['mahasiswa_id']}';
                                  
                                  Color statusColor = status == 'hadir' ? Colors.green : Colors.orange;
                                  IconData statusIcon = status == 'hadir' ? Icons.check : Icons.warning;
                                  
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: statusColor.withOpacity(0.2),
                                        child: Icon(statusIcon, color: statusColor),
                                      ),
                                      title: Text(
                                        namaMahasiswa,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text('${waktuPresensi.toString().substring(11, 16)} • ${status.toUpperCase()}'),
                                      trailing: Icon(Icons.check_circle, color: statusColor),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  if (await _confirmCloseSesi()) {
                    _closeSesi();
                  }
                },
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
      ),
    );
  }

  void _startSesi() async {
    setState(() {
      _isSesiActive = true;
      _secretKey = OtpService.generateSecretKey();
    });

    print('\n=== SESI DIMULAI ===');
    print('Mata Kuliah: ${widget.mataKuliah.namaMk}');
    print('Secret Key: ${_secretKey.substring(0, 20)}...');
    
    _updateOtp();
    _startTimer();
    
    // Test OTP generation
    OtpService.testOTP(_secretKey);
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      try {
        await Provider.of<SesiProvider>(context, listen: false)
            .createSesiPresensi(widget.mataKuliah.id, user.id, _secretKey);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesi berhasil dibuat! Kode OTP aktif.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('[ERROR] Gagal membuat sesi: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat sesi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _updateOtp() {
    if (_secretKey.isNotEmpty) {
      final otp = OtpService.generateOTP(_secretKey);
      setState(() {
        _currentOtp = otp;
        _otpChangeCount++;
      });
      print('[OTP UPDATE #${_otpChangeCount}] New OTP: $otp at ${DateTime.now()}');
    }
  }

  void _startTimer() {
    // Calculate initial time left based on current second
    final now = DateTime.now();
    final secondsInPeriod = now.second % 30;
    _timeLeft = 30 - secondsInPeriod;
    
    print('[TIMER] Starting timer with $_timeLeft seconds remaining');
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
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
    
    _timer?.cancel();
    
    final provider = Provider.of<SesiProvider>(context, listen: false);
    final sesi = provider.currentSesi;
    if (sesi != null) {
      provider.tutupSesi(sesi.id);
    }
    
    print('=== SESI DITUTUP ===\n');
    Navigator.pop(context);
  }

  Future<bool> _confirmCloseSesi() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tutup Sesi?'),
          content: Text('Apakah Anda yakin ingin menutup sesi presensi? Mahasiswa tidak akan bisa presensi setelah sesi ditutup.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Tutup Sesi'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _testOTP() {
    if (_secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesi belum dimulai')),
      );
      return;
    }
    
    OtpService.testOTP(_secretKey);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('OTP Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Secret Key: ${_secretKey.substring(0, 20)}...'),
              SizedBox(height: 8),
              Text('Current OTP: $_currentOtp'),
              SizedBox(height: 8),
              Text('Time Left: $_timeLeft seconds'),
              SizedBox(height: 8),
              Text('OTP Changes: $_otpChangeCount'),
              SizedBox(height: 16),
              Text('Test validation dengan OTP saat ini:'),
              SizedBox(height: 8),
              Text(
                OtpService.validateOTP(_secretKey, _currentOtp) ? '✓ VALID' : '✗ INVALID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: OtpService.validateOTP(_secretKey, _currentOtp) ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getMahasiswaName(String mahasiswaId) async {
    try {
      final response = await SupabaseConfig.instance
          .from('users')
          .select('nama')
          .eq('id', mahasiswaId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('[ERROR] Failed to fetch mahasiswa name: $e');
      return null;
    }
  }
}