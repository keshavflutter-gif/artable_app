import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_shared_widgets.dart';

class StudioStartScreen extends StatefulWidget {
  const StudioStartScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioStartScreen> createState() => _StudioStartScreenState();
}

class _StudioStartScreenState extends State<StudioStartScreen> {
  bool _pickingGallery = false;

  String get _routeChallengeId => widget.challengeId?.trim() ?? '';

  bool get _hasChallenge => _routeChallengeId.isNotEmpty;

  Map<String, dynamic>? get _initialChallenge {
    if (!_hasChallenge) return null;
    return ReelHelpers.challengeById(_routeChallengeId);
  }

  @override
  void initState() {
    super.initState();
    MusicApiService.prefetchTracks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<StudioCubit>();
      if (_hasChallenge) {
        cubit.fetchStudioSetup(_routeChallengeId);
      } else {
        // Home / FAB free upload — never inherit a prior challenge CUID.
        cubit.clearSubmissionLinkage();
      }
    });
  }

  String _studioPath(String route, String challengeId) {
    final id = challengeId.trim();
    if (id.isEmpty) return route;
    return '$route?id=$id';
  }

  Future<void> _pickFromGallery(String challengeId) async {
    if (_pickingGallery) return;
    setState(() => _pickingGallery = true);
    try {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final cubit = context.read<StudioCubit>();
      cubit.prepareFreshRecording(clearChallenge: !_hasChallenge);
      if (_hasChallenge) {
        cubit.fetchStudioSetup(_routeChallengeId);
      }
      cubit.setRecordedVideoPath(file.path);
      if (!mounted) return;
      context.push(_studioPath(AppRoutes.studioEditVideo, challengeId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open gallery: ${e.toString().replaceAll('Exception:', '').trim()}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingGallery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioState = context.watch<StudioCubit>().state;
    final setupData = studioState.studioSetup;

    final challengeMap = setupData != null && _hasChallenge
        ? setupData.challenge.toUiMap()
        : (_initialChallenge ??
            {
              'id': _routeChallengeId,
              'title': _hasChallenge ? 'Studio Challenge' : 'Upload Video',
              'maxVideoDuration': 60,
            });

    final challengeId = (challengeMap['id']?.toString() ?? _routeChallengeId).trim();
    final steps = setupData?.steps;
    final recordingTips = setupData?.recordingTips;
    final policy = setupData?.policy;
    // Free upload (no challenge setup): allow gallery by default.
    final galleryAllowed =
        policy?.galleryUploadAllowed ?? !_hasChallenge;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Studio'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioStepIndicator(
                      activeIndex: 0,
                      steps: steps,
                    ),
                    StudioHeroCard(challenge: challengeMap),
                    const SizedBox(height: 16),
                    _InfoNote(galleryAllowed: galleryAllowed),
                    const SizedBox(height: 26),
                    const Text(
                      'Recording Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TipGrid(tipsList: recordingTips),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Start Recording',
                      icon: const Icon(Icons.videocam_outlined,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        context.read<StudioCubit>().prepareFreshRecording(
                              clearChallenge: !_hasChallenge,
                            );
                        if (_hasChallenge) {
                          context
                              .read<StudioCubit>()
                              .fetchStudioSetup(_routeChallengeId);
                        }
                        context.push(
                          _studioPath(AppRoutes.studioCamera, challengeId),
                        );
                      },
                    ),
                    if (galleryAllowed) ...[
                      const SizedBox(height: 10),
                      SecondaryOutlineButton(
                        label: _pickingGallery
                            ? 'Opening Gallery...'
                            : 'Upload from Gallery',
                        icon: const Icon(Icons.video_library_outlined, size: 17),
                        onPressed: _pickingGallery
                            ? null
                            : () => _pickFromGallery(challengeId),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SecondaryOutlineButton(
                      label: 'View Drafts',
                      icon: const Icon(Icons.description_outlined, size: 17),
                      onPressed: () => context.push(
                        _studioPath(AppRoutes.studioDrafts, challengeId),
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
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({this.galleryAllowed = false});

  final bool galleryAllowed;

  @override
  Widget build(BuildContext context) {
    final noteText = galleryAllowed
        ? 'You may upload from gallery or record your video using the in-app studio.'
        : 'Gallery upload is not allowed. Record your video using the in-app studio.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.08),
            const Color(0xFFFF8A3D).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const _InfoIcon(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noteText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: AppColors.purple,
      ),
    );
  }
}

class _TipGrid extends StatelessWidget {
  const _TipGrid({this.tipsList});

  final List<dynamic>? tipsList;

  @override
  Widget build(BuildContext context) {
    final tips = (tipsList != null && tipsList!.isNotEmpty)
        ? tipsList!
            .map((t) => t is Map
                ? Map<String, dynamic>.from(t)
                : <String, dynamic>{'text': t.toString()})
            .toList()
        : const [
            {'text': 'Hold phone steady and film vertically'},
            {'text': 'Use good lighting on your face'},
            {'text': 'Keep entries short and on-theme'},
            {'text': 'Smile — energy wins ratings'},
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tips.length.clamp(0, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final tip = tips[index];
        final text = tip['text']?.toString() ??
            tip['title']?.toString() ??
            tip['description']?.toString() ??
            '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFECE8F5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
