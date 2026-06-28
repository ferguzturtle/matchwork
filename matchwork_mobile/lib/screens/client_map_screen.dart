import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../models/provider_model.dart';
import '../providers/app_state_provider.dart';
import 'chat_screen.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadProviders();
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
    });

    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId != null) {
      final matched = await SupabaseService.instance.checkIfMatched(p.id, currentUserId);
      final pending = await SupabaseService.instance.checkIfPending(p.id, currentUserId);
      setState(() {
        _isMatched = matched;
        _isPending = pending;
      });
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
          decoration: const InputDecoration(
            labelText: 'Mensaje de solicitud',
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

            if (activeCategoryKey == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Explorar Categorías',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: surfaceNavy),
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
                          case 'construccion':
                            catIcon = Icons.construction;
                            break;
                          case 'salud':
                            catIcon = Icons.medical_services;
                            break;
                          case 'instalaciones':
                            catIcon = Icons.engineering;
                            break;
                          case 'mantenimiento':
                            catIcon = Icons.cleaning_services;
                            break;
                          case 'profesionales':
                            catIcon = Icons.support_agent;
                            break;
                          default:
                            catIcon = Icons.category;
                        }
                        return ListTile(
                          leading: Icon(catIcon, color: surfaceNavy),
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
                          icon: const Icon(Icons.arrow_back, color: surfaceNavy),
                          onPressed: () {
                            setModalState(() {
                              activeCategoryKey = null;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            catDetail.label,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: surfaceNavy),
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
                          leading: Icon(_getIconData(sub.value.icon), color: surfaceNavy),
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
      case 'construction':
        return Icons.construction;
      case 'format_paint':
        return Icons.format_paint;
      case 'handyman':
        return Icons.handyman;
      case 'plumbing':
        return Icons.plumbing;
      case 'medical_services':
        return Icons.medical_services;
      case 'physical_therapy':
        return Icons.accessibility_new;
      case 'elderly':
        return Icons.elderly;
      case 'child_care':
        return Icons.child_care;
      case 'bolt':
        return Icons.bolt;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'router':
        return Icons.router;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'pest_control':
        return Icons.bug_report;
      case 'yard':
        return Icons.yard;
      case 'pool':
        return Icons.pool;
      case 'school':
        return Icons.school;
      case 'computer':
        return Icons.computer;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'support_agent':
        return Icons.support_agent;
      case 'engineering':
        return Icons.engineering;
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

    final appState = Provider.of<AppStateProvider>(context);
    final filtered = _getFilteredProviders(appState.currentLat, appState.currentLng);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceNavy,
        foregroundColor: Colors.white,
        title: const Text('MatchWork', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              
              // Providers markers
              MarkerLayer(
                markers: [
                  // Client position pin
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

          // 2. Category Selector Header (Horizontal Scroll)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: InkWell(
                onTap: _showCategoryExplorer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFilterLabel(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Radar/Radius Button (Bottom-Right, above card)
          Positioned(
            right: 16,
            bottom: _selectedProvider != null ? 240 : 16,
            child: Column(
              children: [
                // Radius trigger float button
                FloatingActionButton(
                  heroTag: 'radius_btn',
                  backgroundColor: surfaceNavy,
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
                // Recenter map button
                FloatingActionButton(
                  heroTag: 'center_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: surfaceNavy,
                  child: const Icon(Icons.my_location),
                  onPressed: () {
                    _mapController.move(
                      LatLng(appState.currentLat, appState.currentLng),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(_selectedProvider!.image),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProvider!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: surfaceNavy,
                                  ),
                                ),
                                Text(
                                  _selectedProvider!.profession,
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedProvider!.rating.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_calculateDistance(appState.currentLat, appState.currentLng, _selectedProvider!.lat, _selectedProvider!.lng).toStringAsFixed(1)} km de distancia',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status Badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _selectedProvider!.status.startsWith('Ocupado')
                                        ? Colors.amber
                                        : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatStatusLabel(_selectedProvider!.status),
                                  style: TextStyle(
                                    fontSize: 12,
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
                      const SizedBox(height: 16),
                      // Buttons
                      Row(
                        children: [
                          if (_isMatched) ...[
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
                                ),
                                icon: const Icon(Icons.chat),
                                label: const Text('Chatear'),
                              ),
                            ),
                          ] else if (_isPending) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_empty),
                                label: const Text('Esperando Aceptación...'),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _sendRequest(_selectedProvider!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentBlue,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.send),
                                label: const Text('Solicitar Asistencia'),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
