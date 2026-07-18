import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'client_map_screen.dart';
import 'conversations_list_screen.dart';
import 'auth_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _savedLocations = [];
  List<Map<String, dynamic>> _hiredWorkers = [];

  bool _isEditingName = false;
  final _nameController = TextEditingController();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId != null) {
      // Load Profile
      final profile = await SupabaseService.instance.getUserProfile(userId);
      // Load Locations
      final locs = await SupabaseService.instance.getUserLocations(userId);
      // Load Hired Workers (accepted service requests)
      List<Map<String, dynamic>> hired = [];
      try {
        final List<dynamic> data = await SupabaseService.instance.client
            .from('service_requests')
            .select('*, providers(*)')
            .eq('customer_id', userId)
            .eq('status', 'aceptado');
        hired = List<Map<String, dynamic>>.from(data);
      } catch (e) {
        debugPrint('Error loading hired workers: $e');
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _savedLocations = locs;
          _hiredWorkers = hired;
          _nameController.text = profile?['name'] ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.updateUserProfile(userId, {'name': newName});
      setState(() {
        _isEditingName = false;
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre actualizado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar nombre: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;
    
    setState(() => _isUploadingPhoto = true);
    
    try {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last;
      
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception("Usuario no autenticado");

      final url = await SupabaseService.instance.uploadProfileImage(userId, bytes, extension);
      if (url != null) {
        await SupabaseService.instance.updateUserProfile(userId, {'avatar_url': url});
        await _loadData(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto actualizada correctamente')),
          );
        }
      } else {
        throw Exception("No se pudo obtener la URL de la imagen");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showAddLocationDialog() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Agregar Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (Ej. Mi Casa, Trabajo)',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSearching
                      ? null
                      : () async {
                          final label = labelCtrl.text.trim();
                          final address = addressCtrl.text.trim();
                          if (label.isEmpty || address.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor completa todos los campos')),
                            );
                            return;
                          }

                          setState(() => isSearching = true);

                          // Geocoding Nominatim
                          double lat = -33.4489;
                          double lng = -70.6693;
                          try {
                            final query = Uri.encodeComponent('$address, Chile');
                            final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
                            final response = await http.get(url, headers: {'User-Agent': 'MatchWorkMobileApp'});
                            if (response.statusCode == 200) {
                              final List<dynamic> results = json.decode(response.body);
                              if (results.isNotEmpty) {
                                lat = double.parse(results[0]['lat']);
                                lng = double.parse(results[0]['lon']);
                              }
                            }
                          } catch (e) {
                            debugPrint('Geocoding error: $e');
                          }

                          final userId = SupabaseService.instance.currentUser?.id;
                          if (userId != null) {
                            final success = await SupabaseService.instance.saveUserLocation(
                              userId: userId,
                              label: label,
                              address: address,
                              lat: lat,
                              lng: lng,
                            );
                            if (success) {
                              await _loadData();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ubicación "$label" guardada con éxito')),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditLocationDialog(Map<String, dynamic> location) {
    final labelCtrl = TextEditingController(text: location['label']);
    final addressCtrl = TextEditingController(text: location['address']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Nombre', counterText: '', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Dirección', counterText: '', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final address = addressCtrl.text.trim();
                if (label.isEmpty || address.isEmpty) return;

                Navigator.pop(context);
                setState(() => _isLoading = true);

                try {
                  final success = await SupabaseService.instance.updateUserLocation(
                    locationId: location['id'].toString(),
                    label: label,
                    address: address,
                  );

                  if (success) {
                    await _loadData();
                  }
                } catch (e) {
                  debugPrint('Error updating location: $e');
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLocation(Map<String, dynamic> location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ubicación'),
        content: Text('¿Estás seguro que deseas eliminar "${location['label']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // location['id'] podria ser un int, aseguramos pasarlo como String
        final success = await SupabaseService.instance.deleteUserLocation(location['id'].toString());
        if (success) {
          await _loadData();
        }
      } catch (e) {
        debugPrint('Error deleting location: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      setState(() => _isLoading = true);
      await appState.performLogoutCleanup();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.isDarkMode;

    final name = _userProfile?['name'] ?? 'Usuario';
    final email = SupabaseService.instance.currentUser?.email ?? '';
    final avatarUrl = _userProfile?['avatar_url'] ??
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        title: const Text('MatchWork', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile Identity Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: CachedNetworkImageProvider(avatarUrl),
                            ),
                            if (_isUploadingPhoto)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name block
                        if (!_isEditingName) ...[
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() => _isEditingName = true),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Editar Nombre'),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                                icon: const Icon(Icons.photo_camera, size: 16),
                                label: const Text('Editar Foto'),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: 'Ingresa tu nombre',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveName,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                                  child: const Text('Guardar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() {
                                    _isEditingName = false;
                                    _nameController.text = name;
                                  }),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                            ],
                          )
                        ],

                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Saved Locations Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF2563EB)),
                          title: const Text('Direcciones Guardadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                            onPressed: _showAddLocationDialog,
                          ),
                        ),
                        const Divider(height: 1),
                        if (_savedLocations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No tienes direcciones guardadas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _savedLocations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final loc = _savedLocations[index];
                              return ListTile(
                                title: Text(loc['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(loc['address'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showEditLocationDialog(loc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () => _deleteLocation(loc),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Saved Services Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          leading: Icon(Icons.bookmark, color: Color(0xFF2563EB)),
                          title: Text('Servicios Guardados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Divider(height: 1),
                        Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No tienes servicios guardados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Contracted Workers Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ListTile(
                          leading: Icon(Icons.history, color: Color(0xFF2563EB)),
                          title: Text('Trabajadores Contratados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const Divider(height: 1),
                        if (_hiredWorkers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Aún no has contratado a ningún trabajador.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _hiredWorkers.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final request = _hiredWorkers[index];
                              final provider = request['providers'] as Map<String, dynamic>?;
                              final pName = provider?['name'] ?? 'Proveedor';
                              final pProfession = provider?['profession'] ?? 'Especialista';
                              final pImage = provider?['image'] ??
                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(pImage),
                                  onBackgroundImageError: (e, s) => debugPrint('Error image: $e'),
                                ),
                                title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(pProfession),
                                trailing: const Icon(Icons.verified, color: Colors.green, size: 20),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Logout Button
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFEE2E2),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF991B1B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ClientMapScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
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
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
