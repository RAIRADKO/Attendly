import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// REMOVED: import 'config/supabase_config.dart'; - tidak digunakan
import 'providers/auth_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/sesi_provider.dart';
import 'routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/mahasiswa/dashboard_screen.dart';
import 'screens/dosen/dashboard_screen.dart';
import 'screens/admin/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

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
        home: const AuthGate(), 
        onGenerateRoute: Routes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.data?.session;
        final event = snapshot.data?.event;

        if (event == AuthChangeEvent.signedOut) {
          return LoginScreen();
        }

        if (session != null) {
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
                return LoginScreen();
              }
              
              if (userSnap.hasData && userSnap.data != null) {
                final role = (userSnap.data!['role'] as String?)?.toLowerCase().trim() ?? '';
                
                switch (role) {
                  case 'dosen':
                    return DosenDashboardScreen();
                  case 'admin':
                    return AdminDashboardScreen();
                  case 'mahasiswa':
                    return MahasiswaDashboardScreen();
                  default:
                    print('[AUTH GATE] Unknown role: $role');
                    return LoginScreen();
                }
              }
              
              print('[AUTH GATE] User data is null');
              return LoginScreen();
            },
          );
        }

        return LoginScreen();
      },
    );
  }

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