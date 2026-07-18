import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';

class ChatScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? chatWithCustomerId; // Opcional, si es el prestador chateando con el cliente

  const ChatScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.chatWithCustomerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  late final String _myId;
  late final String _otherId;
  
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _myId = SupabaseService.instance.currentUser?.id ?? '';
    // If chatWithCustomerId is passed, we are the provider chateando with customer. Otherwise we are customer chateando with provider.
    _otherId = widget.chatWithCustomerId ?? widget.providerId;
    
    _loadMessages();
    _subscribeToNewMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getMessages(_myId, _otherId);
    setState(() {
      _messages.addAll(data);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _subscribeToNewMessages() {
    _realtimeSubscription = SupabaseService.instance.subscribeToMessages(
      senderId: _myId,
      receiverId: _otherId,
      onNewMessage: (msg) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      },
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    try {
      await SupabaseService.instance.sendMessage(
        senderId: _myId,
        receiverId: _otherId,
        text: text,
      );
      // Reset inactivity timer in case of provider
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.resetActivityTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_realtimeSubscription != null) {
      SupabaseService.instance.client.removeChannel(_realtimeSubscription!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        appState.resetActivityTimer();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : surfaceNavy,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: accentBlue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.providerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Messages list area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? const Center(child: Text('Inicia la conversación enviando un mensaje.'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg['sender_id'] == _myId;
                            
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? accentBlue : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                                    bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            // Bottom Send Input Box
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 10),
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onTap: () => appState.resetActivityTimer(),
                      onChanged: (_) => appState.resetActivityTimer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
