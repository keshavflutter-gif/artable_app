import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/utils/studio_video_player_utils.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';
import 'package:artable_app/features/studio/presentation/widgets/recorded_video_preview.dart';
import 'package:artable_app/features/studio/presentation/widgets/studio_shared_widgets.dart';

class StudioDetailsScreen extends StatefulWidget {
  const StudioDetailsScreen({
    super.key,
    this.challengeId,
    this.draftId,
  });

  final String? challengeId;
  final String? draftId;

  @override
  State<StudioDetailsScreen> createState() => _StudioDetailsScreenState();
}

class _StudioDetailsScreenState extends State<StudioDetailsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hashtagsController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _confirmed = false;
  bool _playing = false;
  late String _categoryId;
  late String _challengeId;

  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    for (final d in MockData.DRAFTS) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final draft = _draft;
    _challengeId = draft != null
        ? draft['challengeId'] as String
        : widget.challengeId ?? 'c1';
    final challenge = ReelHelpers.challengeById(_challengeId)!;
    _categoryId = MockData.CATEGORIES
        .firstWhere(
          (c) => c['name'] == challenge['category'],
          orElse: () => MockData.CATEGORIES.first,
        )['id'] as String;
    _hashtagsController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    if (draft != null) {
      final studio = context.read<StudioCubit>();
      studio.restoreRecordingEffects(
        filterId: draft['filterId'] as String?,
        beautyOn: draft['beautyOn'] as bool?,
        beautyIntensity: (draft['beautyIntensity'] as num?)?.toDouble(),
      );
      final path = draft['videoPath']?.toString();
      if (path != null && path.isNotEmpty) {
        studio.setRecordedVideoPath(path);
      }
    }
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final studio = context.read<StudioCubit>();
    String? path = studio.recordedVideoPath ?? _draft?['videoPath']?.toString();

    if (path == null || path.isEmpty) return;

    if (_videoController != null) {
      try {
        await _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }

    final controller = await StudioVideoPlayerUtils.initializeRecordedVideo(path);

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null) {
      setState(() {
        _videoController = controller;
        _isVideoInitialized = true;
        _playing = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller != null && _isVideoInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
        setState(() => _playing = false);
      } else {
        controller.play();
        setState(() => _playing = true);
      }
    }
  }

  Map<String, dynamic> get _selectedChallenge =>
      ReelHelpers.challengeById(_challengeId)!;

  String _getDuration(StudioCubit studio) {
    final draft = _draft;
    if (draft != null) return draft['duration'] as String? ?? '0:00';
    return studio.recordedDuration;
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && _confirmed;

  List<String> get _hashtagChips {
    return _hashtagsController.text
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .toList();
  }

  void _syncCategoryFromChallenge() {
    final c = _selectedChallenge;
    final match = MockData.CATEGORIES.firstWhere(
      (cat) => cat['name'] == c['category'],
      orElse: () => MockData.CATEGORIES.first,
    );
    setState(() => _categoryId = match['id'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final challenge = _selectedChallenge;
    final music = studio.selectedMusic;
    final duration = _getDuration(studio);
    final isFrontCamera = studio.isFrontCamera;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Video Details'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StudioStepIndicator(activeIndex: 2),
                    RecordedVideoPreview(
                      videoController: _videoController,
                      isVideoInitialized: _isVideoInitialized,
                      playing: _playing,
                      onTogglePlayPause: _togglePlayPause,
                      duration: duration,
                      isFrontCamera: isFrontCamera,
                      filterId: studio.recordingFilter,
                      beautyOn: studio.recordingBeautyOn,
                      beautyIntensity: studio.recordingBeautyIntensity,
                    ),
                    if (music != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.withValues(alpha: 0.1),
                              AppColors.pink.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note, size: 13, color: AppColors.purple),
                            const SizedBox(width: 7),
                            Text(
                              music,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _FieldLabel('Title'),
                    _AuthInput(
                      child: TextField(
                        controller: _titleController,
                        style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: 'Give your entry a title',
                          hintStyle: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.textFaint),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Description'),
                    TextField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Tell viewers about your entry',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.55), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Category'),
                    _AuthInput(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _categoryId,
                          isExpanded: true,
                          items: MockData.CATEGORIES
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _categoryId = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Hashtags'),
                    _AuthInput(
                      child: TextField(
                        controller: _hashtagsController,
                        style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: '#dance #talent #artable',
                          hintStyle: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.textFaint),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_hashtagChips.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _hashtagChips
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F2FC),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _FieldLabel('Challenge'),
                    _AuthInput(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _challengeId,
                          isExpanded: true,
                          items: MockData.CHALLENGES
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(c['title'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _challengeId = v);
                              _syncCategoryFromChallenge();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ChallengeSummaryCard(challenge: challenge),
                    const SizedBox(height: 26),
                    Text(
                      'Before You Submit',
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...[
                      'My video is original content.',
                      'I followed the community guidelines.',
                      'Video is recorded in Artable Studio.',
                    ].map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, size: 18, color: AppColors.success),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(text, style: AppTextStyles.bodyRegular145.copyWith(fontSize: 13.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.06),
                            const Color(0xFFFF8A3D).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.purple.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star, size: 18, color: AppColors.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Winners are decided by Talent Score. Likes and shares improve visibility.',
                              style: AppTextStyles.hint12.copyWith(fontSize: 12, color: AppColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _confirmed,
                          activeColor: AppColors.purple,
                          onChanged: (v) => setState(() => _confirmed = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'I confirm this is my original work recorded in Artable Studio.',
                              style: AppTextStyles.bodyRegular145.copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryOutlineButton(
                            label: 'Save Draft',
                            onPressed: () => context.push(
                              '${AppRoutes.studioDrafts}?id=$_challengeId',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: _canSubmit ? 1 : 0.5,
                            child: GradientButton(
                              label: 'Submit Entry',
                              onPressed: _canSubmit
                                  ? () => context.push(
                                        '${AppRoutes.studioUpload}?id=$_challengeId',
                                      )
                                  : null,
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
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: AppTextStyles.displaySemiBold135.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      alignment: Alignment.centerLeft,
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        child: child,
      ),
    );
  }
}
