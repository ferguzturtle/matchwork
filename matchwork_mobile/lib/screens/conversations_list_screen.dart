import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  late final String _myId;

  @override
  void initState() {
    super.initState();
    _myId = SupabaseService.instance.currentUser?.id ?? '';
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch all messages involving current user
      final List<dynamic> data = await SupabaseService.instance.client
          .from('messages')
          .select('sender_id, receiver_id, text, created_at')
          .or('sender_id.eq.$_myId,receiver_id.eq.$_myId')
          .order('created_at', ascending: false);

      // 2. Filter unique partners and keep last message
      final Map<String, Map<String, dynamic>> uniqueChats = {};

      for (var item in data) {
        final Map<String, dynamic> msg = item as Map<String, dynamic>;
        final String sender = msg['sender_id'] as String;
        final String receiver = msg['receiver_id'] as String;
        final String partnerId = sender == _myId ? receiver : sender;

        if (!uniqueChats.containsKey(partnerId)) {
          uniqueChats[partnerId] = {
            'partnerId': partnerId,
            'lastMessage': msg['text'] ?? 'Imagen',
            'createdAt': msg['created_at'] as String,
          };
        }
      }

      // 3. Load profile details for each partner
      final List<Map<String, dynamic>> resolvedChats = [];
      for (var chat in uniqueChats.values) {
        String partnerId = chat['partnerId'];
        String name = 'Usuario de MatchWork';
        String avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';

        final profile = await SupabaseService.instance.getUserProfile(partnerId);
        if (profile != null) {
          name = profile['name'] ?? name;
          avatarUrl = profile['avatar_url'] ?? avatarUrl;
        }

        resolvedChats.add({
          ...chat,
          'name': name,
          'avatarUrl': avatarUrl,
        });
      }

      setState(() {
        _conversations = resolvedChats;
      });
    } catch (e) {
      print("Error loading conversation list: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    final isDark = Provider.of<AppStateProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : surfaceNavy,
        foregroundColor: Colors.white,
        title: const Text('Centro de Mensajería', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Sin Conversaciones Activas',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : surfaceNavy),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Haz match con un prestador o cliente desde el mapa para iniciar un chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage: CachedNetworkImageProvider(chat['avatarUrl']),
                      ),
                      title: Text(
                        chat['name'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : surfaceNavy),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          chat['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              providerId: chat['partnerId'],
                              providerName: chat['name'],
                              chatWithCustomerId: chat['partnerId'], // Resolve as partnerId dynamically
                            ),
                          ),
                        ).then((_) => _loadConversations());
                      },
                    );
                  },
                ),
    );
  }
}
