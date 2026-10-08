import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:artable_app/firebase_options.dart';
import 'package:artable_app/app/routes/app_router.dart';
import 'package:artable_app/app/routes/app_routes.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Must be annotated with @pragma('vm:entry-point') so it can run in background isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase background init error: $e');
  }
  debugPrint('=== FCM Background Message Received ===');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'high_importance_channel';
  static const String _androidChannelName = 'High Importance Notifications';
  static const String _androidChannelDesc = 'Used for urgent app notifications and alerts.';

  bool _isInitialized = false;
  String? _currentToken;

  /// Returns current cached or freshly fetched FCM token.
  String? get currentToken => _currentToken;

  /// Callback function to connect FCM Token with your backend server API.
  Future<void> Function(String token)? onTokenRefreshCallback;

  /// Main initialization entry point.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Set top-level background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Flutter Local Notifications for Foreground display
      await _setupLocalNotifications();

      // 3. Request permissions for iOS & Android 13+
      await requestNotificationPermission();

      // 4. Configure Foreground notification presentation options for iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Fetch and log FCM token
      await getFcmToken();

      // 6. Listen for Token Refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('=== FCM Token Refreshed ===: $newToken');
        _currentToken = newToken;
        if (onTokenRefreshCallback != null) {
          await onTokenRefreshCallback!(newToken);
        }
      });

      // 7. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 8. Listen for Background Notification Taps (when app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapMessage);

      // 9. Check for Initial Message (when app launched from terminated state via notification tap)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('=== FCM Initial Message Received (Terminated state tap) ===');
        // Defer slightly to allow router initialization to complete
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTapMessage(initialMessage);
        });
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Request Notification Permissions (iOS & Android 13+)
  Future<NotificationSettings> requestNotificationPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        debugPrint('User granted notification permission.');
        break;
      case AuthorizationStatus.provisional:
        debugPrint('User granted provisional notification permission.');
        break;
      case AuthorizationStatus.denied:
        debugPrint('User denied notification permission.');
        break;
      case AuthorizationStatus.notDetermined:
        debugPrint('User has not yet determined notification permission.');
        break;
    }
    return settings;
  }

  /// Retrieves the current FCM registration token.
  Future<String?> getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      _currentToken = token;
      debugPrint('====================================================');
      debugPrint('=== CURRENT FCM TOKEN ===');
      debugPrint('$token');
      debugPrint('====================================================');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Set up Local Notifications plugin for Android & iOS foreground notification UI.
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('Local notification payload decode error: $e');
          }
        }
      },
    );

    // Create high-importance Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Handles incoming notifications when app is in FOREGROUND.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('=== FCM Foreground Message Received ===');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      _showLocalNotification(
        id: message.hashCode,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Displays local notification popup when app is in foreground.
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Called when user taps a notification (Background / Terminated state).
  void _handleNotificationTapMessage(RemoteMessage message) {
    debugPrint('=== Notification Tapped ===');
    debugPrint('Data payload: ${message.data}');
    handleNotificationNavigation(message.data);
  }

  /// Parses payload data and routes user to appropriate screen cleanly.
  void handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    try {
      final route = data['route']?.toString().trim();
      final screen = data['screen']?.toString().trim();
      final id = data['id']?.toString().trim();

      debugPrint('Handling notification navigation -> route: $route, screen: $screen, id: $id');

      if (route != null && route.isNotEmpty) {
        appRouter.push(route);
        return;
      }

      if (screen != null && screen.isNotEmpty) {
        switch (screen) {
          case 'notifications':
            appRouter.push(AppRoutes.notifications);
            break;
          case 'home':
            appRouter.go(AppRoutes.home);
            break;
          case 'reels':
          case 'reelsFeed':
            appRouter.go(AppRoutes.reelsFeed);
            break;
          case 'challengeDetail':
          case 'challenge_detail':
            if (id != null && id.isNotEmpty) {
              appRouter.push('${AppRoutes.challengeDetail}?id=$id');
            } else {
              appRouter.push(AppRoutes.categories);
            }
            break;
          case 'videoDetail':
          case 'video_detail':
            if (id != null && id.isNotEmpty) {
              appRouter.push('${AppRoutes.videoDetail}?id=$id');
            } else {
              appRouter.go(AppRoutes.reelsFeed);
            }
            break;
          case 'profile':
            appRouter.go(AppRoutes.profile);
            break;
          case 'rewards':
            appRouter.go(AppRoutes.rewards);
            break;
          case 'rewardDetail':
          case 'reward_detail':
            if (id != null && id.isNotEmpty) {
              appRouter.push('${AppRoutes.rewardDetail}?id=$id');
            } else {
              appRouter.go(AppRoutes.rewards);
            }
            break;
          case 'winners':
            appRouter.go(AppRoutes.winners);
            break;
          case 'trending':
          case 'trendingVideos':
            appRouter.go(AppRoutes.trendingVideos);
            break;
          default:
            debugPrint('Unknown notification screen payload: $screen. Opening notifications screen.');
            appRouter.push(AppRoutes.notifications);
            break;
        }
      } else {
        // Default fallback if no screen/route specified
        appRouter.push(AppRoutes.notifications);
      }
    } catch (e) {
      debugPrint('Notification navigation error: $e');
    }
  }
}
