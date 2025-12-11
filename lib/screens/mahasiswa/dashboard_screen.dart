import 'package:flutter/material.dart';
// REMOVED: import 'package:provider/provider.dart'; - tidak digunakan
// REMOVED: import '../../providers/auth_provider.dart'; - tidak digunakan
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
  MataKuliah? _selectedMataKuliah;

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return MahasiswaHomeScreen();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Presensi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue[600]),
              ),
              SizedBox(height: 24),
              Text(
                'Pilih Mata Kuliah',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              SizedBox(height: 8),
              Text(
                'Silakan pilih mata kuliah dari menu Beranda untuk melakukan presensi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentIndex = 0),
                icon: Icon(Icons.arrow_back),
                label: Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded, size: 26),
              activeIcon: Icon(Icons.qr_code_scanner, size: 26),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded, size: 26),
              activeIcon: Icon(Icons.history, size: 26),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}