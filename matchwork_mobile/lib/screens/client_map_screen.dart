import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/provider_model.dart';
import '../providers/app_state_provider.dart';
import 'chat_screen.dart';
import 'provider_profile_screen.dart';
import 'conversations_list_screen.dart';
import 'client_profile_screen.dart';
import '../widgets/app_drawer.dart';
import '../models/categories_data.dart';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({super.key});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  final MapController _mapController = MapController();
  
  List<ProviderModel> _allProviders = [];
  String _selectedFilterType = 'all'; // 'all', 'category', 'subcategory'
  String _selectedFilterValue = '';
  String _selectedRadius = 'all'; // 'all', '2', '5', '10', '20'
  bool _isLoadingProviders = false;
  
  ProviderModel? _selectedProvider;
  bool _isMatched = false;
  bool _isPending = false;
  bool _isLoadingStatus = false;

  List<Map<String, dynamic>> _userSavedLocations = [];
  Map<String, dynamic>? _selectedLocation;
  String _selectedLocationName = 'Ubicación GPS Actual';
  
  RealtimeChannel? _providersSubscription;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _loadSavedLocations();
    _setupProvidersSubscription();
  }

  @override
  void dispose() {
    _providersSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupProvidersSubscription() {
    _providersSubscription = SupabaseService.instance.client
        .channel('public:providers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'providers',
          callback: (payload) {
            if (!mounted) return;
            if (payload.eventType == PostgresChangeEvent.update) {
              final newRecord = payload.newRecord;
              if (newRecord != null) {
                setState(() {
                  final index = _allProviders.indexWhere((p) => p.id == newRecord['id']);
                  if (index != -1) {
                    _allProviders[index] = ProviderModel.fromJson(newRecord);
                  }
                });
              }
            } else {
              _loadProvidersSilently();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadProvidersSilently() async {
    final data = await SupabaseService.instance.getProviders();
    if (mounted) {
      setState(() {
        _allProviders = data;
      });
    }
  }

  Future<void> _loadSavedLocations() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      final locs = await SupabaseService.instance.getUserLocations(userId);
      if (mounted) {
        setState(() {
          _userSavedLocations = locs;
        });
      }
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoadingProviders = true);
    final data = await SupabaseService.instance.getProviders();
    setState(() {
      _allProviders = data;
      _isLoadingProviders = false;
    });
  }

  // Haversine Distance Formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  // Filter providers by category & radius
  List<ProviderModel> _getFilteredProviders(double centerLat, double centerLng) {
    return _allProviders.filter((p) {
      if (p.status == 'Fuera de servicio') return false;
      
      bool matchesCategory = true;
      if (_selectedFilterType == 'category') {
        matchesCategory = p.category == _selectedFilterValue;
      } else if (_selectedFilterType == 'subcategory') {
        matchesCategory = p.subcategory == _selectedFilterValue;
      }
      
      bool matchesRadius = true;
      if (_selectedRadius != 'all') {
        final dist = _calculateDistance(centerLat, centerLng, p.lat, p.lng);
        matchesRadius = dist <= double.parse(_selectedRadius);
      }
      
      return matchesCategory && matchesRadius;
    });
  }

  Future<void> _onProviderSelected(ProviderModel p) async {
    setState(() {
      _selectedProvider = p;
      _isMatched = false;
      _isPending = false;
      _isLoadingStatus = true;
    });

    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId != null) {
      final matched = await SupabaseService.instance.checkIfMatched(p.id, currentUserId);
      final pending = await SupabaseService.instance.checkIfPending(p.id, currentUserId);
      if (mounted) {
        setState(() {
          _isMatched = matched;
          _isPending = pending;
          _isLoadingStatus = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  void _sendRequest(ProviderModel p) async {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId == null) return;

    // Show request message input dialog
    final controller = TextEditingController(text: 'Hola, necesito ayuda con un servicio.');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Asistencia'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Mensaje de solicitud',
            counterText: '',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.instance.createServiceRequest(
                providerId: p.id,
                customerId: currentUserId,
                message: controller.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Solicitud enviada!')),
              );
              _onProviderSelected(p); // Refresh card state
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    if (_selectedFilterType == 'all') return 'Todas las Categorías';
    if (_selectedFilterType == 'category') {
      return categories[_selectedFilterValue]?.label ?? _selectedFilterValue;
    }
    // Subcategory: loop to find it
    for (var cat in categories.values) {
      if (cat.subcategories.containsKey(_selectedFilterValue)) {
        return cat.subcategories[_selectedFilterValue]!.label;
      }
    }
    return _selectedFilterValue;
  }

  void _showCategoryExplorer() {
    String? activeCategoryKey;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const surfaceNavy = Color(0xFF0F172A);
            const accentBlue = Color(0xFF2563EB);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : surfaceNavy;

            if (activeCategoryKey == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Explorar Categorías',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.grid_view, color: accentBlue),
                    title: const Text('Todas las Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() {
                        _selectedFilterType = 'all';
                        _selectedFilterValue = '';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: categories.entries.map((e) {
                        IconData catIcon;
                         switch (e.key) {
                          case 'reparaciones_mantenimiento':
                            catIcon = Icons.handyman;
                            break;
                          case 'limpieza_hogar':
                            catIcon = Icons.cleaning_services;
                            break;
                          case 'jardineria_exteriores':
                            catIcon = Icons.yard;
                            break;
                          case 'tecnologia_linea_blanca':
                            catIcon = Icons.computer;
                            break;
                          case 'salud_belleza_bienestar':
                            catIcon = Icons.spa;
                            break;
                          case 'mudanzas_logistica':
                            catIcon = Icons.local_shipping;
                            break;
                          case 'cuidado_mascotas':
                            catIcon = Icons.pets;
                            break;
                          case 'servicios_profesionales':
                            catIcon = Icons.school;
                            break;
                          default:
                            catIcon = Icons.category;
                        }
                        return ListTile(
                          leading: Icon(catIcon, color: textColor),
                          title: Text(e.value.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            setModalState(() {
                              activeCategoryKey = e.key;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            } else {
              final catDetail = categories[activeCategoryKey!]!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: textColor),
                          onPressed: () {
                            setModalState(() {
                              activeCategoryKey = null;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            catDetail.label,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.list, color: accentBlue),
                    title: Text('Ver todo en ${catDetail.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() {
                        _selectedFilterType = 'category';
                        _selectedFilterValue = activeCategoryKey!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: catDetail.subcategories.entries.map((sub) {
                        return ListTile(
                          leading: Icon(_getIconData(sub.value.icon), color: textColor),
                          title: Text(sub.value.label),
                          onTap: () {
                            setState(() {
                              _selectedFilterType = 'subcategory';
                              _selectedFilterValue = sub.key;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'handyman':
        return Icons.handyman;
      case 'plumbing':
        return Icons.plumbing;
      case 'bolt':
        return Icons.bolt;
      case 'vpn_key':
        return Icons.vpn_key;
      case 'construction':
        return Icons.construction;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'home':
        return Icons.home;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'bug_report':
        return Icons.bug_report;
      case 'yard':
        return Icons.yard;
      case 'pool':
        return Icons.pool;
      case 'home_work':
        return Icons.home_work;
      case 'kitchen':
        return Icons.kitchen;
      case 'computer':
        return Icons.computer;
      case 'spa':
        return Icons.spa;
      case 'content_cut':
        return Icons.content_cut;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'weekend':
        return Icons.weekend;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'pets':
        return Icons.pets;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'home_max':
        return Icons.home_max;
      case 'school':
        return Icons.school;
      case 'drive_eta':
        return Icons.drive_eta;
      default:
        return Icons.build;
    }
  }

  String _formatStatusLabel(String status) {
    if (status.startsWith('Ocupado')) {
      final parts = status.split('|');
      if (parts.length > 1) {
        final date = DateTime.parse(parts[1]).toLocal();
        final minutes = date.minute.toString().padLeft(2, '0');
        return 'Ocupado (Hasta las ${date.hour}:$minutes)';
      }
      return 'Ocupado (Indefinido)';
    }
    return 'Disponible';
  }

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appState = Provider.of<AppStateProvider>(context);
    final double searchLat = _selectedLocation != null 
        ? (_selectedLocation!['lat'] as num).toDouble() 
        : appState.currentLat;
    final double searchLng = _selectedLocation != null 
        ? (_selectedLocation!['lng'] as num).toDouble() 
        : appState.currentLng;
    final filtered = _getFilteredProviders(searchLat, searchLng);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : surfaceNavy,
        foregroundColor: Colors.white,
        title: const Text('MatchWork', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: AppDrawer(onAddLocationTap: _showAddLocationDialog),
      body: Stack(
        children: [
          // 1. Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(appState.currentLat, appState.currentLng),
              initialZoom: 14.0,
              onTap: (_, __) {
                setState(() {
                  _selectedProvider = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              
              // Providers markers
              MarkerLayer(
                markers: [
                  // Client position pin (only if using real-time location)
                  if (_selectedLocation == null)
                    Marker(
                      point: LatLng(appState.currentLat, appState.currentLng),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_selectedLocation != null)
                    Marker(
                      point: LatLng(searchLat, searchLng),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),

                  // Providers pins
                  ...filtered.map((p) {
                    final isBusy = p.status.startsWith('Ocupado');
                    final color = isBusy ? Colors.amber[600]! : const Color(0xFF10B981);
                    
                    return Marker(
                      point: LatLng(p.lat, p.lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _onProviderSelected(p),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: Icon(
                                _getIconData(p.icon),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _TrianglePainter(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Location & Category Selector Header (Column of Pills)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location Selector Dropdown
                GestureDetector(
                  onTap: _showLocationPicker,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _selectedLocationName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : surfaceNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: InkWell(
                    onTap: _showCategoryExplorer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.category, color: accentBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getFilterLabel(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : surfaceNavy,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Radar/Radius Button (Bottom-Right, above card)
          Positioned(
            right: 16,
            bottom: _selectedProvider != null ? 240 : 16,
            child: Column(
              children: [
                // Zoom In Button
                FloatingActionButton(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : surfaceNavy,
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                  },
                ),
                const SizedBox(height: 8),
                // Zoom Out Button
                FloatingActionButton(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : surfaceNavy,
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                  },
                ),
                const SizedBox(height: 12),
                // Radius trigger float button
                FloatingActionButton(
                  heroTag: 'radius_btn',
                  backgroundColor: isDark ? accentBlue : surfaceNavy,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.radar),
                  onPressed: () {
                    // Open a popup menu to select radius
                    showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 400, 16, 100),
                      items: const [
                        PopupMenuItem(value: 'all', child: Text('Todo el mapa')),
                        PopupMenuItem(value: '2', child: Text('Dentro de 2 km')),
                        PopupMenuItem(value: '5', child: Text('Dentro de 5 km')),
                        PopupMenuItem(value: '10', child: Text('Dentro de 10 km')),
                        PopupMenuItem(value: '20', child: Text('Dentro de 20 km')),
                      ],
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          _selectedRadius = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value == 'all' 
                                  ? 'Buscando en todo el mapa' 
                                  : 'Filtrando a $value km a la redonda'
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Fit all providers button
                FloatingActionButton(
                  heroTag: 'fit_all_btn',
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : surfaceNavy,
                  child: const Icon(Icons.zoom_out_map),
                  onPressed: () {
                    if (filtered.isNotEmpty) {
                      double minLat = searchLat;
                      double maxLat = searchLat;
                      double minLng = searchLng;
                      double maxLng = searchLng;

                      for (var p in filtered) {
                        if (p.lat < minLat) minLat = p.lat;
                        if (p.lat > maxLat) maxLat = p.lat;
                        if (p.lng < minLng) minLng = p.lng;
                        if (p.lng > maxLng) maxLng = p.lng;
                      }

                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds(
                            LatLng(minLat, minLng),
                            LatLng(maxLat, maxLng),
                          ),
                          padding: const EdgeInsets.all(50.0),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No hay proveedores disponibles para enfocar')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Recenter map button
                FloatingActionButton(
                  heroTag: 'center_btn',
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : surfaceNavy,
                  child: const Icon(Icons.my_location),
                  onPressed: () {
                    _mapController.move(
                      LatLng(searchLat, searchLng),
                      14.0,
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. Slide up card details (if selected)
          if (_selectedProvider != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 8,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Avatar & Info block
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: CachedNetworkImageProvider(_selectedProvider!.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedProvider!.name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : surfaceNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedProvider!.profession,
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    // Row with Pin icon, distance, and Status Badge
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${_calculateDistance(appState.currentLat, appState.currentLng, _selectedProvider!.lat, _selectedProvider!.lng).toStringAsFixed(1)} km',
                                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 8),
                                        // Status Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _selectedProvider!.status.startsWith('Ocupado')
                                                ? Colors.amber[50]
                                                : const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _selectedProvider!.status.startsWith('Ocupado')
                                                  ? Colors.amber[200]!
                                                  : const Color(0xFFA7F3D0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: _selectedProvider!.status.startsWith('Ocupado')
                                                      ? Colors.amber
                                                      : const Color(0xFF10B981),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatStatusLabel(_selectedProvider!.status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _selectedProvider!.status.startsWith('Ocupado')
                                                      ? Colors.amber[800]
                                                      : const Color(0xFF065F46),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 2. Buttons: Solicitar and Ver Perfil
                          Row(
                            children: [
                              // Solicitar Button
                              if (_isLoadingStatus) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    label: const Text('Cargando...', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ] else if (_isMatched) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            providerId: _selectedProvider!.id,
                                            providerName: _selectedProvider!.name,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Hablar', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ] else if (_isPending) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.hourglass_empty, size: 18),
                                    label: const Text('Esperando solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _sendRequest(_selectedProvider!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.handshake, size: 18),
                                    label: const Text('Solicitar', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              // Ver Perfil Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProviderProfileScreen(providerId: _selectedProvider!.id),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Ver Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close Button in top right
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _selectedProvider = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    await _loadSavedLocations();
    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seleccionar Ubicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Current GPS Location Option
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Color(0xFF2563EB)),
                      title: const Text(
                        'Ubicación GPS Actual',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: _selectedLocation == null
                          ? const Icon(Icons.check, color: Color(0xFF2563EB))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocation = null;
                          _selectedLocationName = 'Ubicación GPS Actual';
                        });
                        _mapController.move(
                          LatLng(appState.currentLat, appState.currentLng),
                          14.0,
                        );
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    // Saved User Locations List
                    if (_userSavedLocations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No tienes ubicaciones guardadas.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _userSavedLocations.length,
                          itemBuilder: (context, index) {
                            final loc = _userSavedLocations[index];
                            final isSelected = _selectedLocation != null &&
                                _selectedLocation!['id'] == loc['id'];

                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.red),
                              title: Text(loc['label'] ?? ''),
                              subtitle: Text(loc['address'] ?? 'Sin dirección'),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Color(0xFF2563EB))
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedLocation = loc;
                                  _selectedLocationName = loc['label'] ?? '';
                                });
                                _mapController.move(
                                  LatLng(
                                    (loc['lat'] as num).toDouble(),
                                    (loc['lng'] as num).toDouble(),
                                  ),
                                  14.0,
                                );
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    const Divider(),
                    // Add Location Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Agregar Nueva Ubicación'),
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        _showAddLocationDialog(); // Show dialog to save location
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddLocationDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Guardar Ubicación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Puedes buscar una dirección, o dejarlo en blanco para guardar el punto rojo del mapa.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelController,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la ubicación (Ej: Mi Casa)',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Ej: Av. Providencia 1234, Providencia, Santiago',
                  helperText: 'Formato ideal: Calle + Número, Comuna, Ciudad',
                  helperStyle: TextStyle(color: Colors.blue),
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final label = labelController.text.trim();
                    if (label.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un nombre arriba primero')),
                      );
                      return;
                    }
                    
                    final userId = SupabaseService.instance.currentUser?.id;
                    if (userId == null) return;
                    
                    // Use exact GPS from AppState
                    final appState = Provider.of<AppStateProvider>(context, listen: false);
                    final exactLat = appState.currentLat;
                    final exactLng = appState.currentLng;
                    
                    final success = await SupabaseService.instance.saveUserLocation(
                      userId: userId,
                      label: label,
                      address: 'Ubicación GPS Exacta',
                      lat: exactLat,
                      lng: exactLng,
                    );
                    
                    if (success) {
                      await _loadSavedLocations();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ubicación "$label" (GPS Exacto) guardada')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Usar mi GPS exacto actual', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final label = labelController.text.trim();
                final address = addressController.text.trim();
                if (label.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un nombre para la ubicación')),
                  );
                  return;
                }

                final userId = SupabaseService.instance.currentUser?.id;
                if (userId != null) {
                  double targetLat = _mapController.camera.center.latitude;
                  double targetLng = _mapController.camera.center.longitude;

                  if (address.isNotEmpty) {
                    try {
                      final query = Uri.encodeComponent('$address, Chile');
                      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1');
                      final res = await http.get(url, headers: {'User-Agent': 'MatchWorkMobileApp'});
                      
                      if (res.statusCode == 200) {
                        final data = json.decode(res.body) as List;
                        if (data.isNotEmpty) {
                          targetLat = double.parse(data[0]['lat']);
                          targetLng = double.parse(data[0]['lon']);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se encontró la dirección exacta. Se guardó el centro del mapa.')),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      print("Error geocoding address: $e");
                    }
                  }

                  final success = await SupabaseService.instance.saveUserLocation(
                    userId: userId,
                    label: label,
                    address: address.isNotEmpty ? address : 'Centro del mapa',
                    lat: targetLat,
                    lng: targetLng,
                  );

                  if (success) {
                    await _loadSavedLocations();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ubicación "$label" guardada con éxito')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al guardar la ubicación')),
                      );
                    }
                  }
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }


}

// Custom Painter for pins arrow
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper filter extension
extension FilterExtension<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    final List<T> result = [];
    for (var element in this) {
      if (test(element)) {
        result.add(element);
      }
    }
    return result;
  }
}
