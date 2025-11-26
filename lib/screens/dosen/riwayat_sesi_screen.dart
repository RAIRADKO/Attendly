import 'package:flutter/material.dart';
// Import provider/model jika nanti sudah siap diintegrasikan
// import '../../models/absen_sesi.dart';

class DosenRiwayatScreen extends StatefulWidget {
  final dynamic user;

  DosenRiwayatScreen({required this.user});

  @override
  _DosenRiwayatScreenState createState() => _DosenRiwayatScreenState();
}

class _DosenRiwayatScreenState extends State<DosenRiwayatScreen> {
  // Mock Data sesuai desain dosen_riwayat.dart
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': 'sesi1',
      'mata_kuliah': 'Pemrograman Mobile',
      'waktu_mulai': '2024-01-15T08:00:00Z',
      'waktu_selesai': '2024-01-15T10:00:00Z',
      'status': 'ditutup',
      'attendeeCount': 2,
      'attendees': [
        {
          'id': '1',
          'mahasiswa_nama': 'Ahmad Santoso',
          'mahasiswa_nim': '12345678',
          'waktu_presensi': '2024-01-15T08:05:00Z',
        },
        {
          'id': '2',
          'mahasiswa_nama': 'Sari Indah',
          'mahasiswa_nim': '12345679',
          'waktu_presensi': '2024-01-15T08:07:00Z',
        },
      ],
    },
    {
      'id': 'sesi2',
      'mata_kuliah': 'Basis Data',
      'waktu_mulai': '2024-01-14T10:00:00Z',
      'waktu_selesai': '2024-01-14T12:00:00Z',
      'status': 'ditutup',
      'attendeeCount': 25,
      'attendees': [], // Mock data kosong untuk demo expand
    },
  ];

  String _expandedSesi = '';

  @override
  Widget build(BuildContext context) {
    int totalSesi = _sessions.length;
    int totalHadir = _sessions.fold(0, (sum, sesi) => sum + (sesi['attendeeCount'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // AppBar dihapus karena biasanya screen ini ada di dalam Tab Dashboard
      // Jika berdiri sendiri, uncomment AppBar di bawah
      /*
      appBar: AppBar(
        title: Text('Riwayat Sesi'),
        backgroundColor: Colors.purple[600],
      ),
      */
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Sesi Presensi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Histori sesi yang pernah dibuka',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Statistics Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[500]!, Colors.purple[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sesi',
                          style: TextStyle(
                            color: Colors.purple[100],
                          ),
                        ),
                        Text(
                          '$totalSesi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Kehadiran',
                          style: TextStyle(
                            color: Colors.purple[100],
                          ),
                        ),
                        Text(
                          '$totalHadir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Sessions List
            if (_sessions.isEmpty)
              Card(
                margin: EdgeInsets.only(top: 20),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        'Belum Ada Riwayat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Anda belum pernah membuka sesi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._sessions.map((sesi) => _buildSessionCard(sesi)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> sesi) {
    bool isExpanded = _expandedSesi == sesi['id'];
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sesi['mata_kuliah'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: sesi['status'] == 'dibuka' ? Colors.green[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: sesi['status'] == 'dibuka' ? Colors.green : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              sesi['status'] == 'dibuka' ? 'Aktif' : 'Ditutup',
                              style: TextStyle(
                                color: sesi['status'] == 'dibuka' ? Colors.green[700] : Colors.grey[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.purple),
                          SizedBox(width: 4),
                          Text(
                            '${sesi['attendeeCount']}',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(_formatDate(sesi['waktu_mulai']), style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      '${_formatTime(sesi['waktu_mulai'])} - ${_formatTime(sesi['waktu_selesai'])}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                Divider(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSesi = isExpanded ? '' : sesi['id'];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? 'Sembunyikan Detail' : 'Lihat Daftar Mahasiswa',
                          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Expandable List
          if (isExpanded)
            Container(
              color: Colors.grey[50],
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: (sesi['attendees'] as List).isEmpty 
                  ? [Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Data peserta tidak tersedia di mock ini', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    )]
                  : (sesi['attendees'] as List).map<Widget>((attendee) {
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        title: Text(attendee['mahasiswa_nama'], style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(attendee['mahasiswa_nim']),
                        trailing: Text(
                          _formatTime(attendee['waktu_presensi']),
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    DateTime dt = DateTime.parse(dateString);
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  String _formatTime(String dateString) {
    DateTime dt = DateTime.parse(dateString);
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }
}