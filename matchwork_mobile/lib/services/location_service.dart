import 'package:geolocator/geolocator.dart';

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
