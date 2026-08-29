import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/features/shell/presentation/widgets/app_shell.dart';
import 'package:artable_app/features/shell/presentation/widgets/bottom_nav.dart';
import 'package:artable_app/core/widgets/network_image_widget.dart';
import 'package:artable_app/core/widgets/section_header.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_header.dart';
import 'package:artable_app/core/widgets/no_internet_dialog.dart';
import 'package:artable_app/features/home/presentation/bloc/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _heroController = PageController();
  int _heroIndex = 0;
  bool _isNoInternetDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
      final trendingCubit = context.read<TrendingVideosCubit>();
      trendingCubit.loadTrendingVideos(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  bool _isNetworkError(String? msg) {
    if (msg == null || msg.isEmpty) return false;
    final lower = msg.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no internet') ||
        lower.contains('network_error') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('timeoutexception');
  }

  @override
  Widget build(BuildContext context) {
    final megaPromoBanners = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (vm) => vm.megaPromoBanners,
    );
    final heroBannerSlides = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (vm) => vm.heroBannerSlides,
    );
    final activeChallenges = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (vm) => vm.activeChallenges,
    );
    final trendingCubit = context.watch<TrendingVideosCubit>();
    final apiTrendingVideos = trendingCubit.videos;
    final homeCubitTrendingReels = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (vm) => vm.trendingReels,
    );
    final List<Map<String, dynamic>> trendingReels = [];
    final Set<String> seenIds = {};

    for (final item in homeCubitTrendingReels) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        trendingReels.add(item);
      }
    }

    for (final v in apiTrendingVideos) {
      final item = v.toUiMap();
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        trendingReels.add(item);
      }
    }
    final isLoading = context.select<HomeCubit, bool>((vm) => vm.isLoading);
    final hasLoaded = context.select<HomeCubit, bool>((vm) => vm.hasLoaded);
    final quickActions = [
      ...MockData.QUICK_ACTIONS,
      {
        'label': 'View More',
        'icon': 'chevronRight',
        'href': '#',
        'tint': 'viewmore',
      },
    ];

    return AppShell(
      currentPath: AppRoutes.home,
      bottomNavVariant: BottomNavVariant.home,
      body: BlocListener<HomeCubit, HomeState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null &&
            curr.dashboard == null &&
            !curr.isLoading &&
            _isNetworkError(curr.errorMessage),
        listener: (context, state) {
          if (_isNoInternetDialogShowing) return;
          _isNoInternetDialogShowing = true;
          NoInternetDialog.show(
            context,
            onRetry: () {
              _isNoInternetDialogShowing = false;
              context.read<HomeCubit>().loadHomeDashboard(forceRefresh: true);
              context.read<TrendingVideosCubit>().loadTrendingVideos(forceRefresh: true);
            },
          ).then((_) {
            _isNoInternetDialogShowing = false;
          });
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => context
                  .read<HomeCubit>()
                  .loadHomeDashboard(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StudioHeader(),
                  const _SponsoredBanner(),
                  _HeroSlider(
                    controller: _heroController,
                    index: _heroIndex,
                    onPageChanged: (i) => setState(() => _heroIndex = i),
                    apiBannerSlides: heroBannerSlides,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuickStripCard(actions: quickActions),
                        _ActiveChallengesCard(challenges: activeChallenges),
                        SectionHeader(
                          title: '🔥 Trending Reels',
                          viewAllLabel: 'View All',
                          viewAllRoute: AppRoutes.trendingVideos,
                          marginTop: 18,
                        ),
                        _ReelGrid(reels: trendingReels),
                        const SizedBox(height: 26),
                        _MegaPromoScroll(banners: megaPromoBanners),
                      ],
                    ),
                  ),
                  const _DownloadBanner(),
                ],
              ),
            ),
          ),
          if (isLoading && !hasLoaded)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    ),
    );
  }
}

class _SponsoredBanner extends StatelessWidget {
  const _SponsoredBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const ColoredBox(color: Colors.white),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.68,
            child: ClipPath(
              clipper: _DiagonalClipper(),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.5, -0.2),
                    end: Alignment(1, 1),
                    colors: [
                      Colors.white,
                      Colors.white,
                      Color(0xFFE8283F),
                      Color(0xFFC4101F),
                      Color(0xFF1A1A1A),
                    ],
                    stops: [0, 0.08, 0.22, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC24D),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Ad',
                style: AppTypography.body(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2A1300),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.4,
                child: const NetworkImageWidget(
                  url: 'https://images.unsplash.com/photo-1698440235228-9c617924c06e?w=340&h=340&q=80&auto=format&fit=crop',
                  height: 134,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 134,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NEW ARRIVAL',
                              style: AppTypography.body(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B6660),
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Run Faster.\nBe Stronger.',
                              maxLines: 2,
                              style: AppTypography.display(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF17120F),
                                height: 1.22,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x52FF3D77),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                'SHOP NOW',
                                style: AppTypography.body(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 134,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                    Text(
                      'SPORTIFY',
                      style: AppTypography.body(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'UP TO',
                      style: AppTypography.display(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '40% OFF',
                      style: AppTypography.display(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFC24D),
                        height: 1.05,
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.22, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroSlider extends StatelessWidget {
  const _HeroSlider({
    required this.controller,
    required this.index,
    required this.onPageChanged,
    required this.apiBannerSlides,
  });

  final PageController controller;
  final int index;
  final ValueChanged<int> onPageChanged;
  final List<Map<String, dynamic>> apiBannerSlides;

  @override
  Widget build(BuildContext context) {
    final List<Widget> slides;
    if (apiBannerSlides.isNotEmpty) {
      slides = apiBannerSlides.map((slide) {
        final title = slide['title'] as String? ?? '';
        final imageUrl = slide['imageUrl'] as String? ?? '';
        final subtitle = slide['subtitle'] as String? ?? '';
        final cta = slide['cta'] as String? ?? 'Join Now';
        final linkUrl = slide['linkUrl'] as String?;

        void handleBannerTap() {
          if (linkUrl != null && linkUrl.isNotEmpty) {
            if (linkUrl.startsWith('http://') ||
                linkUrl.startsWith('https://')) {
              context.go('/challenges?tab=active');
            } else if (linkUrl.contains('challenges')) {
              context.go('/challenges?tab=active');
            } else if (linkUrl.contains('membership')) {
              context.push(AppRoutes.membershipPlan);
            } else if (linkUrl.contains('invite')) {
              context.push(AppRoutes.inviteFriends);
            } else {
              context.go('/challenges?tab=active');
            }
          } else {
            context.go('/challenges?tab=active');
          }
        }

        if (title.toUpperCase().contains('ONLY YOUR TALENT WINS')) {
          return _HeroMainSlide(
            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            title: title.isNotEmpty ? title : null,
            onJoin: handleBannerTap,
          );
        }

        return _HeroSecondarySlide(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          cta: cta,
          onTap: handleBannerTap,
        );
      }).toList();
    } else {
      slides = <Widget>[
        _HeroMainSlide(
          onJoin: () => context.go('/challenges?tab=active'),
        ),
        _HeroSecondarySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1699730185428-d11054059c7f?w=900&h=700&q=80&auto=format&fit=crop',
          title: 'Invite friends, earn coins',
          subtitle: 'Get bonus wallet coins for every signup',
          cta: 'Invite Now',
          onTap: () => context.push(AppRoutes.inviteFriends),
        ),
      ];
    }

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView(
            controller: controller,
            onPageChanged: onPageChanged,
            children: slides,
          ),
          if (slides.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(slides.length, (i) {
                  final active = i == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(active ? 4 : 3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroMainSlide extends StatelessWidget {
  const _HeroMainSlide({
    this.imageUrl,
    this.title,
    required this.onJoin,
  });

  final String? imageUrl;
  final String? title;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final bannerImg = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : 'https://images.unsplash.com/photo-1752650143719-e1a1d94a02b9?w=700&h=800&q=80&auto=format&fit=crop';

    final bannerTitle = (title != null && title!.isNotEmpty)
        ? title!
        : 'ONLY YOUR\nTALENT WINS!';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF1B0E3E), Color(0xFF2A1560), Color(0xFF170B33)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.6,
            height: 190,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black],
                stops: [0, 0.2],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: NetworkImageWidget(
                url: bannerImg,
                alignment: const Alignment(0, -0.76),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO CELEBRITIES.\nNO FOLLOWER ADVANTAGE.',
                    style: AppTypography.body(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bannerTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFC24D),
                      height: 1.16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'JOIN CHALLENGE',
                                style: AppTypography.display(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1B0E3E),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                size: 10,
                                color: Color(0xFF1B0E3E),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.membershipPlan),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC24D), Color(0xFFFF9F1C)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4DFF9F1C),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, size: 10, color: Color(0xFF2A1600)),
                              const SizedBox(width: 4),
                              Text(
                                'PREMIUM MEMBERSHIP',
                                style: AppTypography.display(
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2A1600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSecondarySlide extends StatelessWidget {
  const _HeroSecondarySlide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkImageWidget(url: imageUrl),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x26140A28),
                const Color(0x0D140A28),
                const Color(0xD10C061A),
              ],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.body(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onTap ?? () => context.push(AppRoutes.membershipPlan),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    cta,
                    style: AppTypography.display(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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

class _QuickStripCard extends StatelessWidget {
  const _QuickStripCard({required this.actions});

  final List<Map<String, dynamic>> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145E2EAA),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: actions.map((action) {
            final tint = action['tint'] as String;
            final href = action['href'] as String;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  final label = action['label'] as String;
                  if (label == 'Upload Video' || href.contains('submit-entry')) {
                    context.push(AppRoutes.submitEntry);
                  } else if (label == 'Active Challenges' || href.contains('challenges')) {
                    context.push('${AppRoutes.challenges}?tab=active');
                  } else if (label == 'Winners') {
                    context.push(AppRoutes.winners);
                  } else if (label == 'Rewards') {
                    context.push(AppRoutes.rewards);
                  } else if (label == 'Invite Friends') {
                    context.push(AppRoutes.inviteFriends);
                  } else if (label == 'Leaderboard') {
                    context.push(AppRoutes.leaderboard);
                  } else if (label == 'Music Library') {
                    context.push(AppRoutes.musicLibrary);
                  } else if (label == 'Trending Videos') {
                    context.push(AppRoutes.trendingVideos);
                  } else if (label == 'Daily Bonus') {
                    context.push(AppRoutes.dailyBonus);
                  } else if (label == 'My Badges') {
                    context.push(AppRoutes.achievements);
                  } else if (label == 'View More') {
                    context.push(AppRoutes.categories);
                  }
                },
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _tintGradient(tint),
                          color: tint == 'viewmore' ? const Color(0x1FE01D5C) : null,
                          boxShadow: tint == 'viewmore'
                              ? null
                              : [
                                  BoxShadow(
                                    color: _tintShadow(tint),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Icon(
                          _iconForAction(action['icon'] as String),
                          size: 22.0,
                          color: tint == 'viewmore' ? const Color(0xFFE01D5C) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 10,
                          fontWeight: tint == 'viewmore' ? FontWeight.w800 : FontWeight.w700,
                          color: tint == 'viewmore' ? const Color(0xFFE01D5C) : const Color(0xFF1E1633),
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  LinearGradient? _tintGradient(String tint) {
    switch (tint) {
      case 'red':
        return const LinearGradient(colors: [Color(0xFFFF5C77), Color(0xFFFF3D77)]);
      case 'purple':
        return const LinearGradient(colors: [Color(0xFF8B3DFF), Color(0xFF6A2CE0)]);
      case 'orange':
        return const LinearGradient(colors: [Color(0xFFFFA53C), Color(0xFFFF7A1C)]);
      case 'green':
        return const LinearGradient(colors: [Color(0xFF3CD98A), Color(0xFF1FAE6A)]);
      case 'blue':
        return const LinearGradient(colors: [Color(0xFF4C6CF7), Color(0xFF3450D6)]);
      case 'cyan':
        return const LinearGradient(colors: [Color(0xFF3DD6E0), Color(0xFF22AEC2)]);
      default:
        return null;
    }
  }

  Color _tintShadow(String tint) {
    switch (tint) {
      case 'red':
        return const Color(0x4DFF3D77);
      case 'purple':
        return const Color(0x4D8B3DFF);
      case 'orange':
        return const Color(0x4DFF8A3D);
      case 'green':
        return const Color(0x4D3CD98A);
      case 'blue':
        return const Color(0x4D4C6CF7);
      case 'cyan':
        return const Color(0x4D3DD6E0);
      default:
        return const Color(0x476E687F);
    }
  }

  IconData _iconForAction(String icon) {
    switch (icon) {
      case 'upload':
        return Icons.file_upload_rounded;
      case 'flame':
        return Icons.water_drop_rounded;
      case 'medal':
        return Icons.workspace_premium_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'invite':
        return Icons.person_add_rounded;
      case 'chart':
        return Icons.leaderboard_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'chevronRight':
        return Icons.chevron_right_rounded;
      default:
        return Icons.circle_rounded;
    }
  }
}

class _ActiveChallengesCard extends StatelessWidget {
  const _ActiveChallengesCard({required this.challenges});

  final List<Map<String, dynamic>> challenges;

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1215083C),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    'Active Challenges',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B132C),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/challenges?tab=active'),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7420E8),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF7420E8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniChallengeCard(challenge: challenges[0]),
              ),
              const SizedBox(width: 10),
              if (challenges.length > 1)
                Expanded(
                  child: _MiniChallengeCard(challenge: challenges[1]),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChallengeCard extends StatelessWidget {
  const _MiniChallengeCard({required this.challenge});

  final Map<String, dynamic> challenge;

  @override
  Widget build(BuildContext context) {
    final rawPrize = challenge['prize'] as String? ?? '₹5,000';
    final prizeText = rawPrize.toLowerCase().startsWith('win')
        ? rawPrize
        : 'Win $rawPrize';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1015083C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1 / 0.88,
            child: NetworkImageWidget(
              url: challenge['imageUrl'] as String? ?? '',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  challenge['title'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B132C),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  challenge['timeLeft'] as String? ?? 'Active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF716B8A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 11.5,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          prizeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00A859),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    final id = challenge['id'];
                    if (id != null && id.toString().isNotEmpty) {
                      context.push('/challenge-detail?id=$id');
                    } else {
                      context.push('/challenges?tab=active');
                    }
                  },
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2A6D), Color(0xFF9E00FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'JOIN NOW →',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelGrid extends StatelessWidget {
  const _ReelGrid({required this.reels});

  final List<Map<String, dynamic>> reels;

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final categoryTint = {
          'Dance': const Color(0xFFE01D5C),
          'Comedy': const Color(0xFF3450D6),
          'Fitness': const Color(0xFF1FAE6A),
          'Singing': AppColors.pink,
          'Magic': const Color(0xFF7420E8),
          'Art': const Color(0xFFE8631F),
        }[reel['category'] as String?] ?? AppColors.purple;

        return GestureDetector(
          onTap: () {
            final reelId = reel['id']?.toString() ?? 'r1';
            context.push('${AppRoutes.reelsFeed}?id=$reelId');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3815083C),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.12, 0, 0, 0, 0,
                    0, 1.05, 0, 0, 0,
                    0, 0, 1.05, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: NetworkImageWidget(url: reel['imageUrl'] as String? ?? ''),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x0A140A28),
                        Color(0x80140A28),
                        Color(0xF50A0516),
                      ],
                      stops: const [0.28, 0.58, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryTint,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      (reel['category'] as String? ?? '').toUpperCase(),
                      style: AppTypography.body(
                        fontSize: 7.8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_arrow, size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            reel['views'] as String? ?? '0',
                            style: AppTypography.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: (reel['avatarUrl'] as String?)?.isNotEmpty == true
                                ? NetworkImage(reel['avatarUrl'] as String)
                                : null,
                            child: (reel['avatarUrl'] as String?)?.isNotEmpty == true
                                ? null
                                : const Icon(Icons.person, size: 12),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              reel['handle'] as String? ?? reel['creator'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (reel['verified'] == true)
                            Icon(Icons.verified, size: 12, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MegaPromoScroll extends StatelessWidget {
  const _MegaPromoScroll({required this.banners});

  final List<Map<String, dynamic>> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return GestureDetector(
            onTap: () {
              final id = banner['id'] as String?;
              if (id != null && id.isNotEmpty) {
                context.push('${AppRoutes.challengeDetail}?id=$id');
              } else {
                context.push('${AppRoutes.challenges}?tab=active');
              }
            },
            child: Container(
            width: 286,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFFFF7E8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0x2EFFB000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24FF8C00),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC933), Color(0xFFFF9500)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x52FF9500),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, size: 13, color: Color(0xFF3A1E00)),
                          SizedBox(width: 5),
                          Text(
                            (banner['tag'] as String? ?? 'FEATURED').toUpperCase(),
                            style: AppTypography.display(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3A1E00),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banner['title'] as String? ?? '',
                                style: AppTypography.display(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF170B33),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                banner['subtitle'] as String? ?? '',
                                style: AppTypography.body(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSoft,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFC933), Color(0xFFFF9500)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4DFF9500),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  (banner['ctaLabel'] as String? ?? 'Join Now').toUpperCase(),
                                  style: AppTypography.display(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3A1E00),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        NetworkImageWidget(
                          url: banner['imageUrl'] as String? ?? '',
                          width: 92,
                          height: 118,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(width: 2, color: AppColors.purple),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2E5E2EAA),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner['countdown'] as String? ?? '0',
                          style: AppTypography.display(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF170B33),
                            height: 1,
                          ),
                        ),
                        Text(
                          'DAYS LEFT',
                          style: AppTypography.body(
                            fontSize: 6.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF716B8A),
                            letterSpacing: 0.2,
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
      },
      ),
    );
  }
}

class _DownloadBanner extends StatelessWidget {
  const _DownloadBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF150A30), Color(0xFF1F1049)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFFFC24D),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Ad',
                style: AppTypography.body(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A1608),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: Container(
              width: 62,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: const NetworkImageWidget(
                url: 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?w=220&h=380&q=80&auto=format&fit=crop',
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x59FF3D77),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARTABLE STUDIO',
                          style: AppTypography.display(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'By Artable Studio Pvt. Ltd.',
                          style: AppTypography.body(
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'PLAY. PARTICIPATE.\nWIN BIG.',
                  style: AppTypography.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFC24D),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real Talent. Real Rewards.',
                  style: AppTypography.body(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'DOWNLOAD NOW',
                    style: AppTypography.display(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
