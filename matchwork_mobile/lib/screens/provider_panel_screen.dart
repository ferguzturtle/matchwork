import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/request_model.dart';
import '../providers/app_state_provider.dart';
import 'chat_screen.dart';
import 'conversations_list_screen.dart';
import 'provider_profile_screen.dart';
import '../widgets/app_drawer.dart';

class ProviderPanelScreen extends StatefulWidget {
  const ProviderPanelScreen({super.key});

  @override
  State<ProviderPanelScreen> createState() => _ProviderPanelScreenState();
}

class _ProviderPanelScreenState extends State<ProviderPanelScreen> {
  final MapController _miniMapController = MapController();
  List<ServiceRequestModel> _requests = [];
  bool _isLoadingRequests = false;

  Timer? _refreshTimer;
  RealtimeChannel? _requestsChannel;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _setupRealtimeRequests();

    // Polling de respaldo cada 5 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRequestsSilent();
    });
    
    // Set up hook to show inactivity dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.onInactivityDetected = () {
        _showInactivityDialog();
      };
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_requestsChannel != null) {
      SupabaseService.instance.client.removeChannel(_requestsChannel!);
    }
    super.dispose();
  }

  void _setupRealtimeRequests() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    _requestsChannel = SupabaseService.instance.client
        .channel('provider-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'service_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint("Nueva solicitud detectada en tiempo real: ${payload.newRecord}");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Tienes una nueva solicitud de servicio!'),
                  backgroundColor: Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                ),
              );
              _loadRequestsSilent();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadRequestsSilent() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await SupabaseService.instance.getProviderRequests(userId);
      if (mounted) {
        setState(() {
          _requests = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests silently: $e');
    }
  }

  Future<void> _loadRequests() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingRequests = true);
    final data = await SupabaseService.instance.getProviderRequests(userId);
    setState(() {
      _requests = data;
      _isLoadingRequests = false;
    });
  }

  void _showInactivityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.timer_off, color: Colors.amber),
            SizedBox(width: 8),
            Text('Fuera de Servicio'),
          ],
        ),
        content: const Text(
          'Hemos cambiado tu estado a "Fuera de servicio" debido a que no has interactuado con la aplicación en los últimos 15 minutos.'
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final appState = Provider.of<AppStateProvider>(context, listen: false);
              appState.resetActivityTimer();
              await appState.updateAvailabilityState('En línea');
            },
            child: const Text('Volver a Activar'),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(ServiceRequestModel req) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.currentStatusState.startsWith('Ocupado')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Acción Bloqueada'),
          content: const Text(
            'Estás en modo "Ocupado". No puedes aceptar nuevos trabajos hasta volver a estar Disponible.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final success = await SupabaseService.instance.acceptServiceRequest(req.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Solicitud Aceptada!')),
      );
      _loadRequests();
      // Go to Chat Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              providerId: req.providerId,
              providerName: req.userName ?? 'Cliente',
              chatWithCustomerId: req.customerId,
            ),
          ),
        );
      }
    }
  }

  void _rejectRequest(ServiceRequestModel req) async {
    final success = await SupabaseService.instance.rejectServiceRequest(req.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud Rechazada.')),
      );
      _loadRequests();
    }
  }

  String _formatStatusText(String status) {
    if (status == 'En línea') return 'Disponible para Trabajos';
    if (status.startsWith('Ocupado')) {
      final parts = status.split('|');
      if (parts.length > 1) {
        final date = DateTime.parse(parts[1]).toLocal();
        final minutes = date.minute.toString().padLeft(2, '0');
        return 'Ocupado (Hasta las ${date.hour}:$minutes)';
      }
      return 'Ocupado (Indefinido)';
    }
    return 'Fuera de Servicio';
  }

  Color _getStatusDotColor(String status) {
    if (status == 'En línea') return const Color(0xFF10B981);
    if (status.startsWith('Ocupado')) return Colors.amber;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);

    final appState = Provider.of<AppStateProvider>(context);
    final status = appState.currentStatusState;

    return GestureDetector(
      onTap: () => appState.resetActivityTimer(), // Reset activity timer on interaction
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: surfaceNavy,
          foregroundColor: Colors.white,
          title: const Text('Panel del Prestador', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // 1. Availability Picker Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusDotColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatStatusText(status),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: surfaceNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segmented Choices
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Disponible')),
                          selected: status == 'En línea',
                          onSelected: (val) async {
                            if (val) {
                              appState.updateSelectedBusyHours('indefinido');
                              await appState.updateAvailabilityState('En línea');
                            }
                          },
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: status == 'En línea' ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Ocupado')),
                          selected: status.startsWith('Ocupado'),
                          onSelected: (val) async {
                            if (val) {
                              appState.updateSelectedBusyHours('indefinido');
                              await appState.updateAvailabilityState('Ocupado');
                            }
                          },
                          selectedColor: Colors.amber,
                          labelStyle: TextStyle(
                            color: status.startsWith('Ocupado') ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Desconectado')),
                          selected: status == 'Fuera de servicio',
                          onSelected: (val) async {
                            if (val) {
                              appState.updateSelectedBusyHours('indefinido');
                              await appState.updateAvailabilityState('Fuera de servicio');
                            }
                          },
                          selectedColor: Colors.grey,
                          labelStyle: TextStyle(
                            color: status == 'Fuera de servicio' ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Colapsable Duration Selector (if Ocupado)
                  if (status.startsWith('Ocupado')) ...[
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Duración del estado ocupado:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1', '2', '4', '8', 'indefinido'].map((hrs) {
                        final label = hrs == 'indefinido' ? 'Indef' : '${hrs}h';
                        final isSel = appState.selectedBusyHours == hrs;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (val) async {
                            if (val) {
                              appState.updateSelectedBusyHours(hrs);
                              if (hrs == 'indefinido') {
                                await appState.updateAvailabilityState('Ocupado');
                              } else {
                                final expireTime = DateTime.now().add(Duration(hours: int.parse(hrs)));
                                await appState.updateAvailabilityState('Ocupado|${expireTime.toUtc().toIso8601String()}');
                              }
                            }
                          },
                          selectedColor: surfaceNavy,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // 2. Mini Map representing Provider location (if available)
            if (appState.isAvailable)
              Container(
                height: 180,
                color: Colors.white,
                child: FlutterMap(
                  mapController: _miniMapController,
                  options: MapOptions(
                    initialCenter: LatLng(appState.currentLat, appState.currentLng),
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(appState.currentLat, appState.currentLng),
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3. Incoming Service Requests list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Solicitudes de Servicio',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: surfaceNavy),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadRequests,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _isLoadingRequests
                          ? const Center(child: CircularProgressIndicator())
                          : _requests.isEmpty
                              ? const Center(child: Text('No tienes solicitudes entrantes'))
                              : ListView.builder(
                                  itemCount: _requests.length,
                                  itemBuilder: (context, index) {
                                    final req = _requests[index];
                                    final isPending = req.status == 'pendiente';
                                    
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  req.userName ?? 'Cliente de MatchWork',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: req.status == 'aceptado'
                                                        ? const Color(0xFFECFDF5)
                                                        : req.status == 'pendiente'
                                                            ? Colors.blue[50]
                                                            : Colors.red[50],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    req.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                      color: req.status == 'aceptado'
                                                          ? const Color(0xFF10B981)
                                                          : req.status == 'pendiente'
                                                              ? Colors.blue
                                                              : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              req.message,
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                            if (isPending) ...[
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () => _rejectRequest(req),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: Colors.redAccent,
                                                        side: const BorderSide(color: Colors.redAccent),
                                                      ),
                                                      child: const Text('Rechazar'),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () => _acceptRequest(req),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: status.startsWith('Ocupado')
                                                            ? Colors.grey
                                                            : accentBlue,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: const Text('Aceptar'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
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
          currentIndex: 1,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
              );
            } else if (index == 2) {
              final userId = SupabaseService.instance.currentUser?.id;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderProfileScreen(providerId: userId),
                  ),
                );
              }
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Mensajes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Solicitudes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
