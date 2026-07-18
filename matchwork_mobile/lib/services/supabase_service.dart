import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_model.dart';
import '../models/request_model.dart';
import '../models/categories_data.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // --- AUTHENTICATION ---
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? category,
    String? subcategory,
  }) async {
    final AuthResponse res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
      },
    );

    final user = res.user;
    if (user != null) {
      String profession = "Trabajador General";
      if (role == 'provider' && subcategory != null) {
        profession = getProfessionLabel(subcategory);
      }

      // Seed profile table
      await client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'email': email,
        'role': role,
        'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        'profession': role == 'customer' ? '' : profession,
        'category': role == 'customer' ? '' : (category ?? ''),
        'subcategory': role == 'customer' ? '' : (subcategory ?? ''),
        'description': role == 'customer' ? '' : 'Sin descripción disponible.',
        'price': role == 'customer' ? '' : '\$0',
      });

      // If provider, also seed provider availability immediately
      if (role == 'provider') {
        await client.from('providers').upsert({
          'id': user.id,
          'name': name,
          'image': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
          'profession': profession,
          'category': category ?? '',
          'subcategory': subcategory ?? '',
          'rating': 4.9,
          'status': 'En línea',
          'lat': -33.4489,
          'lng': -70.6693,
          'icon': getSubcategoryIcon(subcategory ?? ''),
        });
      }
    }
    return user;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => client.auth.currentUser;

  // --- CACHES ---
  List<ProviderModel>? _cachedProviders;
  DateTime? _lastProvidersFetch;
  
  final Map<String, Map<String, dynamic>> _cachedProfiles = {};
  final Map<String, DateTime> _lastProfileFetch = {};

  final Map<String, List<Map<String, dynamic>>> _cachedLocations = {};
  final Map<String, DateTime> _lastLocationsFetch = {};

  void clearProvidersCache() => _cachedProviders = null;
  void clearProfileCache(String userId) => _cachedProfiles.remove(userId);
  void clearLocationsCache(String userId) => _cachedLocations.remove(userId);

  // --- PROFILES ---
  Future<Map<String, dynamic>?> getUserProfile(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfiles.containsKey(userId) && _lastProfileFetch.containsKey(userId)) {
      if (DateTime.now().difference(_lastProfileFetch[userId]!).inMinutes < 5) {
        return _cachedProfiles[userId];
      }
    }
    try {
      final data = await client.from('profiles').select().eq('id', userId).single();
      _cachedProfiles[userId] = data;
      _lastProfileFetch[userId] = DateTime.now();
      return data;
    } catch (e) {
      print("Error getting profile: $e");
      return _cachedProfiles[userId];
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await client.from('profiles').update(updates).eq('id', userId);
    clearProfileCache(userId);
  }

  // --- PROVIDERS ---
  Future<List<ProviderModel>> getProviders({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProviders != null && _lastProvidersFetch != null) {
      if (DateTime.now().difference(_lastProvidersFetch!).inMinutes < 5) {
        return _cachedProviders!;
      }
    }
    try {
      final List<dynamic> data = await client.from('providers').select();
      _cachedProviders = data.map((json) => ProviderModel.fromJson(json as Map<String, dynamic>)).toList();
      _lastProvidersFetch = DateTime.now();
      return _cachedProviders!;
    } catch (e) {
      print("Error getting providers: $e");
      return _cachedProviders ?? [];
    }
  }

  Future<void> updateProviderAvailability({
    required String providerId,
    required String status,
    double? lat,
    double? lng,
  }) async {
    // 1. Get profile data to seed if it's missing in provider
    String name = 'Prestador General';
    String image = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';
    String profession = 'Prestador General';
    String category = 'construccion';
    String subcategory = 'gasfiteria';

    try {
      final profile = await getUserProfile(providerId);
      if (profile != null) {
        name = profile['name'] ?? name;
        image = profile['avatar_url'] ?? image;
        profession = profile['profession'] ?? profession;
        category = profile['category'] ?? category;
        subcategory = profile['subcategory'] ?? subcategory;
      }
    } catch (e) {
      print("Error resolving profile details for provider availability: $e");
    }

    final Map<String, dynamic> updateData = {
      'id': providerId,
      'status': status,
      'name': name,
      'image': image,
      'profession': profession,
      'category': category,
      'subcategory': subcategory,
      'icon': _getSubcategoryIcon(subcategory),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (lat != null && lng != null) {
      updateData['lat'] = lat;
      updateData['lng'] = lng;
    }

    await client.from('providers').upsert(updateData);
  }

  Future<void> updateProviderLocation({
    required String providerId,
    required double lat,
    required double lng,
  }) async {
    try {
      await client.from('providers').update({
        'lat': lat,
        'lng': lng,
      }).eq('id', providerId);
    } catch (e) {
      print("Error updating provider location: $e");
    }
  }

  String _getSubcategoryIcon(String subcategory) {
    switch (subcategory.toLowerCase()) {
      case 'gasfiteria':
        return 'plumbing';
      case 'electricidad':
        return 'bolt';
      case 'limpieza':
        return 'cleaning_services';
      case 'climatizacion':
        return 'ac_unit';
      default:
        return 'construction';
    }
  }

  // --- SERVICE REQUESTS ---
  Future<List<ServiceRequestModel>> getProviderRequests(String providerId) async {
    try {
      final List<dynamic> data = await client
          .from('service_requests')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      final List<ServiceRequestModel> requests = [];
      for (var item in data) {
        final req = ServiceRequestModel.fromJson(item as Map<String, dynamic>);
        // Resolve customer name
        String clientName = 'Cliente de MatchWork';
        final profile = await getUserProfile(req.customerId);
        if (profile != null) {
          clientName = profile['name'] ?? clientName;
        }
        requests.add(req.copyWith(userName: clientName));
      }
      return requests;
    } catch (e) {
      print("Error getting requests: $e");
      return [];
    }
  }

  Future<void> createServiceRequest({
    required String providerId,
    required String customerId,
    required String message,
  }) async {
    await client.from('service_requests').insert({
      'provider_id': providerId,
      'customer_id': customerId,
      'message': message,
      'status': 'pendiente',
    });
  }

  Future<bool> acceptServiceRequest(String requestId) async {
    try {
      await client.from('service_requests').update({'status': 'aceptado'}).eq('id', requestId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectServiceRequest(String requestId) async {
    try {
      await client.from('service_requests').update({'status': 'rechazado'}).eq('id', requestId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIfMatched(String providerId, String customerId) async {
    try {
      final data = await client
          .from('service_requests')
          .select()
          .eq('provider_id', providerId)
          .eq('customer_id', customerId)
          .eq('status', 'aceptado');
      return (data as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkIfPending(String providerId, String customerId) async {
    try {
      final data = await client
          .from('service_requests')
          .select()
          .eq('provider_id', providerId)
          .eq('customer_id', customerId)
          .eq('status', 'pendiente');
      return (data as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // --- MESSAGES ---
  Future<List<Map<String, dynamic>>> getMessages(String senderId, String receiverId) async {
    try {
      final data = await client
          .from('messages')
          .select()
          .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error getting messages: $e");
      return [];
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
    });
  }

  // Realtime subscription helper
  RealtimeChannel subscribeToMessages({
    required String senderId,
    required String receiverId,
    required Function(Map<String, dynamic> message) onNewMessage,
  }) {
    final channel = client.channel('realtime:public:messages');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final recordSender = newRecord['sender_id'] as String;
        final recordReceiver = newRecord['receiver_id'] as String;

        // Verify if message belongs to this conversation
        if ((recordSender == senderId && recordReceiver == receiverId) ||
            (recordSender == receiverId && recordReceiver == senderId)) {
          onNewMessage(newRecord);
        }
      },
    ).subscribe();
    return channel;
  }

  Future<List<Map<String, dynamic>>> getUserLocations(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLocations.containsKey(userId) && _lastLocationsFetch.containsKey(userId)) {
      if (DateTime.now().difference(_lastLocationsFetch[userId]!).inMinutes < 5) {
        return _cachedLocations[userId]!;
      }
    }
    try {
      final List<dynamic> data = await client
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      final locs = List<Map<String, dynamic>>.from(data);
      _cachedLocations[userId] = locs;
      _lastLocationsFetch[userId] = DateTime.now();
      return locs;
    } catch (e) {
      print("Error getting user locations: $e");
      return _cachedLocations[userId] ?? [];
    }
  }

  Future<bool> saveUserLocation({
    required String userId,
    required String label,
    required String address,
    required double lat,
    required double lng,
  }) async {
    try {
      await client.from('user_locations').insert({
        'user_id': userId,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
      });
      clearLocationsCache(userId);
      return true;
    } catch (e) {
      print("Error saving location: $e");
      return false;
    }
  }

  Future<bool> deleteUserLocation(String locationId) async {
    try {
      await client.from('user_locations').delete().eq('id', locationId);
      return true;
    } catch (e) {
      print("Error deleting user location: $e");
      return false;
    }
  }

  Future<bool> updateUserLocation({
    required String locationId,
    required String label,
    required String address,
  }) async {
    try {
      await client.from('user_locations').update({
        'label': label,
        'address': address,
      }).eq('id', locationId);
      return true;
    } catch (e) {
      print("Error updating user location: $e");
      return false;
    }
  }

  Future<bool> saveFeedback(String userId, String comment) async {
    try {
      await client.from('app_feedback').insert({
        'user_id': userId,
        'comment': comment,
        'status': 'nuevo',
      });
      return true;
    } catch (e) {
      print("Error saving feedback: $e");
      return false;
    }
  }

  // --- STORAGE ---
  Future<String?> uploadProfileImage(String userId, Uint8List fileBytes, String fileExtension) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storagePath = '$userId/$fileName';
      
      await client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = client.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // --- NOTIFICATIONS ---
  RealtimeChannel? _notificationsChannel;

  void initializeNotificationsListener() {
    final userId = currentUser?.id;
    if (userId == null) return;

    if (_notificationsChannel != null) {
      client.removeChannel(_notificationsChannel!);
    }

    _notificationsChannel = client.channel('global_notifications_$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'service_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'provider_id',
          value: userId,
        ),
        callback: (payload) {
          BotToast.showSimpleNotification(
            title: "¡Nueva solicitud de servicio!",
            subTitle: "Revisa tu panel de trabajador.",
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green.shade600,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            subTitleStyle: const TextStyle(color: Colors.white),
            hideCloseButton: true,
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: userId,
        ),
        callback: (payload) {
          BotToast.showSimpleNotification(
            title: "¡Nuevo mensaje!",
            subTitle: "Alguien te ha escrito en el chat.",
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF2563EB),
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            subTitleStyle: const TextStyle(color: Colors.white),
            hideCloseButton: true,
          );
        },
      )
      ..subscribe();
  }

  void disposeNotificationsListener() {
    if (_notificationsChannel != null) {
      client.removeChannel(_notificationsChannel!);
      _notificationsChannel = null;
    }
  }
}
