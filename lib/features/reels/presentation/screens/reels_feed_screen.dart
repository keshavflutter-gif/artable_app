import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/features/reels/presentation/widgets/creator_info_row.dart';
import 'package:artable_app/features/reels/presentation/widgets/talent_rating_slider.dart';

class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  final _pageController = PageController();
  String? _ratingReelId;
  bool _ratingSuccess = false;
  double _ratingValue = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_FeedItem> get _items {
    final cards = MockData.REELS.map(_FeedItem.reel).toList();
    if (cards.length > 3) {
      cards.insert(3, const _FeedItem.ad());
    }
    return cards;
  }

  void _openRating(String reelId) {
    setState(() {
      _ratingReelId = reelId;
      _ratingSuccess = false;
      _ratingValue = 5;
    });
  }

  void _closeRating() {
    setState(() {
      _ratingReelId = null;
      _ratingSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reelsProvider = context.watch<ReelsCubit>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              if (item.isAd) return const _AdReelCard();
              final reel = item.reel!;
              final challenge = ReelHelpers.challengeForReel(reel);
              final liked = reelsProvider.isLiked(reel['id'] as String);
              final saved = reelsProvider.isBookmarked(reel['id'] as String);

              return Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: reel['imageUrl'] as String,
                    fit: BoxFit.cover,
                    alt: reel['title'] as String? ?? '',
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x590A0514),
                          const Color(0x0D0A0514),
                          const Color(0x330A0514),
                          const Color(0xEB06030E),
                        ],
                        stops: const [0, 0.22, 0.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 68,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: ReelHelpers.categoryTint(reel['category'] as String? ?? ''),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        (reel['category'] as String? ?? '').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 128,
                    child: Column(
                      children: [
                        _ActionBtn(
                          icon: liked ? Icons.favorite : Icons.favorite_border,
                          count: reel['likes'] as String? ?? '',
                          active: liked,
                          onTap: () => context.read<ReelsCubit>().toggleLike(reel['id'] as String),
                        ),
                        const SizedBox(height: 18),
                        _ActionBtn(
                          icon: Icons.chat_bubble_outline,
                          count: reel['comments'] as String? ?? '',
                          onTap: () => context.push('${AppRoutes.comments}?id=${reel['id']}'),
                        ),
                        const SizedBox(height: 18),
                        _ActionBtn(
                          icon: Icons.share_outlined,
                          count: reel['shares'] as String? ?? '',
                          onTap: () => context.push('${AppRoutes.shareReport}?id=${reel['id']}'),
                        ),
                        const SizedBox(height: 18),
                        _ActionBtn(
                          icon: saved ? Icons.bookmark : Icons.bookmark_border,
                          count: saved ? 'Saved' : 'Save',
                          active: saved,
                          onTap: () => context.read<ReelsCubit>().toggleBookmark(reel['id'] as String),
                        ),
                        const SizedBox(height: 18),
                        _ActionBtn(
                          icon: Icons.star,
                          count: 'Rate',
                          rateStyle: true,
                          onTap: () => _openRating(reel['id'] as String),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 78,
                    bottom: 26,
                    child: GestureDetector(
                      onTap: () => context.push('${AppRoutes.videoDetail}?id=${reel['id']}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CreatorInfoRow(reel: reel, lightText: true),
                          const SizedBox(height: 8),
                          _MetaRow(
                            icon: Icons.emoji_events_outlined,
                            text: challenge?['title'] as String? ?? '',
                          ),
                          const SizedBox(height: 8),
                          _MetaRow(
                            icon: Icons.music_note,
                            text: reel['musicName'] as String? ?? '',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reel['caption'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _MetaRow(
                            icon: Icons.remove_red_eye_outlined,
                            text: '${reel['views']} views',
                            muted: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xA60A0514),
                    const Color(0x4D0A0514),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏆 Challenge Arena',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        _HeaderIconBtn(icon: Icons.search),
                        const SizedBox(width: 10),
                        _HeaderIconBtn(icon: Icons.notifications_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_ratingReelId != null) _buildRatingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRatingOverlay() {
    final reel = ReelHelpers.reelById(_ratingReelId!)!;
    final impact = ReelHelpers.ratingImpact((reel['talentScore'] as num).toDouble());

    return GestureDetector(
      onTap: _closeRating,
      child: Container(
        color: const Color(0x66080414),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C1132), Color(0xFF150C2B)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                if (!_ratingSuccess) ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: _closeRating,
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.09),
                        minimumSize: const Size(28, 28),
                      ),
                    ),
                  ),
                  RatingPanelHeader(impact: impact, compact: true),
                  const SizedBox(height: 16),
                  TalentRatingSlider(
                    initialValue: _ratingValue,
                    compact: true,
                    onChanged: (v) => setState(() => _ratingValue = v),
                  ),
                  const SizedBox(height: 2),
                  RatingSubmitButton(
                    label: 'Submit Rating',
                    onPressed: () => setState(() => _ratingSuccess = true),
                  ),
                ] else ...[
                  RatingSuccessBadge(score: _ratingValue.toStringAsFixed(1)),
                  const SizedBox(height: 14),
                  Text(
                    "Thanks for helping decide this challenge's winner.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  RatingSubmitButton(label: 'Done', onPressed: _closeRating),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem.reel(this.reel) : isAd = false;
  const _FeedItem.ad() : reel = null, isAd = true;

  final Map<String, dynamic>? reel;
  final bool isAd;
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: muted ? Colors.white.withValues(alpha: 0.75) : const Color(0xFFFFC24D),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: muted ? 0.75 : 1),
              shadows: const [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.count,
    this.onTap,
    this.active = false,
    this.rateStyle = false,
  });

  final IconData icon;
  final String count;
  final VoidCallback? onTap;
  final bool active;
  final bool rateStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? AppGradients.button
                  : rateStyle
                      ? const LinearGradient(
                          colors: [Color(0xFFFFC933), Color(0xFFFF9500)],
                        )
                      : null,
              color: active || rateStyle ? null : Colors.white.withValues(alpha: 0.14),
              border: active || rateStyle
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              icon,
              size: 20,
              color: rateStyle ? const Color(0xFF3A1E00) : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}

class _AdReelCard extends StatelessWidget {
  const _AdReelCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(
          url:
              'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=700&h=1200&q=80&auto=format&fit=crop',
          fit: BoxFit.cover,
          alt: 'ad',
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x590A0514),
                const Color(0xEB06030E),
              ],
            ),
          ),
        ),
        Positioned(
          top: 68,
          left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF170B33),
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Go Prime — Ad-Free Viewing',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Remove ads and get the diamond badge',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D77).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
