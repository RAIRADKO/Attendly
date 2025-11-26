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
    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi Mahasiswa'),
        backgroundColor: Colors.blue[600],
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'logout') {
                _logout(context);
              } else if (choice == 'riwayat') {
                Navigator.pushNamed(context, '/mahasiswa/riwayat');
              }
            },
            // PERBAIKAN DI SINI: Menangani dua item menu dengan tipe yang benar
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'riwayat',
                child: Text('Riwayat Presensi'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PresensiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingWidget();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.mataKuliahList.length,
            itemBuilder: (context, index) {
              final mk = provider.mataKuliahList[index];
              return Card(
                child: ListTile(
                  title: Text(mk.namaMk),
                  subtitle: Text('Kode: ${mk.kodeMk}'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToPresensi(context, mk),
                ),
              );
            },
          );
        },
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