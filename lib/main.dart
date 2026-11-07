import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/storage/local_storage.dart';
import 'app/app.dart';
import 'data/datasources/music_api_service.dart';

void main() async {
  // 1. Ensure Flutter Engine binding is initialized before async startup tasks
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  // Prevent any transient native video player platform / texture ID teardown race from crashing UI
  final originalErrorBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final str = details.exceptionAsString();
    if (str.contains('No active player with ID') ||
        str.contains('VideoPlayerController')) {
      debugPrint('Suppressed VideoPlayer platform race: $str');
      return Container(
        color: const Color(0xFF150C2B),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7A33EB),
            strokeWidth: 3,
          ),
        ),
      );
    }
    return originalErrorBuilder(details);
  };

  // 2. Firebase only on the critical path — FCM/permissions after first frame
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 3. Preserve native splash screen until critical fonts are ready
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // 4. Disable Google Fonts runtime HTTP fetching to force bundled local asset usage
  GoogleFonts.config.allowRuntimeFetching = false;

  // 5. Preload only the faces used on splash / first paint
  await _preloadCriticalFonts();

  // 6. Capture cold-start App Link / custom scheme before first navigation.
  try {
    await DeepLinkService.start();
  } catch (e) {
    debugPrint('DeepLinkService init warning: $e');
  }

  // 7. Initialize application
  runApp(const ArtableApp());

  // 8. Background warm-up after first frame (does not block Home)
  unawaited(_warmAfterFirstFrame());

  // 9. Remove native splash once critical fonts are ready
  FlutterNativeSplash.remove();
}

Future<void> _warmAfterFirstFrame() async {
  // Let the first frames paint, then warm non-critical assets / services.
  await Future<void>.delayed(Duration.zero);
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService deferred init warning: $e');
  }
  unawaited(_preloadRemainingFonts());
  MusicApiService.prefetchTracks();
}

/// Faces needed for splash / shell chrome before first paint.
Future<void> _preloadCriticalFonts() async {
  try {
    final poppins = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
    await poppins.load();
  } catch (e) {
    debugPrint('Critical font preloading note: $e');
  }
}

/// Remaining faces after first paint (weights used deeper in the app).
Future<void> _preloadRemainingFonts() async {
  try {
    final poppinsExtra = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-ExtraBold.ttf'));
    final interLoader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    await Future.wait([poppinsExtra.load(), interLoader.load()]);
  } catch (e) {
    debugPrint('Deferred font preloading note: $e');
  }
}
