import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/client_map_screen.dart';
import 'screens/provider_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load keys from assets/.env
  final env = await loadEnv();
  final supabaseUrl = env['SUPABASE_URL'] ?? env['VITE_SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_KEY'] ?? env['SUPABASE_ANON_KEY'] ?? env['VITE_SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print("WARNING: Supabase URL or Key is empty. Please verify your assets/.env file.");
  }

  // 2. Initialize Supabase
  await SupabaseService.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const MatchWorkApp(),
    ),
  );
}

// Custom manual .env parser from assets
Future<Map<String, String>> loadEnv() async {
  try {
    final content = await rootBundle.loadString('assets/.env');
    final lines = content.split('\n');
    final env = <String, String>{};
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx == -1) continue;
      final key = line.substring(0, idx).trim();
      final val = line.substring(idx + 1).trim().replaceAll('"', '').replaceAll("'", "");
      env[key] = val;
    }
    return env;
  } catch (e) {
    print("Error loading assets/.env: $e");
    return {};
  }
}

class MatchWorkApp extends StatelessWidget {
  const MatchWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SupabaseService.instance.client.auth.currentSession;
    
    return MaterialApp(
      title: 'MatchWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: session == null 
          ? const AuthScreen() 
          : const AuthWrapper(),
    );
  }
}

// AuthWrapper helps async load state for logged users
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInit = false;
  String _role = 'customer';

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      final profile = await SupabaseService.instance.getUserProfile(userId);
      final resolvedRole = profile != null ? (profile['role'] ?? 'customer') : 'customer';

      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.switchRole(resolvedRole);
      await appState.initializeProviderState(userId);

      if (mounted) {
        setState(() {
          _role = resolvedRole;
          _isInit = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _role == 'customer' 
        ? const ClientMapScreen() 
        : const ProviderPanelScreen();
  }
}
