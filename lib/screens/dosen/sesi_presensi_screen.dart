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
  State<SesiPresensiScreen> createState() => _SesiPresensiScreenState();
}

class _SesiPresensiScreenState extends State<SesiPresensiScreen> {
  String _currentOtp = '';
  String _secretKey = '';
  int _timeLeft = 30;
  Timer? _timer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startSesi();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startSesi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate secret key
      _secretKey = OtpService.generateSecretKey();
      
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      // Buat sesi di database
      await Provider.of<SesiProvider>(context, listen: false)
          .createSesiPresensi(widget.mataKuliah.id, user.id, _secretKey);

      // Generate OTP pertama dan mulai timer
      _updateOtp();
      _startTimer();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[SESI ERROR] $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _updateOtp() {
    if (_secretKey.isEmpty) return;
    
    final otp = OtpService.generateOTP(_secretKey);
    setState(() => _currentOtp = otp);
    print('[OTP UPDATE] New OTP: $otp');
  }

  void _startTimer() {
    _timeLeft = OtpService.getTimeRemaining();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() => _timeLeft--);

      if (_timeLeft <= 0) {
        _updateOtp();
        _timeLeft = 30;
      }
    });
  }

  void _closeSesi() async {
    _timer?.cancel();
    
    final provider = Provider.of<SesiProvider>(context, listen: false);
    final sesi = provider.currentSesi;
    if (sesi != null) {
      await provider.tutupSesi(sesi.id);
    }
    
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirmCloseSesi() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutup Sesi?'),
        content: const Text('Mahasiswa tidak akan bisa presensi setelah sesi ditutup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tutup Sesi'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _confirmCloseSesi()) {
          _closeSesi();
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sesi Presensi Aktif'),
          backgroundColor: Colors.purple[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmCloseSesi()) {
                _closeSesi();
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContentView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Gagal membuat sesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _startSesi, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Text(widget.mataKuliah.namaMk, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(widget.mataKuliah.kodeMk, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // OTP Card dengan Timer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple[600]!, Colors.purple[800]!]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Text('Kode OTP', style: TextStyle(color: Colors.purple[100], fontSize: 16)),
                const SizedBox(height: 16),

                // OTP Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    _currentOtp,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8),
                  ),
                ),

                const SizedBox(height: 20),

                // Timer Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.purple[100], size: 20),
                    const SizedBox(width: 8),
                    Text('Berubah dalam $_timeLeft detik', style: TextStyle(color: Colors.purple[100], fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _timeLeft / 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 16),
                Text('Bagikan kode ini kepada mahasiswa', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildAttendeesSection(),
          const SizedBox(height: 24),

          // Close Button
          ElevatedButton.icon(
            onPressed: () async {
              if (await _confirmCloseSesi()) _closeSesi();
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('Tutup Sesi Presensi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection() {
    return Consumer<SesiProvider>(
      builder: (context, provider, child) {
        final sesiId = provider.currentSesi?.id ?? 0;
        if (sesiId == 0) return const LoadingWidget(message: 'Menyiapkan sesi...');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mahasiswa Hadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseConfig.instance.from('absensi').stream(primaryKey: ['id']).eq('sesi_id', sesiId),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                      child: Text('Total: $count', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseConfig.instance.from('absensi').stream(primaryKey: ['id']).eq('sesi_id', sesiId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingWidget();
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('Belum ada mahasiswa presensi', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final presensi = data[index];
                    final waktu = DateTime.tryParse(presensi['waktu_presensi'] ?? '');
                    final status = presensi['status'] ?? 'hadir';
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getMahasiswaName(presensi['mahasiswa_id']),
                      builder: (context, nameSnap) {
                        final nama = nameSnap.data?['nama'] ?? 'Mahasiswa';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.green[100], child: const Icon(Icons.check, color: Colors.green)),
                            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(waktu != null ? '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}' : status),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
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
    );
  }

  Future<Map<String, dynamic>?> _getMahasiswaName(String? id) async {
    if (id == null) return null;
    try {
      return await SupabaseConfig.instance.from('users').select('nama').eq('id', id).maybeSingle();
    } catch (e) {
      return null;
    }
  }
}
