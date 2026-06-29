import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';
import '../screens/conversations_list_screen.dart';
import '../screens/auth_screen.dart';
import '../models/categories_data.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onAddLocationTap;
  
  const AppDrawer({super.key, this.onAddLocationTap});

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);
    
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.isDarkMode;
    
    final user = SupabaseService.instance.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Usuario de MatchWork';
    final userEmail = user?.email ?? '';

    // Color definitions based on Theme
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerBgColor = isDark ? surfaceNavy : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : surfaceNavy;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];
    final iconColor = isDark ? Colors.white70 : surfaceNavy;
    final activeTileBg = isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF);
    final activeTextColor = isDark ? Colors.white : accentBlue;

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        children: [
          // Header with Avatar and User Name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
            color: headerBgColor,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: accentBlue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verificado',
                            style: TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: appState.userRole == 'customer'
                  ? [
                      // Client Drawer Items
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.explore_outlined,
                        title: 'Explorar',
                        isSelected: true,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: 'Mensajes',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'Perfil',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          _showProfileDialog(context, userName, userEmail);
                        },
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.contact_mail_outlined,
                        title: 'Cambiar a Perfil de Trabajador',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          _handleWorkerRoleSwitch(context, appState);
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.add_location_outlined,
                        title: 'Agregar Ubicación',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          if (onAddLocationTap != null) {
                            onAddLocationTap!();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta opción solo está disponible desde el mapa.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                        title: isDark ? 'Modo Claro' : 'Modo Oscuro',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          appState.toggleTheme(!isDark);
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.rate_review_outlined,
                        title: 'Dejar Comentarios',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          _showFeedbackDialog(context);
                        },
                      ),
                    ]
                  : [
                      // Worker Drawer Items
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: 'Mensajes',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.assignment_outlined,
                        title: 'Solicitudes',
                        isSelected: true,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.switch_account_outlined,
                        title: 'Cambiar a Cliente',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () async {
                          Navigator.pop(context);
                          await appState.switchRole('customer');
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                        title: isDark ? 'Modo Claro' : 'Modo Oscuro',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          appState.toggleTheme(!isDark);
                        },
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.help_outline,
                        title: 'Centro de Ayuda',
                        isSelected: false,
                        textColor: textColor,
                        iconColor: iconColor,
                        activeTileBg: activeTileBg,
                        activeTextColor: activeTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpCenterDialog(context);
                        },
                      ),
                    ],
            ),
          ),
          
          const Divider(),
          
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión', 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context);
              await SupabaseService.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required Color textColor,
    required Color iconColor,
    required Color activeTileBg,
    required Color activeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? activeTileBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? activeTextColor : iconColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeTextColor : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, String name, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Perfil del Cliente'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nombre:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Correo Electrónico:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(email, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              const Text('Estado de Cuenta:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 6),
                  Text('Verificado por MatchWork', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.rate_review, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Dejar Comentario'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cuéntanos tu experiencia o sugerencias para seguir mejorando MatchWork.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu comentario aquí...',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor escribe un comentario')),
                  );
                  return;
                }

                final userId = SupabaseService.instance.currentUser?.id;
                if (userId != null) {
                  final success = await SupabaseService.instance.saveFeedback(userId, comment);
                  if (success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Gracias por tus comentarios!')),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al enviar el comentario')),
                      );
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Centro de Ayuda'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Tienes dudas o problemas con tus servicios?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Contáctanos a soporte técnico:'),
              Text(
                'soporte@matchwork.com',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              SizedBox(height: 16),
              Text(
                'Preguntas Frecuentes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• ¿Cómo recibo pagos? Se acuerda directo con el cliente.'),
              Text('• ¿Cómo aparezco en el mapa? Pon tu estado en "Disponible".'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _handleWorkerRoleSwitch(BuildContext context, AppStateProvider appState) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get database profile to check if user has a category set
      final profile = await SupabaseService.instance.getUserProfile(userId);
      final profileCategory = profile?['category'] as String?;
      final profileSubcategory = profile?['subcategory'] as String?;
      final profileProfession = (profile?['profession'] as String?) ?? 'Especialista';

      // 2. Get saved professions
      final professions = await appState.getUserProfessions(userId);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // 3. If local professions is empty but profile has category, save it as first local profession
      if (professions.isEmpty && profileCategory != null && profileCategory.isNotEmpty) {
        await appState.saveUserProfession(userId, {
          'category': profileCategory,
          'subcategory': profileSubcategory ?? '',
          'profession': profileProfession,
        });
      }

      // Re-fetch professions
      final updatedProfessions = await appState.getUserProfessions(userId);

      if (context.mounted) {
        if (updatedProfessions.isEmpty) {
          // If completely empty, go straight to register dialog
          _showAddProfessionDialog(context, appState, userId);
        } else {
          // Show selection dialog
          _showSelectProfessionDialog(context, appState, userId, updatedProfessions);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar perfil: $e')),
        );
      }
    }
  }

  void _showSelectProfessionDialog(
    BuildContext context,
    AppStateProvider appState,
    String userId,
    List<Map<String, dynamic>> professions,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Seleccionar Oficio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Elige con qué oficio deseas conectarte ahora.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                ...professions.map((prof) {
                  final catKey = prof['category'] ?? '';
                  final subcatKey = prof['subcategory'] ?? '';
                  final profName = prof['profession'] ?? 'Especialista';

                  // Get subcategory icon and label
                  String subcatLabel = subcatKey.replaceAll('_', ' ');
                  IconData iconData = Icons.build_outlined;
                  if (categories[catKey] != null &&
                      categories[catKey]!.subcategories[subcatKey] != null) {
                    subcatLabel = categories[catKey]!.subcategories[subcatKey]!.label;
                    final iconName = categories[catKey]!.subcategories[subcatKey]!.icon;
                    if (iconName == 'plumbing') { iconData = Icons.plumbing; }
                    else if (iconName == 'bolt') { iconData = Icons.bolt; }
                    else if (iconName == 'key') { iconData = Icons.key; }
                    else if (iconName == 'carpenter') { iconData = Icons.handyman; }
                    else if (iconName == 'thermostat') { iconData = Icons.thermostat; }
                    else if (iconName == 'cleaning_services') { iconData = Icons.cleaning_services; }
                    else if (iconName == 'iron') { iconData = Icons.iron; }
                    else if (iconName == 'wash') { iconData = Icons.local_laundry_service; }
                    else if (iconName == 'bug_report') { iconData = Icons.bug_report; }
                    else if (iconName == 'agriculture') { iconData = Icons.agriculture; }
                    else if (iconName == 'pool') { iconData = Icons.pool; }
                    else if (iconName == 'roofing') { iconData = Icons.roofing; }
                    else if (iconName == 'format_paint') { iconData = Icons.format_paint; }
                    else if (iconName == 'construction') { iconData = Icons.construction; }
                    else if (iconName == 'home_repair_service') { iconData = Icons.home_repair_service; }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () async {
                        // Close dialog
                        Navigator.pop(dialogContext);

                        // Show loader
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await appState.setActiveProfession(userId, prof['id']);
                          await appState.switchRole('provider');
                          await appState.initializeProviderState(userId);
                          if (context.mounted) Navigator.pop(context); // Close loader
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cambiar de oficio: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF2563EB),
                              child: Icon(iconData, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subcatLabel,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showAddProfessionDialog(context, appState, userId);
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Agregar nuevo oficio',
                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProfessionDialog(
    BuildContext context,
    AppStateProvider appState,
    String userId,
  ) {
    String? selectedCat = 'reparaciones_mantenimiento';
    String? selectedSubcat = 'gasfiteria';
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Agregar Nuevo Oficio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Define tu nuevo servicio o especialidad para recibir solicitudes.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nombre del Oficio / Título',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Ej. Gasfíter a Domicilio',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Categoría',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: categories.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value.label));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCat = val;
                          if (val != null && categories[val] != null) {
                            selectedSubcat = categories[val]!.subcategories.keys.first;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subcategoría',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedSubcat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: selectedCat == null || categories[selectedCat] == null
                          ? []
                          : categories[selectedCat]!.subcategories.entries.map((e) {
                              return DropdownMenuItem(value: e.key, child: Text(e.value.label));
                            }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSubcat = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = nameController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un título para el oficio')),
                      );
                      return;
                    }
                    if (selectedCat == null || selectedSubcat == null) return;

                    // Close dialog
                    Navigator.pop(dialogContext);

                    // Show loader
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final newProfession = {
                        'category': selectedCat!,
                        'subcategory': selectedSubcat!,
                        'profession': title,
                      };
                      // Save profession locally
                      await appState.saveUserProfession(userId, newProfession);

                      // Get list to find the ID of the newly saved profession
                      final updated = await appState.getUserProfessions(userId);
                      final match = updated.firstWhere(
                        (p) => p['subcategory'] == selectedSubcat && p['profession'] == title,
                        orElse: () => {},
                      );

                      if (match.isNotEmpty) {
                        await appState.setActiveProfession(userId, match['id']);
                      }

                      // Switch role to provider
                      await appState.switchRole('provider');
                      await appState.initializeProviderState(userId);

                      if (context.mounted) Navigator.pop(context); // Close loader
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close loader
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear oficio: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
