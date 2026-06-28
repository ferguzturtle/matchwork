import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';
import '../screens/client_map_screen.dart';
import '../screens/provider_panel_screen.dart';
import '../screens/conversations_list_screen.dart';
import '../screens/auth_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);

    final appState = Provider.of<AppStateProvider>(context);
    final user = SupabaseService.instance.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Usuario de MatchWork';
    final userEmail = user?.email ?? '';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with Avatar and User Name
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: surfaceNavy,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            accountEmail: Row(
              children: [
                Expanded(
                  child: Text(
                    userEmail,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VERIFICADO',
                    style: TextStyle(color: surfaceNavy, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Menu Items
          ListTile(
            leading: const Icon(Icons.explore, color: surfaceNavy),
            title: const Text('Explorar (Mapa)', style: TextStyle(fontWeight: FontWeight.bold)),
            selected: appState.userRole == 'customer',
            onTap: () {
              Navigator.pop(context); // Close drawer
              if (appState.userRole != 'customer') {
                appState.switchRole('customer');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientMapScreen()),
                );
              }
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.chat, color: surfaceNavy),
            title: const Text('Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationsListScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.assignment, color: surfaceNavy),
            title: const Text('Solicitudes (Trabajador)', style: TextStyle(fontWeight: FontWeight.bold)),
            selected: appState.userRole == 'provider',
            onTap: () async {
              Navigator.pop(context); // Close drawer
              if (appState.userRole != 'provider') {
                await appState.switchRole('provider');
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
              }
            },
          ),
          
          const Divider(),
          
          // Switch Role Toggle
          ListTile(
            leading: const Icon(Icons.switch_account, color: accentBlue),
            title: Text(
              appState.userRole == 'customer' ? 'Cambiar a Prestador' : 'Cambiar a Cliente',
              style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer
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
          
          const Spacer(),
          
          const Divider(),
          
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.pop(context); // Close drawer
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
}
