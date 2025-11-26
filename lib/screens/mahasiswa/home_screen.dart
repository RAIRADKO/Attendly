import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mata_kuliah.dart';
import '../../widgets/loading_widget.dart';

class MahasiswaHomeScreen extends StatefulWidget {
  @override
  _MahasiswaHomeScreenState createState() => _MahasiswaHomeScreenState();
}

class _MahasiswaHomeScreenState extends State<MahasiswaHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<PresensiProvider>(context, listen: false)
            .fetchMataKuliahAktif(user.id, user.role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background abu-abu muda seperti desain
      appBar: AppBar(
        title: Text('Dashboard Mahasiswa'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'logout') {
                _logout(context);
              } else if (choice == 'riwayat') {
                Navigator.pushNamed(context, '/mahasiswa/riwayat');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'riwayat', child: Text('Riwayat Presensi')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Consumer<PresensiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingWidget();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card (Gradient)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[500]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${user?.nama ?? 'Mahasiswa'}! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Jangan lupa untuk melakukan presensi di setiap mata kuliah yang sedang berlangsung.',
                        style: TextStyle(
                          color: Colors.blue[100],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Header List
                Text(
                  'Daftar Mata Kuliah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),

                // List Mata Kuliah
                if (provider.mataKuliahList.isEmpty)
                   Center(child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text("Tidak ada mata kuliah aktif"),
                   ))
                else
                  ...provider.mataKuliahList.map((mk) => _buildMataKuliahCard(context, mk)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMataKuliahCard(BuildContext context, MataKuliah mk) {
    // Logika sederhana untuk UI: Anggap sesi selalu aktif atau perlu dicek via API lain
    // Disini kita buat tombolnya selalu aktif agar user bisa masuk ke halaman presensi
    bool isActive = true; 

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.book, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mk.namaMk,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              mk.kodeMk,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            // Dosen Info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  mk.namaDosen ?? 'Dosen belum ditentukan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToPresensi(context, mk),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Isi Presensi Sekarang'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPresensi(BuildContext context, MataKuliah mk) {
    Navigator.pushNamed(
      context,
      '/mahasiswa/presensi',
      arguments: mk,
    );
  }

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}