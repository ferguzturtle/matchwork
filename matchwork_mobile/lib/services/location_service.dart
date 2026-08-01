import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  // Check permissions and request if necessary
  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    // Always check/request permission even if service is disabled, 
    // as browsers and some devices need the prompt to trigger the service.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Prominent Disclosure for Google Play
      final context = navigatorKey.currentContext;
      if (context != null) {
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Uso de Ubicación'),
              ],
            ),
            content: const Text(
              'MatchWork recopila datos de ubicación para poder mostrar tu disponibilidad a los clientes en el mapa de servicios de forma precisa, incluso si la app está cerrada o no está en uso.\n\nEsta función es esencial para que los clientes puedan encontrarte cuando estás en estado "Disponible".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), 
                  foregroundColor: Colors.white,
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (proceed != true) return false;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // If permission granted but GPS is physically off, try to open settings (works on mobile)
    if (!serviceEnabled) {
      try {
        await Geolocator.openLocationSettings();
      } catch (e) {
        print("Could not open location settings: $e");
      }
    }

    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, // Mejor precisión posible
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print("Error getting current position: $e");
      return null;
    }
  }

  // Stream of location updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Mejor precisión posible
        distanceFilter: 2, // Actualizar cada 2 metros (antes estaba en 10m)
      ),
    );
  }
}
