import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/reels/presentation/widgets/talent_rating_slider.dart';

class TalentRatingScreen extends StatefulWidget {
  const TalentRatingScreen({super.key, this.reelId});

  final String? reelId;

  @override
  State<TalentRatingScreen> createState() => _TalentRatingScreenState();
}

class _TalentRatingScreenState extends State<TalentRatingScreen> {
  double _ratingValue = 5;
  bool _success = false;

  Map<String, dynamic> get _reel =>
      ReelHelpers.reelById(widget.reelId ?? 'r1')!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reelId = widget.reelId ?? 'r1';
      final reelsCubit = context.read<ReelsCubit>();
      final userRating = reelsCubit.getUserRating(reelId);
      final video = reelsCubit.getVideo(reelId) ?? _reel;

      double initialRating = userRating ?? 5.0;
      if (userRating == null) {
        if (video['userRating'] != null) {
          initialRating = double.tryParse(video['userRating'].toString()) ?? 5.0;
        } else if (video['score'] != null) {
          initialRating = double.tryParse(video['score'].toString()) ?? 5.0;
        } else if (video['rating'] != null) {
          initialRating = double.tryParse(video['rating'].toString()) ?? 5.0;
        } else if (video['talentScore'] is num) {
          initialRating = (video['talentScore'] as num).toDouble();
        } else if (video['ratings'] is List && (video['ratings'] as List).isNotEmpty) {
          for (final item in (video['ratings'] as List)) {
            if (item is Map && item['score'] != null) {
              final parsed = double.tryParse(item['score'].toString());
              if (parsed != null && parsed > 0) {
                initialRating = parsed;
                break;
              }
            }
          }
        }
      }

      setState(() {
        _ratingValue = initialRating.clamp(0.0, 10.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reel = _reel;
    final impact = ReelHelpers.ratingImpact((reel['talentScore'] as num).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: reel['imageUrl'] as String,
            fit: BoxFit.cover,
            alt: reel['title'] as String? ?? '',
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              color: const Color(0xB8080414),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _success ? _buildSuccess() : _buildForm(reel, impact),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Map<String, dynamic> reel, int impact) {
    return Container(
      key: const ValueKey('form'),
      height: MediaQuery.sizeOf(context).height * 0.7,
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
      child: Column(
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
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, size: 15, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Column(
                children: [
                  RatingPanelHeader(impact: impact),
                  const SizedBox(height: 14),
                  _PreviewCard(reel: reel),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Impact',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                        Text(
                          '🔥 $impact',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    );
  }

  Widget _buildSuccess() {
    return Container(
      key: const ValueKey('success'),
      height: MediaQuery.sizeOf(context).height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1132), Color(0xFF150C2B)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
            onPressed: () => context.go('${AppRoutes.videoDetail}?id=${_reel['id']}'),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.reel});

  final Map<String, dynamic> reel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AppNetworkImage(
              url: reel['imageUrl'] as String,
              fit: BoxFit.cover,
              alt: reel['title'] as String? ?? '',
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
                CircleAvatar(
                  radius: 13,
                  backgroundImage: NetworkImage(reel['avatarUrl'] as String),
                ),
                const SizedBox(width: 7),
                Text(
                  reel['handle'] as String? ?? '',
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
                _Stat(icon: Icons.favorite, value: reel['likes'] as String? ?? ''),
                const SizedBox(height: 14),
                _Stat(icon: Icons.chat_bubble_outline, value: reel['comments'] as String? ?? ''),
                const SizedBox(height: 14),
                _Stat(icon: Icons.share_outlined, value: reel['shares'] as String? ?? ''),
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
