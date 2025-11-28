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

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<PresensiProvider>(context, listen: false)
            .fetchRiwayatPresensi(user.id);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Sliver App Bar dengan Gradient
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[600],
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Consumer<PresensiProvider>(
                        builder: (context, provider, _) {
                          int totalHadir = provider.presensiList.where((p) => p.status == 'hadir').length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Riwayat Kehadiran',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Total $totalHadir kehadiran tercatat',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Consumer<PresensiProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Container(
                      height: 400,
                      child: LoadingWidget(),
                    );
                  }

                  int totalHadir = provider.presensiList.where((p) => p.status == 'hadir').length;
                  int totalTidakHadir = provider.presensiList.length - totalHadir;

                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Statistics Card
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.teal[400]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Total Kehadiran',
                                  '$totalHadir',
                                  Icons.check_circle,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Total Absen',
                                  '$totalTidakHadir',
                                  Icons.cancel,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar Riwayat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (provider.presensiList.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${provider.presensiList.length} Entri',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // List Content
                        if (provider.presensiList.isEmpty)
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.history, size: 64, color: Colors.grey[400]),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Belum Ada Riwayat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Riwayat presensi Anda akan muncul di sini',
                                    style: TextStyle(color: Colors.grey[500]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...provider.presensiList.map((presensi) => _buildRiwayatCard(presensi)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRiwayatCard(Absensi presensi) {
    bool isHadir = presensi.status == 'hadir';
    Color statusColor = isHadir ? Colors.green : Colors.red;
    IconData statusIcon = isHadir ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Optional: add detail view
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presensi.namaMahasiswa,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  presensi.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      _formatDateTime(presensi.waktuPresensi),
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
                if (presensi.latitude != null && presensi.longitude != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${presensi.latitude!.toStringAsFixed(6)}, ${presensi.longitude!.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}