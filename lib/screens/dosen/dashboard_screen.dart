import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'home_screen.dart';
import 'riwayat_sesi_screen.dart';
// Import screen sesi presensi jika ingin ditampilkan langsung di tab, 
// tapi biasanya sesi presensi dibuka dari Home.
// Disini kita buat Tab 'Sesi' sebagai placeholder atau list sesi aktif.

class DosenDashboardScreen extends StatefulWidget {
  @override
  _DosenDashboardScreenState createState() => _DosenDashboardScreenState();
}

class _DosenDashboardScreenState extends State<DosenDashboardScreen> {
  int _currentIndex = 0;

  Widget _buildCurrentScreen() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    switch (_currentIndex) {
      case 0:
        return DosenHomeScreen(); 
      case 1:
        // Di desain dosen_dashboard.dart, tab tengah adalah "Sesi OTP". 
        // Karena sesi OTP butuh parameter MK, kita tampilkan placeholder 
        // atau info jika belum ada sesi dipilih.
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radio_button_checked, size: 64, color: Colors.purple[200]),
              SizedBox(height: 16),
              Text('Tidak ada sesi aktif yang dipilih'),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 0),
                child: Text('Buka sesi dari Beranda'),
              )
            ],
          ),
        );
      case 2:
        return DosenRiwayatScreen(user: user);
      default:
        return DosenHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.purple[600],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mata Kuliah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.podcasts), // Icon Sesi/Radio
            label: 'Sesi Aktif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}