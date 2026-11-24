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

  String get formattedDuration {
    final secs = duration.round();
    final mins = (secs ~/ 60).toString();
    final rem = (secs % 60).toString().padLeft(2, '0');
    return '$mins:$rem';
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    final dur = json['duration'] ?? json['durationSeconds'];
    final double durationVal = dur is num
        ? dur.toDouble()
        : (double.tryParse(dur?.toString() ?? '') ?? 0);

    String cover = json['coverUrl']?.toString() ??
        json['thumbnailUrl']?.toString() ??
        json['imageUrl']?.toString() ??
        '';
    if (cover.isEmpty && json['thumbnails'] is Map) {
      final thumbs = Map<String, dynamic>.from(json['thumbnails'] as Map);
      cover = thumbs['md']?.toString() ??
          thumbs['sm']?.toString() ??
          thumbs['lg']?.toString() ??
          '';
    }

    String audio = json['audioUrl']?.toString() ??
        json['streamUrl']?.toString() ??
        json['url']?.toString() ??
        '';
    if (audio.isEmpty && json['files'] is Map) {
      final files = Map<String, dynamic>.from(json['files'] as Map);
      audio = files['mp3']?.toString() ?? files['audio']?.toString() ?? '';
    }

    final waveRaw = json['waveform'];
    final waveform = waveRaw is List
        ? waveRaw.map((e) => (e as num).toInt()).toList()
        : <int>[];

    return MusicTrack(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      artist: json['artist']?.toString() ??
          json['artistName']?.toString() ??
          'Unknown Artist',
      duration: durationVal,
      coverUrl: cover,
      audioUrl: audio,
      category: json['category']?.toString() ?? 'All',
      waveform: waveform,
    );
  }
}