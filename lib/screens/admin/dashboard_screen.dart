import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// REMOVED: import 'laporan_screen.dart'; - tidak digunakan karena menggunakan named route
import 'tambah_user_screen.dart'; 
import 'tambah_mk_screen.dart';   
import 'tambah_jadwal_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        backgroundColor: Colors.purple[600],
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Menu Laporan
            _buildDashboardCard(
              context,
              'Laporan Presensi',
              Icons.description,
              Colors.blue[600]!,
              () => Navigator.pushNamed(context, '/admin/laporan'),
            ),
            
            // Menu Tambah User
            _buildDashboardCard(
              context,
              'Tambah User',
              Icons.person_add,
              Colors.orange[600]!,
              () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TambahUserScreen())
              ),
            ),

            // Menu Tambah MK
            _buildDashboardCard(
              context,
              'Tambah MK',
              Icons.library_add,
              Colors.green[600]!,
              () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TambahMataKuliahScreen())
              ),
            ),

            // Menu Atur Jadwal
            _buildDashboardCard(
              context,
              'Atur Jadwal',
              Icons.calendar_month,
              Colors.orange[800]!,
              () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TambahJadwalScreen())
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}