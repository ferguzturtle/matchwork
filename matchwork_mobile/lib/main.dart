import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/network_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/client_map_screen.dart';
import 'screens/provider_panel_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  NetworkService().initialize();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 1. Load keys from assets/.env
  final env = await loadEnv();
  final supabaseUrl = env['SUPABASE_URL'] ?? env['VITE_SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_KEY'] ?? env['SUPABASE_ANON_KEY'] ?? env['VITE_SUPABASE_ANON_KEY'] ?? '';

  final isConfigMissing = supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;

  if (!isConfigMissing) {
    // 2. Initialize Supabase
    await SupabaseService.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: MatchWorkApp(isConfigMissing: isConfigMissing),
    ),
  );
  
  // Remove splash screen now that Flutter is ready and Supabase is initialized
  FlutterNativeSplash.remove();
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
  final bool isConfigMissing;
  const MatchWorkApp({super.key, this.isConfigMissing = false});

  @override
  Widget build(BuildContext context) {
    if (isConfigMissing) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MatchWork',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuración Faltante',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No se pudo cargar o leer el archivo "assets/.env".\n\nPor favor, detén el comando "flutter run" en tu terminal y vuelve a iniciarlo para que Flutter compile el archivo de assets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final session = SupabaseService.instance.client.auth.currentSession;
    final appState = Provider.of<AppStateProvider>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MatchWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
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

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      // Read saved role, default to 'customer' so any login defaults to the map
      final resolvedRole = prefs.getString('user_role') ?? 'customer';

      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.switchRole(resolvedRole);
      await appState.initializeProviderState(userId);
      
      // Initialize real-time notifications
      SupabaseService.instance.initializeNotificationsListener();
      NotificationService().saveTokenToDatabase(userId);

      if (mounted) {
        setState(() {
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

    final appState = Provider.of<AppStateProvider>(context);
    return appState.userRole == 'customer' 
        ? const ClientMapScreen() 
        : const ProviderPanelScreen();
  }
}
