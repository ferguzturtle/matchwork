import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';

class AppStateProvider extends ChangeNotifier {
  String _userRole = 'customer'; // 'customer' or 'provider'
  String _currentStatusState = 'Fuera de servicio'; // 'En línea', 'Ocupado...', 'Fuera de servicio'
  String _selectedBusyHours = 'indefinido';
  
  double _currentLat = -33.4489;
  double _currentLng = -70.6693;
  
  DateTime _lastActivityTime = DateTime.now();
  bool _isAvailable = false;
  
  // Active trackers and streams
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _inactivityTimer;
  Timer? _pingTimer;
  Timer? _busyExpirationTimer;

  // Getters
  String get userRole => _userRole;
  String get currentStatusState => _currentStatusState;
  String get selectedBusyHours => _selectedBusyHours;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  bool get isAvailable => _isAvailable;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  AppStateProvider() {
    _loadLocalRole();
    _loadLocalTheme();
  }

  // --- INITIALIZATION ---
  Future<void> _loadLocalRole() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('user_role') ?? 'customer';
    notifyListeners();
  }

  Future<void> _loadLocalTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool val) async {
    _isDarkMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
    notifyListeners();
  }

  Future<void> initializeProviderState(String providerId) async {
    try {
      // 1. Fetch initial status from Supabase
      final profile = await SupabaseService.instance.getUserProfile(providerId);
      if (profile != null) {
        // Find if provider entry exists
        final providers = await SupabaseService.instance.getProviders();
        final currentProv = providers.firstWhere((p) => p.id == providerId, orElse: () => throw Exception());
        _currentStatusState = currentProv.status;
        _isAvailable = (_currentStatusState == 'En línea' || _currentStatusState.startsWith('Ocupado'));
      }
    } catch (_) {
      _currentStatusState = 'Fuera de servicio';
      _isAvailable = false;
    }

    if (_userRole == 'customer') {
      // Force offline if customer
      await updateAvailabilityState('Fuera de servicio');
      await startGpsTracking();
    } else if (_userRole == 'provider') {
      // Initialize pings/inactivity if provider
      startActivityTracker();
      if (_isAvailable) {
        startGpsTracking();
      }
    }
    notifyListeners();
  }

  // --- SWITCH ROLE ---
  Future<void> switchRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    if (role == 'customer') {
      // Force offline
      stopActivityTracker();
      await updateAvailabilityState('Fuera de servicio');
      await startGpsTracking();
    } else {
      // Reset activity and tracker
      resetActivityTimer();
      startActivityTracker();
      await updateAvailabilityState('En línea');
    }
    notifyListeners();
  }

  // --- UPDATE AVAILABILITY STATE ---
  Future<void> updateAvailabilityState(String status) async {
    _currentStatusState = status;
    _isAvailable = (status == 'En línea' || status.startsWith('Ocupado'));

    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      await SupabaseService.instance.updateProviderAvailability(
        providerId: userId,
        status: status,
        lat: _isAvailable ? _currentLat : null,
        lng: _isAvailable ? _currentLng : null,
      );
    }

    if (_isAvailable) {
      startGpsTracking();
    } else {
      stopGpsTracking();
    }
    notifyListeners();
  }

  // --- GPS LOCATION TRACKING ---
  Future<void> startGpsTracking() async {
    if (_gpsSubscription != null) return;

    final hasPerm = await LocationService.instance.handlePermission();
    if (!hasPerm) return;

    // Get initial position
    final initialPos = await LocationService.instance.getCurrentPosition();
    if (initialPos != null) {
      _currentLat = initialPos.latitude;
      _currentLng = initialPos.longitude;
      notifyListeners();
    }

    // Subscribe to continuous updates
    _gpsSubscription = LocationService.instance.getPositionStream().listen((pos) async {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      notifyListeners();

      // Update Supabase with new location (throttled) - ONLY IF PROVIDER
      if (_userRole == 'provider') {
        final userId = SupabaseService.instance.currentUser?.id;
        if (userId != null) {
          await SupabaseService.instance.updateProviderAvailability(
            providerId: userId,
            status: _currentStatusState,
            lat: _currentLat,
            lng: _currentLng,
          );
        }
      }
    });
  }

  void stopGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  // --- INACTIVITY & PRESENCE TIMERS ---
  void resetActivityTimer() {
    _lastActivityTime = DateTime.now();
  }

  void startActivityTracker() {
    stopActivityTracker();

    // 1. Inactivity checking loop (every 30 seconds)
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final isBusy = _currentStatusState.startsWith('Ocupado');
      if (_isAvailable && !isBusy) {
        final diff = DateTime.now().difference(_lastActivityTime);
        if (diff.inMinutes >= 15) {
          print("Inactivity detected (15 mins). Going Offline.");
          await updateAvailabilityState('Fuera de servicio');
          // Show inactivity alert in the active UI
          _showInactivityDialog();
        }
      }
    });

    // 2. Active presence ping (every 2 minutes)
    _pingTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      final userId = SupabaseService.instance.currentUser?.id;
      if (_isAvailable && userId != null) {
        print("Sending presence ping...");
        await SupabaseService.instance.updateProviderAvailability(
          providerId: userId,
          status: _currentStatusState,
          lat: _currentLat,
          lng: _currentLng,
        );
      }
    });

    // 3. Busy status expiration check (every 10 seconds)
    _busyExpirationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_currentStatusState.startsWith('Ocupado|')) {
        final parts = _currentStatusState.split('|');
        if (parts.length > 1) {
          final expireTime = DateTime.parse(parts[1]);
          if (DateTime.now().isAfter(expireTime)) {
            print("Busy timer completed. Returning to Available.");
            _selectedBusyHours = 'indefinido';
            await updateAvailabilityState('En línea');
          }
        }
      }
    });
  }

  void stopActivityTracker() {
    _inactivityTimer?.cancel();
    _pingTimer?.cancel();
    _busyExpirationTimer?.cancel();
    _inactivityTimer = null;
    _pingTimer = null;
    _busyExpirationTimer = null;
  }

  void updateSelectedBusyHours(String hrs) {
    _selectedBusyHours = hrs;
    notifyListeners();
  }

  // Hook to show inactivity popup in current context
  Function? onInactivityDetected;

  void _showInactivityDialog() {
    if (onInactivityDetected != null) {
      onInactivityDetected!();
    }
  }

  @override
  void dispose() {
    stopGpsTracking();
    stopActivityTracker();
    super.dispose();
  }
}
