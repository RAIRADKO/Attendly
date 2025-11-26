import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/mata_kuliah.dart';
import '../../widgets/loading_widget.dart';

class DosenHomeScreen extends StatefulWidget {
  @override
  _DosenHomeScreenState createState() => _DosenHomeScreenState();
}

class _DosenHomeScreenState extends State<DosenHomeScreen> {
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
        title: Text('Presensi Dosen'),
        backgroundColor: Colors.green[600],
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
                  onTap: () => _navigateToSesi(context, mk),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToSesi(BuildContext context, MataKuliah mk) {
    Navigator.pushNamed(
      context,
      '/dosen/sesi',
      arguments: mk,
    );
  }

  void _logout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}