import 'dart:async';
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
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';

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
  List<String> _mergedClipPaths = [];
  final List<VideoPlayerController> _clipControllers = [];
  int _currentClipIndex = 0;
  bool _isSwitchingClip = false;

  Map<String, dynamic>? get _draft {
    if (widget.draftId == null) return null;
    final studioDrafts = context.read<StudioCubit>().state.drafts;
    for (final d in studioDrafts) {
      if (d['id'] == widget.draftId) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final studio = context.read<StudioCubit>();
    final challengesCubit = context.read<ChallengesCubit>();
    final draft = _draft;

    _challengeId = (studio.videoChallengeId != null && studio.videoChallengeId!.isNotEmpty)
        ? studio.videoChallengeId!
        : (draft != null
            ? draft['challengeId'] as String
            : widget.challengeId ?? 'c1');

    if (_challengeId.isNotEmpty && !_challengeId.startsWith('c')) {
      final detail = challengesCubit.getChallengeDetail(_challengeId);
      if (detail == null) {
        challengesCubit.loadChallengeDetail(_challengeId).then((loadedDetail) {
          if (mounted && loadedDetail != null && loadedDetail.category?.id != null && loadedDetail.category!.id.isNotEmpty) {
            setState(() {
              _categoryId = loadedDetail.category!.id;
            });
          }
        });
      }
    }

    String? catId = studio.videoCategoryId;
    if (catId == _challengeId) {
      catId = null;
    }

    if (catId != null && catId.isNotEmpty) {
      _categoryId = catId;
    } else {
      final detail = challengesCubit.getChallengeDetail(_challengeId);
      if (detail?.category?.id != null && detail!.category!.id.isNotEmpty) {
        _categoryId = detail.category!.id;
      } else {
        _categoryId = '';
      }
    }
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
    final draft = _draft;

    if (draft != null && draft['mergedClipPaths'] is List && (draft['mergedClipPaths'] as List).isNotEmpty) {
      _mergedClipPaths = List<String>.from(draft['mergedClipPaths'] as List);
    } else if (studio.state.mergedClipPaths != null && studio.state.mergedClipPaths!.isNotEmpty) {
      _mergedClipPaths = List<String>.from(studio.state.mergedClipPaths!);
    } else {
      _mergedClipPaths = [];
    }

    if (_videoController != null) {
      try {
        await _videoController!.dispose();
      } catch (_) {}
      _videoController = null;
    }

    if (_mergedClipPaths.length > 1) {
      debugPrint('StudioDetailsScreen loading multi-clip playlist: ${_mergedClipPaths.length} clips');
      for (final c in _clipControllers) {
        c.removeListener(_onVideoControllerUpdate);
        c.dispose();
      }
      _clipControllers.clear();

      for (final p in _mergedClipPaths) {
        try {
          final c = await StudioVideoPlayerUtils.initializeClipController(p, autoPlay: false, loop: false);
          if (c != null) _clipControllers.add(c);
        } catch (e) {
          debugPrint('Error preloading clip $p: $e');
        }
      }

      if (_clipControllers.isNotEmpty) {
        _currentClipIndex = 0;
        final firstController = _clipControllers.first;
        firstController.addListener(_onVideoControllerUpdate);
        await firstController.play();
        if (mounted) {
          setState(() {
            _videoController = firstController;
            _isVideoInitialized = true;
            _playing = true;
          });
        }
        return;
      }
    }

    String? path = studio.recordedVideoPath ?? draft?['videoPath']?.toString();

    if (path == null || path.isEmpty) return;

    var controller = await StudioVideoPlayerUtils.initializeRecordedVideo(path);


    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller != null) {
      final validController = controller;
      validController.addListener(_onVideoControllerUpdate);
      final trimStart = studio.state.videoTrimStartSeconds;
      if (trimStart > 0) {
        validController.seekTo(Duration(milliseconds: (trimStart * 1000).round()));
      }
      setState(() {
        _videoController = validController;
        _isVideoInitialized = true;
        _playing = validController.value.isPlaying;
      });
    }
  }

  void _onVideoControllerUpdate() {
    final controller = _videoController;
    if (controller == null || !mounted || _isSwitchingClip) return;

    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _playing) {
      setState(() => _playing = isPlaying);
    }

    if (_clipControllers.isNotEmpty) {
      final posMs = controller.value.position.inMilliseconds;
      final durMs = controller.value.duration.inMilliseconds;
      if (durMs > 0 && posMs >= durMs - 250) {
        _advanceToNextMergedClip();
        return;
      }
    } else {
      final studio = context.read<StudioCubit>();
      final trimStart = studio.state.videoTrimStartSeconds;
      final trimEnd = studio.state.videoTrimEndSeconds;

      if (trimEnd != null && trimEnd > trimStart) {
        final startMs = (trimStart * 1000).round();
        final endMs = (trimEnd * 1000).round();
        final posMs = controller.value.position.inMilliseconds;

        if (posMs >= endMs || posMs < startMs) {
          controller.seekTo(Duration(milliseconds: startMs));
          if (controller.value.isPlaying) {
            controller.play();
          }
        }
      }
    }
  }

  Future<void> _advanceToNextMergedClip() async {
    if (_isSwitchingClip || _clipControllers.isEmpty) return;
    _isSwitchingClip = true;

    try {
      final oldController = _videoController;
      oldController?.removeListener(_onVideoControllerUpdate);
      await oldController?.pause();

      _currentClipIndex = (_currentClipIndex + 1) % _clipControllers.length;
      final nextController = _clipControllers[_currentClipIndex];

      await nextController.seekTo(Duration.zero);
      nextController.addListener(_onVideoControllerUpdate);
      await nextController.play();

      if (mounted) {
        setState(() {
          _videoController = nextController;
          _isVideoInitialized = true;
          _playing = true;
        });
      }
    } catch (e) {
      debugPrint('Error advancing merged clip in details: $e');
    } finally {
      _isSwitchingClip = false;
    }
  }

  @override
  void dispose() {
    for (final c in _clipControllers) {
      c.removeListener(_onVideoControllerUpdate);
      c.pause();
      c.dispose();
    }
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    unawaited(StudioMusicPlaybackService.stop());
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller != null && _isVideoInitialized) {
      final studio = context.read<StudioCubit>();
      final trimStart = studio.state.videoTrimStartSeconds;
      final trimEnd = studio.state.videoTrimEndSeconds;

      if (controller.value.isPlaying) {
        controller.pause();
        setState(() => _playing = false);
      } else {
        if (trimEnd != null && trimEnd > trimStart) {
          final startMs = (trimStart * 1000).round();
          final endMs = (trimEnd * 1000).round();
          final posMs = controller.value.position.inMilliseconds;

          if (posMs >= endMs || posMs < startMs) {
            controller.seekTo(Duration(milliseconds: startMs));
          }
        }
        controller.play();
        setState(() => _playing = true);
      }
    }
  }

  Future<void> _handleSaveDraft(StudioCubit studio) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final rawHashtags = _hashtagsController.text.trim();
    final effectiveHashtags = rawHashtags.isNotEmpty
        ? rawHashtags.split(' ')
        : (_hashtagChips.isNotEmpty
            ? _hashtagChips
            : ['dance', 'talent', 'artable']);

    final challengeObj = {
      'id': _challengeId,
      'categoryId': _categoryId,
      'title': title.isNotEmpty ? title : 'Studio Draft',
    };

    final existingDraftId = widget.draftId ?? _draft?['id'] as String?;

    final res = (existingDraftId != null && existingDraftId.isNotEmpty)
        ? await studio.updateDraftDetails(
            videoId: existingDraftId,
            challenge: challengeObj,
            title: title.isNotEmpty ? title : null,
            description: description.isNotEmpty ? description : null,
            hashtags: effectiveHashtags,
          )
        : await studio.saveDraftFromPreview(
            challenge: challengeObj,
            title: title.isNotEmpty ? title : null,
            description: description.isNotEmpty ? description : null,
            hashtags: effectiveHashtags,
          );

    if (!mounted) return;

    if (res != null) {
      _videoController?.pause();
      await StudioMusicPlaybackService.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully'),
          backgroundColor: AppColors.purple,
          duration: Duration(seconds: 2),
        ),
      );
      context.push('${AppRoutes.studioDrafts}?id=$_challengeId');
    } else {
      final errorMsg = studio.state.saveDraftError ?? 'Failed to save draft';
      if (errorMsg.contains('Draft limit') || studio.state.drafts.length >= StudioCubit.maxDraftsLimit) {
        _showDraftLimitDialog(context, _challengeId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showDraftLimitDialog(BuildContext context, String? challengeId) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFECE8F5), width: 1.2),
        ),
        backgroundColor: Colors.white,
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF9800),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Draft Limit Reached (20/20)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Maximum 20 drafts can be saved in studio gallery. Please delete an existing draft to save a new video.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSoft,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final route = (challengeId != null && challengeId.isNotEmpty)
                            ? '${AppRoutes.studioDrafts}?id=$challengeId'
                            : AppRoutes.studioDrafts;
                        context.push(route);
                      },
                      child: const Text(
                        'Manage Drafts',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> get _selectedChallenge =>
      ReelHelpers.challengeById(_challengeId)!;

  String _getDuration(StudioCubit studio) {
    if (studio.recordedDuration.isNotEmpty && studio.recordedDuration != '0:00') {
      return studio.recordedDuration;
    }
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

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems(
    BuildContext context,
    String? currentSelectedId,
  ) {
    final Map<String, String> categoryMap = {};

    try {
      final challengesCubit = context.read<ChallengesCubit>();
      if (!challengesCubit.hasLoadedCategories && !challengesCubit.isLoadingCategories) {
        challengesCubit.loadCategories();
      }

      final apiCats = challengesCubit.categoriesResponse?.data ?? [];
      for (final c in apiCats) {
        if (c.id.isNotEmpty && c.name.isNotEmpty) {
          categoryMap[c.id] = c.name;
        }
      }

      if (currentSelectedId != null &&
          currentSelectedId.isNotEmpty &&
          !categoryMap.containsKey(currentSelectedId)) {
        final detail = challengesCubit.getChallengeDetail(_challengeId);
        if (detail != null) {
          if (detail.category?.id == currentSelectedId &&
              detail.category?.name != null &&
              detail.category!.name.isNotEmpty) {
            categoryMap[currentSelectedId] = detail.category!.name;
          } else if (detail.categoryName.isNotEmpty) {
            categoryMap[currentSelectedId] = detail.categoryName;
          }
        }
      }
    } catch (_) {}

    if (currentSelectedId != null &&
        currentSelectedId.isNotEmpty &&
        !categoryMap.containsKey(currentSelectedId)) {
      try {
        final detail = context.read<ChallengesCubit>().getChallengeDetail(_challengeId);
        final name = (detail?.categoryName != null && detail!.categoryName.isNotEmpty)
            ? detail.categoryName
            : 'Dance';
        categoryMap[currentSelectedId] = name;
      } catch (_) {
        categoryMap[currentSelectedId] = 'Dance';
      }
    }

    return categoryMap.entries
        .map((e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            ))
        .toList();
  }

  List<DropdownMenuItem<String>> _buildChallengeDropdownItems(
    BuildContext context,
    String? currentSelectedId,
  ) {
    final Map<String, String> challengeMap = {};

    try {
      final challengesCubit = context.read<ChallengesCubit>();
      for (final c in challengesCubit.challenges) {
        final id = c['id']?.toString() ?? '';
        final title = c['title']?.toString() ?? '';
        if (id.isNotEmpty && title.isNotEmpty) challengeMap[id] = title;
      }

      if (currentSelectedId != null && currentSelectedId.isNotEmpty) {
        final detail = challengesCubit.getChallengeDetail(currentSelectedId);
        if (detail != null && detail.title.isNotEmpty) {
          challengeMap[currentSelectedId] = detail.title;
        }
      }
    } catch (_) {}

    if (currentSelectedId != null &&
        currentSelectedId.isNotEmpty &&
        !challengeMap.containsKey(currentSelectedId)) {
      try {
        final detail = context.read<ChallengesCubit>().getChallengeDetail(currentSelectedId);
        final title = (detail?.title != null && detail!.title.isNotEmpty)
            ? detail.title
            : 'Monthly Mega Dance Battle';
        challengeMap[currentSelectedId] = title;
      } catch (_) {
        challengeMap[currentSelectedId] = 'Monthly Mega Dance Battle';
      }
    }

    return challengeMap.entries
        .map((e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioCubit>();
    final challenge = _selectedChallenge;
    final music = studio.selectedMusic;
    final duration = _getDuration(studio);
    final isFrontCamera = studio.isFrontCamera;

    final categoryItems = _buildCategoryDropdownItems(context, _categoryId);
    final challengeItems = _buildChallengeDropdownItems(context, _challengeId);

    final selectedCategoryValue =
        categoryItems.any((item) => item.value == _categoryId)
            ? _categoryId
            : (categoryItems.isNotEmpty ? categoryItems.first.value : null);

    final selectedChallengeValue =
        challengeItems.any((item) => item.value == _challengeId)
            ? _challengeId
            : (challengeItems.isNotEmpty ? challengeItems.first.value : null);

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
                          value: selectedCategoryValue,
                          isExpanded: true,
                          items: categoryItems,
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
                          value: selectedChallengeValue,
                          isExpanded: true,
                          items: challengeItems,
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
                            label: studio.state.isSavingDraft ? 'Saving...' : 'Save Draft',
                            onPressed: studio.state.isSavingDraft ? null : () => _handleSaveDraft(studio),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: _canSubmit ? 1 : 0.5,
                            child: GradientButton(
                              label: 'Submit Entry',
                              onPressed: _canSubmit
                                  ? () async {
                                      final studioCubit = context.read<StudioCubit>();
                                      final router = GoRouter.of(context);
                                      _videoController?.pause();
                                      await StudioMusicPlaybackService.stop();
                                      final rawHashtags =
                                          _hashtagsController.text.trim();
                                      final effectiveHashtags =
                                          rawHashtags.isNotEmpty
                                              ? rawHashtags
                                              : (_hashtagChips.isNotEmpty
                                                  ? _hashtagChips.join(' ')
                                                  : '#dance #talent #artable');

                                      final targetDraftId = widget.draftId ?? _draft?['id'] as String?;
                                      studioCubit.setVideoSubmissionDetails(
                                        title: _titleController.text.trim(),
                                        description:
                                            _descriptionController.text.trim(),
                                        categoryId: _categoryId,
                                        hashtags: effectiveHashtags,
                                        challengeId: _challengeId,
                                        draftId: targetDraftId,
                                      );
                                      if (mounted) {
                                        final draftQuery = (targetDraftId != null && targetDraftId.isNotEmpty)
                                            ? '&draft=$targetDraftId'
                                            : '';
                                        router.push(
                                          '${AppRoutes.studioUpload}?id=$_challengeId$draftQuery',
                                        );
                                      }
                                    }
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
