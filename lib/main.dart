import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/sesi_provider.dart';
import 'routes.dart';
// Import screen Anda
import 'screens/auth/login_screen.dart';
import 'screens/mahasiswa/dashboard_screen.dart'; // Dashboard mahasiswa
import 'screens/dosen/dashboard_screen.dart'; // Dashboard dosen
import 'screens/admin/dashboard_screen.dart'; // Dashboard admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load .env
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase dengan variable dari .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => SesiProvider()),
      ],
      child: MaterialApp(
        title: 'Attendly',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Hapus 'initialRoute' static
        // Gunakan 'home' dengan StreamBuilder untuk cek status login real-time
        home: const AuthGate(), 
        onGenerateRoute: Routes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Widget baru untuk mengatur alur login/logout otomatis
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Saat loading awal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        // Jika ada session (User sudah login)
        if (session != null) {
          // Disini Anda perlu logika untuk cek role (dosen/mahasiswa)
          // Untuk sementara, kita ambil data user lagi atau simpan role di metadata
          return FutureBuilder(
            future: Supabase.instance.client.from('users').select('role').eq('id', session.user.id).single(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (userSnap.hasData) {
                final role = userSnap.data?['role'];
                if (role == 'dosen') return DosenDashboardScreen();
                if (role == 'admin') return AdminDashboardScreen();
                return MahasiswaDashboardScreen();
              }
              
              return LoginScreen(); // Fallback jika gagal ambil role
            },
          );
        }

        // Jika belum login
        return LoginScreen();
      },
    );
  }
}