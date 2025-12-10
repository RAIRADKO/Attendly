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

// PERBAIKAN: Widget untuk mengatur alur login/logout otomatis dengan error handling yang lebih baik
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Saat loading awal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.data?.session;
        final event = snapshot.data?.event;

        // PERBAIKAN: Handle logout event
        if (event == AuthChangeEvent.signedOut) {
          return LoginScreen();
        }

        // Jika ada session (User sudah login)
        if (session != null) {
          // PERBAIKAN: Ambil data user lengkap dengan error handling
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserRole(session.user.id),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (userSnap.hasError) {
                print('[AUTH GATE] Error fetching user role: ${userSnap.error}');
                // Jika error, tetap tampilkan login screen
                return LoginScreen();
              }
              
              if (userSnap.hasData && userSnap.data != null) {
                final role = (userSnap.data!['role'] as String?)?.toLowerCase().trim() ?? '';
                
                // PERBAIKAN: Redirect berdasarkan role dengan case-insensitive
                switch (role) {
                  case 'dosen':
                    return DosenDashboardScreen();
                  case 'admin':
                    return AdminDashboardScreen();
                  case 'mahasiswa':
                    return MahasiswaDashboardScreen();
                  default:
                    print('[AUTH GATE] Unknown role: $role');
                    // Jika role tidak dikenali, tampilkan login screen
                    return LoginScreen();
                }
              }
              
              // Fallback jika data null
              print('[AUTH GATE] User data is null');
              return LoginScreen();
            },
          );
        }

        // Jika belum login
        return LoginScreen();
      },
    );
  }

  /// PERBAIKAN: Helper method untuk mengambil role user dengan error handling
  Future<Map<String, dynamic>?> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role, nama, email')
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('[AUTH GATE] Error getting user role: $e');
      return null;
    }
  }
}