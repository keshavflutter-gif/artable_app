import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.duration = 0,
    this.coverUrl = '',
    this.audioUrl = '',
    this.category = 'All',
    this.waveform = const [],
  });

  final String id;
  final String title;
  final String artist;
  final double duration;
  final String coverUrl;
  final String audioUrl;
  final String category;
  final List<int> waveform;

  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    double? duration,
    String? coverUrl,
    String? audioUrl,
    String? category,
    List<int>? waveform,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      waveform: waveform ?? this.waveform,
    );
  }

  String get formattedDuration {
    final secs = duration.round();
    final mins = (secs ~/ 60).toString();
    final rem = (secs % 60).toString().padLeft(2, '0');
    return '$mins:$rem';
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    final dur = json['duration'] ??
        json['durationSeconds'] ??
        json['duration_seconds'] ??
        json['durationSec'] ??
        json['length'];
    double durationVal = 0;
    if (dur is num) {
      durationVal = dur.toDouble();
    } else if (dur is String) {
      if (dur.contains(':')) {
        final parts = dur.split(':');
        if (parts.length == 2) {
          final m = double.tryParse(parts[0]) ?? 0;
          final s = double.tryParse(parts[1]) ?? 0;
          durationVal = (m * 60) + s;
        }
      } else {
        durationVal = double.tryParse(dur) ?? 0;
      }
    }
    if (durationVal > 1000 && durationVal % 1000 == 0) {
      durationVal = durationVal / 1000;
    }

    final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final title = json['title']?.toString() ?? json['name']?.toString() ?? 'Untitled';

    String artistName = json['artist']?.toString() ??
        json['artistName']?.toString() ??
        json['artist_name']?.toString() ??
        '';
    if (artistName.isEmpty && json['artists'] is List && (json['artists'] as List).isNotEmpty) {
      final firstArtist = (json['artists'] as List).first;
      if (firstArtist is List && firstArtist.length > 1 && firstArtist[1] is Map) {
        artistName = (firstArtist[1] as Map)['name']?.toString() ?? '';
      } else if (firstArtist is Map) {
        artistName = firstArtist['name']?.toString() ?? '';
      }
    }
    if (artistName.isEmpty) {
      artistName = 'Unknown Artist';
    }

    String cover = json['coverUrl']?.toString() ??
        json['cover_url']?.toString() ??
        json['thumbnailUrl']?.toString() ??
        json['thumbnail_url']?.toString() ??
        json['imageUrl']?.toString() ??
        json['image_url']?.toString() ??
        json['posterUrl']?.toString() ??
        json['poster_url']?.toString() ??
        json['thumbnail']?.toString() ??
        json['image']?.toString() ??
        json['cover']?.toString() ??
        '';
    if (cover.isEmpty && json['thumbnails'] is Map) {
      final thumbs = Map<String, dynamic>.from(json['thumbnails'] as Map);
      cover = thumbs['md']?.toString() ??
          thumbs['sm']?.toString() ??
          thumbs['lg']?.toString() ??
          '';
    }

    String audio = json['audioUrl']?.toString() ??
        json['audio_url']?.toString() ??
        json['streamUrl']?.toString() ??
        json['stream_url']?.toString() ??
        json['fileUrl']?.toString() ??
        json['file_url']?.toString() ??
        json['musicUrl']?.toString() ??
        json['music_url']?.toString() ??
        json['audio']?.toString() ??
        json['mediaUrl']?.toString() ??
        json['media_url']?.toString() ??
        json['url']?.toString() ??
        '';
    if (audio.isEmpty && json['files'] is Map) {
      final files = Map<String, dynamic>.from(json['files'] as Map);
      audio = files['mp3']?.toString() ??
          files['audio']?.toString() ??
          files['url']?.toString() ??
          files['file']?.toString() ??
          '';
    }
    if (audio.isEmpty && json['file'] is Map) {
      final f = Map<String, dynamic>.from(json['file'] as Map);
      audio = f['url']?.toString() ?? f['path']?.toString() ?? '';
    }
    if (audio.isEmpty && json['music'] is Map) {
      final m = Map<String, dynamic>.from(json['music'] as Map);
      audio = m['url']?.toString() ?? m['audioUrl']?.toString() ?? '';
    }

    // Resolve URLs with baseUrl if relative
    String resolvedCover = MediaUrlUtils.resolve(cover);
    String resolvedAudio = MediaUrlUtils.resolve(audio);

    // Fallbacks if audio or cover is missing
    if (resolvedAudio.isEmpty) {
      final resolved = MusicApiService.resolveByName('$title — $artistName') ??
          MusicApiService.resolveByName(title);
      if (resolved != null && resolved.audioUrl.isNotEmpty) {
        resolvedAudio = resolved.audioUrl;
      } else {
        final fallback = MusicApiService.fallbackTracks;
        if (fallback.isNotEmpty) {
          final idx = id.hashCode.abs() % fallback.length;
          resolvedAudio = fallback[idx].audioUrl;
        }
      }
    }

    if (resolvedCover.isEmpty) {
      final fallback = MusicApiService.fallbackTracks;
      if (fallback.isNotEmpty) {
        final idx = id.hashCode.abs() % fallback.length;
        resolvedCover = fallback[idx].coverUrl;
      }
    }

    final waveRaw = json['waveform'];
    final waveform = waveRaw is List
        ? waveRaw.map((e) => (e as num).toInt()).toList()
        : <int>[];

    return MusicTrack(
      id: id,
      title: title,
      artist: artistName,
      duration: durationVal,
      coverUrl: resolvedCover,
      audioUrl: resolvedAudio,
      category: json['category']?.toString() ?? 'All',
      waveform: waveform,
    );
  }
}