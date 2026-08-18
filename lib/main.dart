import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'data/datasources/music_api_service.dart';

void main() async {
  // 1. Ensure Flutter Engine binding is initialized before async startup tasks
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Preserve native splash screen until font pre-loading is completed
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // 3. Disable Google Fonts runtime HTTP fetching to force bundled local asset usage
  GoogleFonts.config.allowRuntimeFetching = false;

  // 4. Preload font binary assets into native font engine before first frame
  await _preloadFonts();

  // 5. Initialize application
  runApp(const ArtableApp());

  // 6. Prefetch music tracks in background so Add Music screen opens instantly
  MusicApiService.prefetchTracks();

  // 7. Remove native splash screen AFTER fonts are guaranteed loaded and ready
  FlutterNativeSplash.remove();
}

/// Pre-warms native FontLoader with local font assets so frame 0 renders with custom fonts.
Future<void> _preloadFonts() async {
  try {
    final poppinsLoader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-ExtraBold.ttf'));

    final interLoader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));

    await Future.wait([
      poppinsLoader.load(),
      interLoader.load(),
    ]);
  } catch (e) {
    debugPrint('Font preloading note: $e');
  }
}