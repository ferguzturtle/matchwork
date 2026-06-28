import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';
import '../screens/client_map_screen.dart';
import '../screens/provider_panel_screen.dart';
import '../screens/conversations_list_screen.dart';
import '../screens/auth_screen.dart';

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
              children: [
                // Explorar (Mapa)
                _buildDrawerItem(
                  context: context,
                  icon: Icons.explore_outlined,
                  title: 'Explorar',
                  isSelected: appState.userRole == 'customer',
                  textColor: textColor,
                  iconColor: iconColor,
                  activeTileBg: activeTileBg,
                  activeTextColor: activeTextColor,
                  onTap: () {
                    Navigator.pop(context);
                    if (appState.userRole != 'customer') {
                      appState.switchRole('customer');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientMapScreen()),
                      );
                    }
                  },
                ),
                
                // Mensajes
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

                // Perfil
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
                
                // Cambiar a Perfil de Trabajador / Cliente
                _buildDrawerItem(
                  context: context,
                  icon: Icons.contact_mail_outlined,
                  title: appState.userRole == 'customer' 
                      ? 'Cambiar a Perfil de Trabajador' 
                      : 'Cambiar a Perfil de Cliente',
                  isSelected: false,
                  textColor: textColor,
                  iconColor: iconColor,
                  activeTileBg: activeTileBg,
                  activeTextColor: activeTextColor,
                  onTap: () async {
                    Navigator.pop(context);
                    final nextRole = appState.userRole == 'customer' ? 'provider' : 'customer';
                    await appState.switchRole(nextRole);
                    if (nextRole == 'provider') {
                      final userId = SupabaseService.instance.currentUser?.id;
                      if (userId != null) {
                        await appState.initializeProviderState(userId);
                      }
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ProviderPanelScreen()),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientMapScreen()),
                        );
                      }
                    }
                  },
                ),

                // Agregar Ubicación
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

                // Modo Claro / Oscuro
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

                // Dejar Comentarios
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
}
