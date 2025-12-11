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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String? _userRole;
  
  @override
  void initState() {
    super.initState();
    _checkCurrentSession();
    
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[AUTH GATE] Auth state changed: ${data.event}');
      
      if (data.event == AuthChangeEvent.signedIn) {
        _checkCurrentSession();
      } else if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
      }
    });
  }
  
  Future<void> _checkCurrentSession() async {
    setState(() => _isLoading = true);
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('[AUTH GATE] Current session: ${session != null ? "exists" : "null"}');
      
      if (session != null) {
        final userId = session.user.id;
        debugPrint('[AUTH GATE] User ID: $userId');
        
        final response = await Supabase.instance.client
            .from('users')
            .select('role, nama, email')
            .eq('id', userId)
            .maybeSingle();
        
        debugPrint('[AUTH GATE] User data response: $response');
        
        if (response != null) {
          final role = (response['role'] as String?)?.toLowerCase().trim() ?? '';
          debugPrint('[AUTH GATE] User role: $role');
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _userRole = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[AUTH GATE] Error: $e');
      setState(() {
        _userRole = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    debugPrint('[AUTH GATE] Building with role: $_userRole');
    
    if (_userRole == null) {
      return const LoginScreen();
    }
    
    switch (_userRole) {
      case 'dosen':
        return DosenDashboardScreen();
      case 'admin':
        return AdminDashboardScreen();
      case 'mahasiswa':
        return MahasiswaDashboardScreen();
      default:
        debugPrint('[AUTH GATE] Unknown role: $_userRole');
        return const LoginScreen();
    }
  }
}