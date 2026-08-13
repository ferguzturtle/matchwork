import '../utils/security_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../providers/app_state_provider.dart';

class ChatScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? chatWithCustomerId; // Opcional, si es el prestador chateando con el cliente
  final bool isUserDeleted;

  const ChatScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.chatWithCustomerId,
    this.isUserDeleted = false,
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
  
  String? _jobStatus;
  RealtimeChannel? _realtimeSubscription;
  RealtimeChannel? _requestsSubscription;

  bool get _isProvider => widget.chatWithCustomerId != null;
  String get _actualProviderId => _isProvider ? _myId : _otherId;
  String get _actualCustomerId => _isProvider ? _otherId : _myId;

  @override
  void initState() {
    super.initState();
    _myId = SupabaseService.instance.currentUser?.id ?? '';
    // If chatWithCustomerId is passed, we are the provider chateando with customer. Otherwise we are customer chateando with provider.
    _otherId = widget.chatWithCustomerId ?? widget.providerId;
    
    _loadMessages();
    _subscribeToNewMessages();
    _loadJobStatus();
    _subscribeToJobStatus();
  }

  Future<void> _loadJobStatus() async {
    final status = await SupabaseService.instance.getJobStatus(_actualProviderId, _actualCustomerId);
    if (mounted) setState(() => _jobStatus = status);
  }

  void _subscribeToJobStatus() {
    _requestsSubscription = SupabaseService.instance.client
        .channel('public:service_requests_chat_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_requests',
            callback: (payload) {
              _loadJobStatus();
            })
        .subscribe();
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
      
      // Enviar notificación push al receptor
      try {
        final receiverProfile = await SupabaseService.instance.getUserProfile(_otherId);
        if (receiverProfile != null && receiverProfile['fcm_token'] != null) {
          final String fcmToken = receiverProfile['fcm_token'];
          
          // Obtener nombre del remitente real desde la base de datos
          final senderProfile = await SupabaseService.instance.getUserProfile(_myId);
          String senderName = 'Usuario';
          if (senderProfile != null && senderProfile['name'] != null && senderProfile['name'].toString().trim().isNotEmpty) {
            senderName = senderProfile['name'];
          }
          
          await NotificationService().sendPushNotification(
            fcmToken,
            'Mensaje de $senderName',
            text,
            data: {'type': 'chat', 'senderId': _myId},
          );
        }
      } catch (e) {
        print("Error enviando notif de chat: $e");
      }

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

  Widget _buildJobActionBanner() {
    if (_jobStatus == null) return const SizedBox.shrink();

    // Soy cliente
    if (!_isProvider) {
      if (_jobStatus == 'aceptado') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Expanded(child: Text('¿Deseas confirmar a este prestador?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              ElevatedButton(
                onPressed: () async {
                  await SupabaseService.instance.requestFormalJob(_actualProviderId, _actualCustomerId);
                  _loadJobStatus();
                },
                child: const Text('Contratar'),
              ),
            ],
          ),
        );
      } else if (_jobStatus == 'solicitud_trabajo') {
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.orange[50],
          child: const Center(child: Text('Esperando a que el proveedor acepte tu solicitud...', style: TextStyle(color: Colors.orange))),
        );
      } else if (_jobStatus == 'trabajando') {
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green[50],
          child: const Center(child: Text('¡El trabajo está en curso!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        );
      } else if (_jobStatus == 'completado') {
          return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.purple[50],
          child: Row(
            children: [
              const Expanded(child: Text('Trabajo finalizado. ¡Califica al proveedor!', style: TextStyle(color: Colors.purple))),
              ElevatedButton(
                onPressed: _showRatingDialog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text('Calificar'),
              ),
            ],
          ),
        );
      }
    } else {
      // Soy proveedor
      if (_jobStatus == 'solicitud_trabajo') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange[50],
          child: Row(
            children: [
              const Expanded(child: Text('Te han enviado una solicitud.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
              ElevatedButton(
                onPressed: () async {
                  await SupabaseService.instance.acceptFormalJob(_actualProviderId, _actualCustomerId);
                  _loadJobStatus();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Aceptar Trabajo'),
              ),
            ],
          ),
        );
      } else if (_jobStatus == 'trabajando') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.green[50],
          child: Row(
            children: [
              const Expanded(child: Text('Trabajo en curso.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              ElevatedButton(
                onPressed: () async {
                  await SupabaseService.instance.finishFormalJob(_actualProviderId, _actualCustomerId);
                  _loadJobStatus();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        );
      } else if (_jobStatus == 'completado') {
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.purple[50],
          child: const Center(child: Text('Trabajo finalizado.', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showRatingDialog() {
    int currentRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Calificar Trabajo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Qué tal fue tu experiencia con el prestador?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () => setStateSB(() => currentRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(inputFormatters: SecurityUtils.secureInputFormatters,
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario o reseña (opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await SupabaseService.instance.submitReview(
                      _actualProviderId,
                      _actualCustomerId,
                      currentRating,
                      commentController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Gracias por tu calificación!'), backgroundColor: Colors.green),
                      );
                    }
                    _loadJobStatus();
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    if (_realtimeSubscription != null) {
      SupabaseService.instance.client.removeChannel(_realtimeSubscription!);
    }
    if (_requestsSubscription != null) {
      SupabaseService.instance.client.removeChannel(_requestsSubscription!);
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
            _buildJobActionBanner(),
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
            SafeArea(
              child: widget.isUserDeleted
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'El usuario ha eliminado su cuenta y no puede recibir mensajes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 10),
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      child: Row(
                        children: [
                    Expanded(
                      child: TextField(inputFormatters: SecurityUtils.secureInputFormatters,
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
            ),
          ],
        ),
      ),
    );
  }
}
