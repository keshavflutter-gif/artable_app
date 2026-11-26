import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/reels/presentation/widgets/talent_rating_slider.dart';

class TalentRatingScreen extends StatelessWidget {
  const TalentRatingScreen({
    super.key,
    this.reelId,
    this.initialReelData,
  });

  final String? reelId;
  final Map<String, dynamic>? initialReelData;

  /// Opens the talent rating UI as a modal bottom sheet over the caller screen.
  static Future<void> showBottomSheet(
    BuildContext context, {
    required Map<String, dynamic> reel,
  }) {
    final id = (reel['id'] ?? reel['_id'] ?? '').toString();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _TalentRatingSheetBody(
        reelId: id.isNotEmpty ? id : null,
        initialReelData: reel,
        isBottomSheet: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsCubit = context.read<ReelsCubit>();
    final id = reelId?.trim() ?? '';
    final reel = initialReelData ??
        (id.isNotEmpty ? reelsCubit.getVideo(id) : null) ??
        (id.isNotEmpty
            ? ReelHelpers.reelById(id, availableReels: reelsCubit.state.videos)
            : null) ??
        <String, dynamic>{'id': id};
    final imageUrl = reel['imageUrl']?.toString() ??
        reel['thumbnailUrl']?.toString() ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: imageUrl,
            fit: BoxFit.cover,
            alt: reel['title']?.toString() ?? '',
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              color: const Color(0xB8080414),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TalentRatingSheetBody(
              reelId: reelId,
              initialReelData: initialReelData,
              isBottomSheet: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _TalentRatingSheetBody extends StatefulWidget {
  const _TalentRatingSheetBody({
    this.reelId,
    this.initialReelData,
    required this.isBottomSheet,
  });

  final String? reelId;
  final Map<String, dynamic>? initialReelData;
  final bool isBottomSheet;

  @override
  State<_TalentRatingSheetBody> createState() => _TalentRatingSheetBodyState();
}

class _TalentRatingSheetBodyState extends State<_TalentRatingSheetBody> {
  double _ratingValue = 5;
  bool _success = false;

  Map<String, dynamic> get _reel {
    final id = widget.reelId?.trim() ?? '';
    final reelsCubit = context.read<ReelsCubit>();
    if (widget.initialReelData != null) {
      return widget.initialReelData!;
    }
    if (id.isNotEmpty) {
      final fromCubit = reelsCubit.getVideo(id);
      if (fromCubit != null) return fromCubit;
      final fromHelper = ReelHelpers.reelById(
        id,
        availableReels: reelsCubit.state.videos,
      );
      if (fromHelper != null) return fromHelper;
    }
    return <String, dynamic>{'id': id};
  }

  void _closeSheet() {
    if (widget.isBottomSheet) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        '${AppRoutes.videoDetail}?id=${_reel['id'] ?? _reel['_id'] ?? widget.reelId ?? ''}',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ratingValue = _resolveInitialRating();
  }

  double _resolveInitialRating() {
    final reelId = widget.reelId?.trim() ?? '';
    final reelsCubit = context.read<ReelsCubit>();
    final userRating = reelId.isNotEmpty ? reelsCubit.getUserRating(reelId) : null;
    if (userRating != null && userRating > 0) {
      return userRating.clamp(0.0, 10.0);
    }

    final video = (reelId.isNotEmpty ? reelsCubit.getVideo(reelId) : null) ?? _reel;
    for (final key in ['userRating', 'averageRating', 'score', 'rating', 'talentScore']) {
      final raw = video[key];
      if (raw == null) continue;
      final parsed = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
      if (parsed != null && parsed > 0) {
        return parsed.clamp(0.0, 10.0);
      }
    }

    if (video['ratings'] is List && (video['ratings'] as List).isNotEmpty) {
      for (final item in (video['ratings'] as List)) {
        if (item is Map && item['score'] != null) {
          final parsed = double.tryParse(item['score'].toString());
          if (parsed != null && parsed > 0) {
            return parsed.clamp(0.0, 10.0);
          }
        }
      }
    }

    return 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final reel = _reel;
    final rawScore = reel['talentScore'];
    final score = rawScore is num
        ? rawScore.toDouble()
        : (double.tryParse('${rawScore ?? ''}') ?? 0.0);
    final impact = ReelHelpers.ratingImpact(score);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _success ? _buildSuccess() : _buildForm(reel, impact),
    );
  }

  Widget _buildForm(Map<String, dynamic> reel, int impact) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Container(
      key: const ValueKey('form'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1132), Color(0xFF150C2B)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _closeSheet,
                  icon: const Icon(Icons.close, size: 15, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingPanelHeader(impact: impact),
                    const SizedBox(height: 14),
                    _PreviewCard(reel: reel),
                    const SizedBox(height: 18),
                    TalentRatingSlider(
                      initialValue: _ratingValue,
                      onChanged: (v) => setState(() => _ratingValue = v),
                    ),
                    RatingSubmitButton(
                      label: 'Submit Rating',
                      onPressed: () {
                        final rId = widget.reelId ?? _reel['id']?.toString() ?? 'r1';
                        context.read<ReelsCubit>().rateVideo(rId, _ratingValue);
                        setState(() => _success = true);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your rating helps decide the winner',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.65;
    return Container(
      key: const ValueKey('success'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1132), Color(0xFF150C2B)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RatingSuccessBadge(score: _ratingValue.toStringAsFixed(1), large: true),
            const SizedBox(height: 18),
            const Text(
              'Rating Submitted!',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thanks for helping decide this challenge's winner.",
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            RatingSubmitButton(
              label: 'Back to Reel',
              onPressed: _closeSheet,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.reel});

  final Map<String, dynamic> reel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = reel['imageUrl']?.toString() ??
        reel['thumbnailUrl']?.toString() ??
        '';
    final avatarUrl = reel['avatarUrl']?.toString().trim() ?? '';

    return SizedBox(
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AppNetworkImage(
              url: imageUrl,
              fit: BoxFit.cover,
              alt: reel['title']?.toString() ?? '',
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                if (avatarUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 13,
                    backgroundImage: NetworkImage(avatarUrl),
                  )
                else
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                const SizedBox(width: 7),
                Text(
                  reel['handle']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 12,
            bottom: 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _Stat(icon: Icons.favorite, value: '${reel['likes'] ?? 0}'),
                const SizedBox(height: 14),
                _Stat(icon: Icons.chat_bubble_outline, value: '${reel['comments'] ?? 0}'),
                const SizedBox(height: 14),
                _Stat(icon: Icons.share_outlined, value: '${reel['shares'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
