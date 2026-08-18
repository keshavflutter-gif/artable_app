import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class MusicPreviewScreen extends StatefulWidget {
  const MusicPreviewScreen({super.key, this.trackId});

  final String? trackId;

  @override
  State<MusicPreviewScreen> createState() => _MusicPreviewScreenState();
}

class _MusicPreviewScreenState extends State<MusicPreviewScreen> {
  var _playing = false;
  var _saved = false;
  late final Map<String, dynamic> _track;
  late final List<Map<String, dynamic>> _relatedTracks;

  // Generate static wave heights to mimic an audio waveform
  final List<double> _waveHeights = List.generate(42, (index) {
    return 10.0 + (math.sin(index * 0.4).abs() * 25.0) + (math.cos(index * 0.9).abs() * 10.0);
  });

  @override
  void initState() {
    super.initState();
    _track = MockData.MUSIC_LIBRARY_TRACKS.firstWhere(
      (x) => x['id'] == widget.trackId,
      orElse: () => MockData.MUSIC_LIBRARY_TRACKS.first,
    );
    _saved = _track['saved'] as bool? ?? false;
    
    // Pick other tracks as related ones
    _relatedTracks = MockData.MUSIC_LIBRARY_TRACKS
        .where((x) => x['id'] != _track['id'])
        .take(2)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _track['title'] as String? ?? 'Neon Nights';
    final artist = _track['artist'] as String? ?? 'Wave Riders';
    final coverUrl = _track['coverUrl'] as String? ?? '';
    final duration = _track['duration'] as String? ?? '2:45';

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Music Preview'),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // Album Cover Image
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E2EAA).withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: AppImage(
                            url: coverUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Song Details
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF8B849C),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Player Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E2EAA).withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Waveform visualization
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _waveHeights.map((h) {
                              return Container(
                                width: 3.2,
                                height: h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EAFD),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Timeline labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '0:00',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFB5ADC8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                duration,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFB5ADC8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Play Button
                          GestureDetector(
                            onTap: () => setState(() => _playing = !_playing),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5487).withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions buttons (Use This Music & Saved toggle)
                    Row(
                      children: [
                        // Use This Music Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected "$title" for your video.'),
                                  backgroundColor: const Color(0xFF8B3DFF),
                                ),
                              );
                              context.pop();
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5487).withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Use This Music',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Saved Toggle Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _saved = !_saved),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _saved ? const Color(0xFFFF3D77) : const Color(0xFFECE8F5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    color: _saved ? const Color(0xFFFF3D77) : const Color(0xFF8B849C),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _saved ? 'Saved' : 'Save',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: _saved ? const Color(0xFFFF3D77) : const Color(0xFF8B849C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // "Related Tracks" Section
                    const Text(
                      'Related Tracks',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Related Tracks list
                    Column(
                      children: _relatedTracks.map((track) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppImage(
                                  url: track['coverUrl'] as String? ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track['title'] as String? ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF241E38),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      track['artist'] as String? ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF8B849C),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                track['duration'] as String? ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFB5ADC8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Small play circular button
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3EAFD),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF8B3DFF),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
