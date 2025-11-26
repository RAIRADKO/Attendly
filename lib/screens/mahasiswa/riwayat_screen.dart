import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/absensi.dart';
import '../../widgets/loading_widget.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  @override
  _RiwayatPresensiScreenState createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<PresensiProvider>(context, listen: false)
            .fetchRiwayatPresensi(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Presensi'),
        backgroundColor: Colors.blue[600],
      ),
      body: Consumer<PresensiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingWidget();
          }

          if (provider.presensiList.isEmpty) {
            return Center(
              child: Text('Belum ada riwayat presensi'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.presensiList.length,
            itemBuilder: (context, index) {
              final presensi = provider.presensiList[index];
              return Card(
                child: ListTile(
                  title: Text(presensi.namaMahasiswa),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: ${presensi.waktuPresensi}'),
                      Text('Status: ${presensi.status}'),
                    ],
                  ),
                  trailing: Icon(
                    Icons.check_circle,
                    color: presensi.status == 'hadir' ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}