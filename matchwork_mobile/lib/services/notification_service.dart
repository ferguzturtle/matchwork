import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matchwork_mobile/services/supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejar mensajes en segundo plano si es necesario
  print("Manejando un mensaje en segundo plano: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Solicitar permisos (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido.');
    }

    // 2. Inicializar Local Notifications para Android/Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(settings: initializationSettings);

    // 3. Manejar notificaciones cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    // 4. Registrar manejador de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("Error obteniendo FCM token: $e");
      return null;
    }
  }

  Future<void> saveTokenToDatabase(String userId) async {
    final token = await getFCMToken();
    if (token != null) {
      await SupabaseService.instance.updateUserProfile(userId, {
        'fcm_token': token,
      });
      print("Token FCM guardado para el usuario $userId");
    }
  }

  Future<void> _showLocalNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'matchwork_channel',
      'Matchwork Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title ?? 'Nueva notificación',
      body: body ?? '',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<String> _getAccessToken() async {
    final String jsonString = await rootBundle.loadString('assets/service-account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  Future<void> sendPushNotification(String fcmToken, String title, String body, {Map<String, dynamic>? data}) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/service-account.json');
      final Map<String, dynamic> serviceAccount = json.decode(jsonString);
      final String projectId = serviceAccount['project_id'];

      final String accessToken = await _getAccessToken();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notificación enviada correctamente');
      } else {
        print('Error enviando notificación: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
    } catch (e) {
      print('Error al enviar la notificación: $e');
    }
  }
}
