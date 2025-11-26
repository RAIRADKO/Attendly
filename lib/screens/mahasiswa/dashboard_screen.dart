import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'home_screen.dart';
import 'presensi_screen.dart';
import 'riwayat_screen.dart';
import '../../models/mata_kuliah.dart';

class MahasiswaDashboardScreen extends StatefulWidget {
  @override
  _MahasiswaDashboardScreenState createState() => _MahasiswaDashboardScreenState();
}

class _MahasiswaDashboardScreenState extends State<MahasiswaDashboardScreen> {
  int _currentIndex = 0;
  
  // Variabel untuk menyimpan state jika user memilih presensi dari Home
  MataKuliah? _selectedMataKuliah;

  // List of Screens
  // Kita menggunakan method build agar bisa passing parameter dynamic
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return MahasiswaHomeScreen(); // Menggunakan screen yang sudah dimodifikasi sebelumnya
        // Note: Logic onSelectMataKuliah di HomeScreen perlu disesuaikan agar 
        // memanggil _handleSelectMataKuliah di sini jika ingin tab berpindah otomatis.
        // Namun untuk saat ini HomeScreen mahasiswa memiliki navigasi pushNamed sendiri.
        // Agar UI "Tab" berfungsi sempurna, HomeScreen sebaiknya memanggil callback parent.
        // Karena HomeScreen yang dibuat sebelumnya menggunakan Navigator.push, 
        // kita biarkan perilaku itu atau sesuaikan nanti.
        // Untuk Dashboard sesuai desain, tab Presensi biasanya untuk scan QR/Input Kode 
        // tanpa konteks MK spesifik atau memilih dari dropdown.
      case 1:
        if (_selectedMataKuliah != null) {
           return PresensiScreen(mataKuliah: _selectedMataKuliah!);
        }
        return _buildEmptyPresensiState();
      case 2:
        return RiwayatPresensiScreen();
      default:
        return MahasiswaHomeScreen();
    }
  }

  Widget _buildEmptyPresensiState() {
    return Scaffold(
      appBar: AppBar(title: Text('Presensi'), backgroundColor: Colors.blue[600]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Pilih Mata Kuliah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Text(
                'Silakan pilih mata kuliah dari menu Beranda untuk melakukan presensi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _currentIndex = 0),
                child: Text('Ke Beranda'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      // Body dirender berdasarkan index
      body: _buildCurrentScreen(),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Reset selection jika pindah manual ke tab presensi tanpa lewat home
            if (index == 1 && _selectedMataKuliah == null) {
               // Tetap di tab presensi tapi tampilan kosong/pilih MK
            }
          });
        },
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Presensi',
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