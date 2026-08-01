import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  CancelFunc? _cancelToast;
  bool _isOffline = false;

  void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool noInternet = result.contains(ConnectivityResult.none) || result.isEmpty;
      
      if (noInternet && !_isOffline) {
        _isOffline = true;
        _showOfflineToast();
      } else if (!noInternet && _isOffline) {
        _isOffline = false;
        _hideOfflineToast();
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        _isOffline = true;
        _showOfflineToast();
      }
    });
  }

  void _showOfflineToast() {
    _cancelToast = BotToast.showCustomNotification(
      toastBuilder: (void Function() cancelFunc) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF991B1B), // Dark Red
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sin conexión a internet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Revisa tu conexión. Algunas funciones pueden no estar disponibles.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: cancelFunc,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
        );
      },
      duration: const Duration(days: 365), // practically infinite until internet returns
      onlyOne: true,
      crossPage: true,
      align: const Alignment(0, -0.95), // Top
    );
  }

  void _hideOfflineToast() {
    if (_cancelToast != null) {
      _cancelToast!();
      _cancelToast = null;
      
      // Show online notification briefly
      BotToast.showCustomNotification(
        toastBuilder: (void Function() cancelFunc) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46), // Dark Green
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Conexión restaurada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        duration: const Duration(seconds: 3),
        align: const Alignment(0, -0.95),
      );
    }
  }
}
