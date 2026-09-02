import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FreeToUseTrack {
  final String id;
  final String title;
  final String artist;
  final double duration;
  final String coverUrl;
  final String audioUrl;
  final List<int> waveform;
  final String category;

  FreeToUseTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverUrl,
    required this.audioUrl,
    required this.waveform,
    required this.category,
  });

  factory FreeToUseTrack.fromJson(
    Map<String, dynamic> json, {
    bool includeWaveform = false,
  }) {
    String artistName = 'Unknown Artist';
    try {
      if (json['artists'] is List && (json['artists'] as List).isNotEmpty) {
        final firstArtistTuple = (json['artists'] as List).first;
        if (firstArtistTuple is List && firstArtistTuple.length > 1) {
          final artistMap = firstArtistTuple[1];
          if (artistMap is Map && artistMap.containsKey('name')) {
            artistName = artistMap['name'].toString();
          }
        }
      }
    } catch (_) {}

    String catName = 'All';
    try {
      if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
        final firstCatTuple = (json['categories'] as List).first;
        if (firstCatTuple is List && firstCatTuple.length > 1) {
          final catMap = firstCatTuple[1];
          if (catMap is Map && catMap.containsKey('name')) {
            catName = catMap['name'].toString();
          }
        }
      }
    } catch (_) {}

    String cover = '';
    if (json['thumbnails'] is Map) {
      final thumbs = json['thumbnails'] as Map;
      cover = thumbs['md']?.toString() ?? thumbs['sm']?.toString() ?? thumbs['lg']?.toString() ?? '';
    }
    if (cover.isEmpty) {
      cover = 'https://data.freetouse.com/music/tracks/${json['id']}/cover/webp/md/cover-md.webp';
    }

    String stream = '';
    if (json['files'] is Map) {
      final files = json['files'] as Map;
      stream = files['mp3']?.toString() ?? '';
    }
    if (stream.isEmpty) {
      stream = 'https://data.freetouse.com/music/tracks/${json['id']}/file/mp3/file.mp3';
    }

    List<int> waveList = [];
    if (includeWaveform && json['waveform'] is List) {
      waveList = (json['waveform'] as List).map((e) => (e as num).toInt()).toList();
    }

    final durNum = json['duration'] as num? ?? 120;

    return FreeToUseTrack(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Track',
      artist: artistName,
      duration: durNum.toDouble(),
      coverUrl: cover,
      audioUrl: stream,
      waveform: waveList,
      category: catName,
    );
  }

  String get formattedDuration {
    final mins = (duration ~/ 60).toString();
    final secs = (duration.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

List<FreeToUseTrack> parseMusicTracksFromJson(String body) {
  const maxTracks = 200;

  try {
    final bodyJson = jsonDecode(body);
    if (bodyJson is! Map || bodyJson['data'] is! List) return const [];

    final tracks = <FreeToUseTrack>[];
    for (final item in bodyJson['data'] as List) {
      if (tracks.length >= maxTracks) break;
      if (item is! Map) continue;

      try {
        final track = FreeToUseTrack.fromJson(
          Map<String, dynamic>.from(item),
          includeWaveform: false,
        );
        if (track.id.isNotEmpty) {
          tracks.add(track);
        }
      } catch (_) {}
    }
    return tracks;
  } catch (e) {
    debugPrint('parseMusicTracksFromJson error: $e');
    return const [];
  }
}

class MusicApiService {
  static const String _endpoint = 'https://api.freetouse.com/v3/music/tracks/all';
  static const int maxCachedTracks = 200;
  static List<FreeToUseTrack>? _cachedTracks;
  static Future<List<FreeToUseTrack>>? _inflight;

  static List<FreeToUseTrack>? get cachedTracks => _cachedTracks;

  /// Starts loading tracks in the background so the music screen opens instantly.
  static void prefetchTracks() {
    if (_cachedTracks != null || _inflight != null) return;
    fetchTracks();
  }

  static Future<List<FreeToUseTrack>> fetchTracks({bool forceRefresh = false}) async {
    if (_cachedTracks != null && !forceRefresh) {
      return _cachedTracks!;
    }

    if (_inflight != null && !forceRefresh) {
      return _inflight!;
    }

    _inflight = _fetchFromNetwork(forceRefresh);
    try {
      return await _inflight!;
    } finally {
      _inflight = null;
    }
  }

  static Future<List<FreeToUseTrack>> _fetchFromNetwork(bool forceRefresh) async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ArtableApp/1.0',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final tracks = await compute(parseMusicTracksFromJson, response.body);
        if (tracks.isNotEmpty) {
          _cachedTracks = tracks;
          return tracks;
        }
      }
    } catch (e) {
      debugPrint('MusicApiService fetch error: $e');
    }

    return _cachedTracks ?? fallbackTracks;
  }

  static List<FreeToUseTrack> get fallbackTracks => _getFallbackTracks();

  static List<FreeToUseTrack> _getFallbackTracks() {
    return [
      FreeToUseTrack(
        id: 'fallback-1',
        title: 'Harbour Ambient',
        artist: 'Johny Grimes',
        duration: 167,
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 7 + 12) % 100),
        category: 'Ambient',
      ),
      FreeToUseTrack(
        id: 'fallback-2',
        title: 'Chill Chillout Vibe',
        artist: 'Wave Collective',
        duration: 145,
        coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 11 + 20) % 95),
        category: 'Chill',
      ),
      FreeToUseTrack(
        id: 'fallback-3',
        title: 'Summer Pop Beat',
        artist: 'Aria Beats',
        duration: 180,
        coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 13 + 5) % 100),
        category: 'Pop',
      ),
      FreeToUseTrack(
        id: 'fallback-4',
        title: 'Easy Sunday Groove',
        artist: 'Lofi Horizons',
        duration: 152,
        coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 9 + 15) % 90),
        category: 'Easy Listening',
      ),
      FreeToUseTrack(
        id: 'fallback-5',
        title: 'Acoustic Sunrise',
        artist: 'Nico Sound',
        duration: 195,
        coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 15 + 8) % 100),
        category: 'Ambient',
      ),
      FreeToUseTrack(
        id: 'fallback-6',
        title: 'Midnight Lounge',
        artist: 'Velvet Beats',
        duration: 160,
        coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300',
        audioUrl: 'https://data.freetouse.com/music/tracks/2eb6c87d-2352-4961-8054-1a9963766e2e/file/mp3/file.mp3',
        waveform: List.generate(40, (i) => (i * 17 + 3) % 95),
        category: 'Chill',
      ),
    ];
  }
}
