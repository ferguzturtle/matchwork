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

  User? get currentUser => client.auth.currentUser;

  // --- PROFILES ---
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await client.from('profiles').select().eq('id', userId).single();
      return data;
    } catch (e) {
      print("Error getting profile: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await client.from('profiles').update(updates).eq('id', userId);
  }

  // --- PROVIDERS ---
  Future<List<ProviderModel>> getProviders() async {
    try {
      final List<dynamic> data = await client.from('providers').select();
      return data.map((json) => ProviderModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print("Error getting providers: $e");
      return [];
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

  Future<List<Map<String, dynamic>>> getUserLocations(String userId) async {
    try {
      final List<dynamic> data = await client
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error getting user locations: $e");
      return [];
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
      return true;
    } catch (e) {
      print("Error saving user location: $e");
      return false;
    }
  }
}
