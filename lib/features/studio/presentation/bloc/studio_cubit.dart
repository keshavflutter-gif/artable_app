import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'package:artable_app/data/datasources/music_api_service.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/studio/data/models/studio_filters_response.dart';
import 'package:artable_app/features/studio/data/repositories/studio_repository.dart';
import 'package:artable_app/features/studio/data/services/studio_music_playback_service.dart';
import 'package:artable_app/features/studio/data/services/video_thumbnail_generator.dart';
import 'package:artable_app/core/utils/media_url_utils.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'studio_state.dart';

class StudioCubit extends Cubit<StudioState> {
  StudioCubit({
    AuthCubit? authCubit,
    StudioRepository? repository,
  })  : _authCubit = authCubit,
        _repository = repository ??
            StudioRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(StudioState());

  AuthCubit? _authCubit;
  final StudioRepository _repository;
  bool _draftWriteLock = false;
  bool _draftsFetchInFlight = false;

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }

  StudioFiltersConfig? get filtersConfig => state.filtersConfig;

  Future<void> loadFiltersConfig({bool forceRefresh = false}) async {
    if (state.isLoadingFilters) return;
    if (state.filtersConfig != null && !forceRefresh) return;

    emit(state.copyWith(isLoadingFilters: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.getStudioFiltersConfig(
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      emit(state.copyWith(
        filtersConfig: res.data,
        isLoadingFilters: false,
      ));
    } catch (e) {
      debugPrint('StudioCubit loadFiltersConfig error: $e');
      emit(state.copyWith(
        filtersConfig: StudioFiltersConfig.empty(),
        isLoadingFilters: false,
      ));
    }
  }

  Future<void> fetchStudioSetup(String challengeId, {bool forceRefresh = false}) async {
    final cleanId = challengeId.trim();
    if (cleanId.isEmpty) return;

    if (state.studioSetup != null &&
        state.studioSetup!.challenge.id == cleanId &&
        !forceRefresh) {
      return;
    }

    emit(state.copyWith(isSetupLoading: true));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.getStudioSetup(
        challengeId: cleanId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      if (res != null && res.success) {
        final setup = res.data;
        final setupChallengeId = setup?.challenge.id.trim() ?? '';
        final setupCategoryId = setup?.challenge.category?.id.trim() ?? '';
        emit(state.copyWith(
          studioSetup: setup,
          isSetupLoading: false,
          videoChallengeId: setupChallengeId.isNotEmpty ? setupChallengeId : null,
          videoCategoryId: setupCategoryId.isNotEmpty ? setupCategoryId : null,
        ));
      } else {
        emit(state.copyWith(isSetupLoading: false));
      }
    } catch (e) {
      debugPrint('StudioCubit fetchStudioSetup error: $e');
      emit(state.copyWith(isSetupLoading: false));
    }
  }

  static const int maxDraftsLimit = 20;
  static const int maxMergeClipsLimit = 10;

  Future<Map<String, dynamic>?> mergeDrafts({
    required List<String> draftIds,
    String? customTitle,
  }) async {
    final currentRecPath = state.recordedVideoPath?.trim();
    final hasCurrentRec = currentRecPath != null &&
        currentRecPath.isNotEmpty &&
        (currentRecPath.startsWith('http') || File(currentRecPath.replaceFirst('file://', '')).existsSync());

    final selectedDrafts = <Map<String, dynamic>>[];
    for (final id in draftIds) {
      for (final d in state.drafts) {
        if (d['id'] == id) {
          selectedDrafts.add(d);
          break;
        }
      }
    }

    final isCurrentRecSelected = hasCurrentRec &&
        selectedDrafts.any((d) {
          final p = (d['videoPath']?.toString() ?? d['videoUrl']?.toString() ?? '').trim();
          return p.isNotEmpty &&
              (p == currentRecPath ||
                  p.replaceFirst('file://', '') == currentRecPath.replaceFirst('file://', ''));
        });

    final isCurrentRecInDrafts = hasCurrentRec &&
        state.drafts.any((d) {
          final p = (d['videoPath']?.toString() ?? d['videoUrl']?.toString() ?? '').trim();
          return p.isNotEmpty &&
              (p == currentRecPath ||
                  p.replaceFirst('file://', '') == currentRecPath.replaceFirst('file://', ''));
        });

    final bool shouldPrependCurrentRec = hasCurrentRec &&
        !isCurrentRecSelected &&
        !isCurrentRecInDrafts;

    if (draftIds.isEmpty && !shouldPrependCurrentRec) return null;

    if (draftIds.length > maxMergeClipsLimit) {
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: 'Maximum $maxMergeClipsLimit videos can be merged at a time.',
      ));
      return null;
    }

    if (state.drafts.length >= maxDraftsLimit) {
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: 'Draft limit reached (Max $maxDraftsLimit drafts). Please delete a draft to save a merged video.',
      ));
      return null;
    }

    if (selectedDrafts.isEmpty && !shouldPrependCurrentRec) return null;

    final mergedClipPaths = <String>[];
    final mergedClipDurations = <double>[];
    final mergedClipThumbnails = <String>[];
    final mergedClipFilterIds = <String>[];
    double totalSecs = 0.0;

    // 1st Clip: Current active video recording ONLY IF it's an unsaved recording not in drafts
    final recPath = currentRecPath;
    if (shouldPrependCurrentRec && recPath != null) {
      mergedClipPaths.add(recPath);
      mergedClipFilterIds.add(normalizeFilterId(state.recordingFilter));
      mergedClipThumbnails.add(state.selectedThumbnailPath ?? '');
      double recDur = 0.0;
      final parts = state.recordedDuration.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        recDur = (m * 60 + s).toDouble();
      } else {
        recDur = 15.0;
      }
      if (recDur <= 0) recDur = 15.0;
      mergedClipDurations.add(recDur);
      totalSecs += recDur;
    }

    // Selected draft videos
    for (final d in selectedDrafts) {
      double draftDur = 0.0;
      if (d['durationSeconds'] != null && (d['durationSeconds'] as num) > 0) {
        draftDur = (d['durationSeconds'] as num).toDouble();
      } else {
        final dur = d['duration']?.toString() ?? '0:30';
        final parts = dur.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          draftDur = (m * 60 + s).toDouble();
        } else {
          draftDur = (d['durationSeconds'] as num?)?.toDouble() ?? 30.0;
        }
      }
      if (draftDur <= 0) draftDur = 15.0;

      final dThumb = (d['thumbnailPath']?.toString() ?? d['thumbnailUrl']?.toString() ?? '').trim();
      if (d['mergedClipPaths'] is List && (d['mergedClipPaths'] as List).isNotEmpty) {
        final subPaths = List<String>.from(d['mergedClipPaths'] as List);
        final subDurs = (d['mergedClipDurations'] is List)
            ? (d['mergedClipDurations'] as List).map((e) => (e as num).toDouble()).toList()
            : <double>[];
        final subThumbs = (d['mergedClipThumbnails'] is List)
            ? List<String>.from(d['mergedClipThumbnails'] as List)
            : <String>[];
        final subFilters = clipFilterIdsOfDraft(d, pathCount: subPaths.length);
        for (int i = 0; i < subPaths.length; i++) {
          final p = subPaths[i].trim();
          if (p.isNotEmpty) {
            mergedClipPaths.add(p);
            mergedClipFilterIds.add(
              i < subFilters.length ? subFilters[i] : filterIdOfDraft(d),
            );
            final dur = (i < subDurs.length && subDurs[i] > 0) ? subDurs[i] : (draftDur / subPaths.length);
            mergedClipDurations.add(dur);
            final t = (i < subThumbs.length && subThumbs[i].isNotEmpty) ? subThumbs[i] : dThumb;
            mergedClipThumbnails.add(t);
            totalSecs += dur;
          }
        }
      } else {
        final p = (d['videoPath']?.toString() ?? d['videoUrl']?.toString() ?? '').trim();
        if (p.isNotEmpty) {
          mergedClipPaths.add(p);
          mergedClipFilterIds.add(filterIdOfDraft(d));
          mergedClipDurations.add(draftDur);
          mergedClipThumbnails.add(dThumb);
          totalSecs += draftDur;
        }
      }
    }

    final first = selectedDrafts.isNotEmpty
        ? selectedDrafts.first
        : {'challengeTitle': 'Studio Draft', 'challengeId': 'c1'};
    final title1 = first['challengeTitle']?.toString() ?? first['title']?.toString() ?? 'Studio Draft';
    final mergedTitle = customTitle ?? '$title1 (Merged ${mergedClipPaths.length} Clips)';

    String resolvedThumb = state.selectedThumbnailPath ?? '';
    if (resolvedThumb.isEmpty && selectedDrafts.isNotEmpty) {
      resolvedThumb = selectedDrafts.first['thumbnailPath']?.toString() ??
          selectedDrafts.first['thumbnailUrl']?.toString() ??
          selectedDrafts.first['imageUrl']?.toString() ??
          '';
    }

    // Fill missing per-clip thumbs so the editor filmstrip / draft card have images.
    for (int i = 0; i < mergedClipPaths.length; i++) {
      final existing = i < mergedClipThumbnails.length ? mergedClipThumbnails[i].trim() : '';
      final looksLikeImage = existing.isNotEmpty &&
          !existing.toLowerCase().endsWith('.mp4') &&
          !existing.toLowerCase().endsWith('.mov') &&
          !existing.toLowerCase().endsWith('.m4v');
      if (looksLikeImage) continue;
      try {
        final thumbFile = await VideoThumbnailGenerator.generateThumbnailFromVideo(
          mergedClipPaths[i],
          timeMs: 200,
        );
        if (thumbFile != null && await thumbFile.exists()) {
          final path = thumbFile.path;
          if (i < mergedClipThumbnails.length) {
            mergedClipThumbnails[i] = path;
          } else {
            mergedClipThumbnails.add(path);
          }
          if (resolvedThumb.isEmpty ||
              resolvedThumb.toLowerCase().endsWith('.mp4') ||
              resolvedThumb.toLowerCase().endsWith('.mov')) {
            resolvedThumb = path;
          }
        }
      } catch (e) {
        debugPrint('mergeDrafts thumbnail generate warning for clip $i: $e');
      }
    }
    while (mergedClipThumbnails.length < mergedClipPaths.length) {
      mergedClipThumbnails.add('');
    }

    final totalSecsInt = totalSecs.round();
    final mins = totalSecsInt ~/ 60;
    final secs = totalSecsInt % 60;
    final formattedDur = '$mins:${secs.toString().padLeft(2, '0')}';

    // Fast instant multi-clip merge: Preview, Edit and Details screens play multi-clips
    // seamlessly as a playlist using mergedClipPaths. Actual file merge is deferred to upload.
    final finalVideoPath = (mergedClipPaths.isNotEmpty ? mergedClipPaths.first : '');

    final mergedPrimaryFilter = mergedClipFilterIds.isNotEmpty
        ? mergedClipFilterIds.first
        : normalizeFilterId(state.recordingFilter);

    if (resolvedThumb.isNotEmpty) {
      setSelectedThumbnailPath(resolvedThumb);
    }

    emit(state.copyWith(
      recordedDuration: formattedDur,
      videoTrimStartSeconds: 0.0,
      videoTrimEndSeconds: totalSecs,
      recordedVideoPath: finalVideoPath.isNotEmpty ? finalVideoPath : null,
      mergedClipPaths: mergedClipPaths,
      mergedClipDurations: mergedClipDurations,
      mergedClipFilterIds: mergedClipFilterIds,
      recordingFilter: mergedPrimaryFilter,
      selectedThumbnailPath: resolvedThumb.isNotEmpty ? resolvedThumb : null,
    ));

    final mergedDraftId = 'merged_${DateTime.now().millisecondsSinceEpoch}';
    final cleanChallengeId = first['challengeId']?.toString() ?? 'c1';

    final mergedDraft = <String, dynamic>{
      'id': mergedDraftId,
      'challengeId': cleanChallengeId,
      'challengeTitle': mergedTitle,
      'title': mergedTitle,
      'description': _descriptionWithFilter(
        'Merged video from ${selectedDrafts.length} drafts',
        filterId: mergedPrimaryFilter,
      ),
      'duration': formattedDur,
      'durationSeconds': totalSecsInt,
      'recordedAt': DateTime.now().toIso8601String(),
      'thumbnailUrl': resolvedThumb.isNotEmpty
          ? resolvedThumb
          : (first['thumbnailUrl']?.toString() ?? ''),
      'thumbnailPath': resolvedThumb.isNotEmpty ? resolvedThumb : null,
      'videoPath': finalVideoPath,
      'videoUrl': finalVideoPath,
      'mergedClipPaths': mergedClipPaths,
      'mergedClipDurations': mergedClipDurations,
      'mergedClipThumbnails': mergedClipThumbnails,
      'mergedClipFilterIds': mergedClipFilterIds,
      'videoTrimStartSeconds': 0.0,
      'videoTrimEndSeconds': totalSecs,
      ...state.recordingEffectsPayload,
      'filterId': mergedPrimaryFilter,
    };
    _attachFilterToDraftMap(
      mergedDraft,
      videoUrl: finalVideoPath,
      filterId: mergedPrimaryFilter,
    );

    addDraft(mergedDraft);
    setActiveDraftId(mergedDraftId);
    emit(state.copyWith(isSavingDraft: false, clearSaveDraftError: true));

    // Optional background sync to backend so the UI never hangs on network upload
    unawaited(() async {
      try {
        final token = _authCubit?.sessionToken;
        if (token != null && token.isNotEmpty && token != 'design_preview') {
          await _repository.saveDraft(
            body: {
              'challengeId': cleanChallengeId,
              'title': mergedTitle,
              'description': _descriptionWithFilter(
                'Merged video from ${selectedDrafts.length} drafts',
              ),
              'videoUrl': finalVideoPath,
              'thumbnailUrl': resolvedThumb,
              'hashtags': ['dance', 'talent', 'artable'],
              'durationSeconds': totalSecsInt,
              ..._filterPersistFields(),
            },
            sessionToken: token,
            refreshToken: _authCubit?.refreshToken,
          );
        }
      } catch (e) {
        debugPrint('Background draft sync warning: $e');
      }
    }());

    return mergedDraft;
  }

  bool _isLocalDraftId(String? id) {
    final v = (id ?? '').trim();
    if (v.isEmpty) return true;
    if (v.startsWith('merged_') || v.startsWith('local_')) return true;
    return RegExp(r'^d\d+$').hasMatch(v);
  }

  bool _isRemoteUrl(String path) {
    final p = path.trim();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  bool _isUsableThumb(String path) {
    final p = path.trim();
    if (p.isEmpty) return false;
    if (p.contains('storage.example')) return false;
    if (MediaUrlUtils.isDummyThumbnail(p)) return false;
    if (_isRemoteUrl(p)) return true;
    try {
      final f = File(p.replaceFirst('file://', ''));
      return f.existsSync() && f.lengthSync() > 200;
    } catch (_) {
      return false;
    }
  }

  int _parseDurationSeconds(int? durationSeconds) {
    if (durationSeconds != null && durationSeconds > 0) return durationSeconds;
    final durParts = state.recordedDuration.split(':');
    if (durParts.length == 2) {
      final m = int.tryParse(durParts[0]) ?? 0;
      final s = int.tryParse(durParts[1]) ?? 0;
      final total = m * 60 + s;
      if (total > 0) return total;
    }
    return 42;
  }

  String? _sessionToken() {
    final token = _authCubit?.sessionToken;
    if (token == null || token.isEmpty || token == 'design_preview') return null;
    return token;
  }

  String? _refreshTokenOrNull() {
    final refresh = _authCubit?.refreshToken;
    if (refresh == null || refresh.isEmpty || refresh == 'design_preview') return null;
    return refresh;
  }

  String _fallbackThumb({
    required String recVideoPath,
    required String currentThumb,
    Map<String, dynamic>? challenge,
  }) {
    if (_isUsableThumb(currentThumb)) return currentThumb.trim();
    final banner = (challenge?['bannerUrl']?.toString() ??
            challenge?['imageUrl']?.toString() ??
            '')
        .trim();
    if (banner.isNotEmpty) return banner;
    return recVideoPath;
  }

  void _replaceDraftById(String oldId, Map<String, dynamic> next) {
    var found = false;
    final updated = state.drafts.map((d) {
      if (d['id'] == oldId) {
        found = true;
        return next;
      }
      return d;
    }).toList();
    if (!found) updated.insert(0, next);
    emit(state.copyWith(
      drafts: updated,
      activeDraftId: state.activeDraftId == oldId
          ? next['id']?.toString()
          : state.activeDraftId,
    ));
  }

  List<Map<String, dynamic>> _mergeIncomingDrafts(List<Map<String, dynamic>> remote) {
    final remoteIds = <String>{};
    final remoteUrls = <String>{};
    for (final d in remote) {
      final id = d['id']?.toString();
      if (id != null && id.isNotEmpty) remoteIds.add(id);
      final url = (d['videoUrl'] ?? d['videoPath'])?.toString() ?? '';
      if (url.isNotEmpty) remoteUrls.add(url);
    }

    final localById = <String, Map<String, dynamic>>{};
    final localsToKeep = <Map<String, dynamic>>[];
    for (final d in state.drafts) {
      final id = d['id']?.toString() ?? '';
      if (id.isNotEmpty) localById[id] = d;
      if (!_isLocalDraftId(id) || remoteIds.contains(id)) continue;
      final url = (d['videoUrl'] ?? d['videoPath'])?.toString() ?? '';
      if (url.isNotEmpty && remoteUrls.contains(url) && _isRemoteUrl(url)) continue;
      localsToKeep.add(d);
    }

    final mergedRemote = remote.map((d) {
      final id = d['id']?.toString();
      final local = id != null ? localById[id] : null;
      if (local == null) return d;
      final out = {...d};
      if (local['mergedClipPaths'] != null) {
        out['mergedClipPaths'] = local['mergedClipPaths'];
      }
      if (local['mergedClipDurations'] != null) {
        out['mergedClipDurations'] = local['mergedClipDurations'];
      }
      if (local['mergedClipThumbnails'] != null) {
        out['mergedClipThumbnails'] = local['mergedClipThumbnails'];
      }
      final localPath = local['videoPath']?.toString() ?? '';
      if (localPath.isNotEmpty && !_isRemoteUrl(localPath)) {
        out['videoPath'] = localPath;
      }
      final localFilter = local['filterId']?.toString();
      if ((out['filterId'] == null || out['filterId'].toString() == 'natural') &&
          localFilter != null &&
          localFilter.isNotEmpty) {
        out['filterId'] = localFilter;
        out['beautyOn'] = local['beautyOn'];
        out['beautyIntensity'] = local['beautyIntensity'];
      }
      return out;
    }).toList();

    return [...localsToKeep, ...mergedRemote];
  }

  Future<String> _maybeUploadMedia(String path, {required bool isVideo}) async {
    final clean = path.replaceFirst('file://', '').trim();
    if (clean.isEmpty || _isRemoteUrl(clean)) return path;
    if (!File(clean).existsSync()) return path;
    try {
      final uploaded = await _repository.uploadFile(
        clean,
        isVideo: isVideo,
        sessionToken: _sessionToken(),
        refreshToken: _refreshTokenOrNull(),
      );
      if (uploaded.isNotEmpty) return uploaded;
    } catch (e) {
      debugPrint('Background draft ${isVideo ? 'video' : 'thumb'} upload: $e');
    }
    return path;
  }

  Future<void> _syncNewDraftInBackground({
    required String localId,
    required String title,
    required String description,
    required String recVideoPath,
    required String thumbPath,
    required List<String> hashtags,
    required int durationSeconds,
    required String cleanChallengeId,
    required String? cleanCategoryId,
    required Map<String, dynamic> filterFields,
  }) async {
    try {
      String vUrl = recVideoPath;
      String tUrl = thumbPath;

      if (!_isUsableThumb(tUrl) && recVideoPath.isNotEmpty) {
        try {
          final gen = await VideoThumbnailGenerator.generateThumbnailFromVideo(recVideoPath)
              .timeout(const Duration(seconds: 4), onTimeout: () => null);
          if (gen != null && await gen.exists()) tUrl = gen.path;
        } catch (_) {}
      }

      final uploaded = await Future.wait([
        _maybeUploadMedia(vUrl, isVideo: true),
        _maybeUploadMedia(tUrl, isVideo: false),
      ]);
      vUrl = uploaded[0];
      tUrl = uploaded[1];

      final sToken = _sessionToken();
      if (sToken == null) return;

      final res = await _repository.saveDraft(
        body: {
          if (cleanChallengeId.isNotEmpty) 'challengeId': cleanChallengeId,
          if (cleanCategoryId != null && cleanCategoryId.isNotEmpty)
            'categoryId': cleanCategoryId,
          'title': title,
          'description': description,
          'videoUrl': vUrl,
          'thumbnailUrl': tUrl,
          'hashtags': hashtags.isNotEmpty ? hashtags : ['dance', 'talent', 'artable'],
          'durationSeconds': durationSeconds,
          if ((filterFields['filterId'] as String) != 'natural')
            'filterId': filterFields['filterId'],
          if (filterFields['beautyOn'] == true) 'beautyOn': true,
          if ((filterFields['beautyIntensity'] as num) > 0)
            'beautyIntensity': filterFields['beautyIntensity'],
        },
        sessionToken: sToken,
        refreshToken: _refreshTokenOrNull(),
      );
      if (!res.success || res.data == null) return;

      final ui = res.data!.toUiMap();
      Map<String, dynamic>? current;
      for (final d in state.drafts) {
        if (d['id'] == localId) {
          current = d;
          break;
        }
      }
      if (current != null) {
        if (current['mergedClipPaths'] != null) {
          ui['mergedClipPaths'] = current['mergedClipPaths'];
        }
        if (current['mergedClipDurations'] != null) {
          ui['mergedClipDurations'] = current['mergedClipDurations'];
        }
        if (current['mergedClipThumbnails'] != null) {
          ui['mergedClipThumbnails'] = current['mergedClipThumbnails'];
        }
        final localPath = current['videoPath']?.toString() ?? '';
        if (localPath.isNotEmpty && !_isRemoteUrl(localPath)) {
          ui['videoPath'] = localPath;
        }
      }
      if ((ui['thumbnailUrl'] == null ||
              ui['thumbnailUrl'].toString().contains('storage.example')) &&
          tUrl.isNotEmpty) {
        ui['thumbnailUrl'] = tUrl;
      }
      _attachFilterToDraftMap(ui, videoUrl: vUrl);
      _replaceDraftById(localId, ui);
    } catch (e) {
      debugPrint('Background draft sync warning: $e');
    }
  }

  Future<void> _syncUpdateDraftInBackground({
    required String videoId,
    required String title,
    required String description,
    required String recVideoPath,
    required String thumbPath,
    required List<String> hashtags,
    required int durationSeconds,
    required String cleanChallengeId,
    required String? cleanCategoryId,
    required Map<String, dynamic> filterFields,
  }) async {
    if (_isLocalDraftId(videoId)) {
      await _syncNewDraftInBackground(
        localId: videoId,
        title: title,
        description: description,
        recVideoPath: recVideoPath,
        thumbPath: thumbPath,
        hashtags: hashtags,
        durationSeconds: durationSeconds,
        cleanChallengeId: cleanChallengeId,
        cleanCategoryId: cleanCategoryId,
        filterFields: filterFields,
      );
      return;
    }

    try {
      String tUrl = thumbPath;
      if (!_isUsableThumb(tUrl) && recVideoPath.isNotEmpty) {
        try {
          final gen = await VideoThumbnailGenerator.generateThumbnailFromVideo(recVideoPath)
              .timeout(const Duration(seconds: 4), onTimeout: () => null);
          if (gen != null && await gen.exists()) tUrl = gen.path;
        } catch (_) {}
      }
      tUrl = await _maybeUploadMedia(tUrl, isVideo: false);

      final sToken = _sessionToken();
      if (sToken == null) return;

      final res = await _repository.updateDraft(
        videoId: videoId,
        body: {
          'challengeId': cleanChallengeId,
          'categoryId': (cleanCategoryId != null && cleanCategoryId.isNotEmpty)
              ? cleanCategoryId
              : null,
          'title': title,
          'description': description,
          'thumbnailUrl': tUrl,
          'hashtags': hashtags.isNotEmpty ? hashtags : ['dance', 'talent', 'artable'],
          'durationSeconds': durationSeconds,
          if ((filterFields['filterId'] as String) != 'natural')
            'filterId': filterFields['filterId'],
          if (filterFields['beautyOn'] == true) 'beautyOn': true,
          if ((filterFields['beautyIntensity'] as num) > 0)
            'beautyIntensity': filterFields['beautyIntensity'],
        },
        sessionToken: sToken,
        refreshToken: _refreshTokenOrNull(),
      );
      if (!res.success || res.data == null) return;

      final ui = res.data!.toUiMap();
      Map<String, dynamic>? current;
      for (final d in state.drafts) {
        if (d['id'] == videoId) {
          current = d;
          break;
        }
      }
      final merged = {...?current, ...ui};
      if (state.recordedVideoPath != null && state.recordedVideoPath!.isNotEmpty) {
        merged['videoPath'] = state.recordedVideoPath;
      }
      if (state.mergedClipPaths != null && state.mergedClipPaths!.isNotEmpty) {
        merged['mergedClipPaths'] = state.mergedClipPaths;
      }
      if (state.mergedClipDurations != null && state.mergedClipDurations!.isNotEmpty) {
        merged['mergedClipDurations'] = state.mergedClipDurations;
      }
      if ((merged['thumbnailUrl'] == null ||
              merged['thumbnailUrl'].toString().contains('storage.example')) &&
          tUrl.isNotEmpty) {
        merged['thumbnailUrl'] = tUrl;
      }
      _attachFilterToDraftMap(merged);
      _replaceDraftById(videoId, merged);
    } catch (e) {
      debugPrint('Background draft update warning: $e');
    }
  }

  Future<Map<String, dynamic>?> saveDraftFromPreview({
    required Map<String, dynamic> challenge,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? hashtags,
    int? durationSeconds,
  }) async {
    if (state.drafts.length >= maxDraftsLimit) {
      emit(state.copyWith(
        isSavingDraft: false,
        saveDraftError: 'Draft limit reached (Max $maxDraftsLimit drafts). Please delete an existing draft to save a new video.',
      ));
      return null;
    }
    if (_draftWriteLock) return null;
    _draftWriteLock = true;

    try {
      emit(state.copyWith(clearSaveDraftError: true));

      final cleanChallengeId =
          (challenge['id']?.toString() ?? state.videoChallengeId ?? '').trim();
      final cleanCategoryId =
          (challenge['categoryId']?.toString() ?? state.videoCategoryId)?.trim();
      final draftTitle =
          (title ?? challenge['title']?.toString() ?? 'Studio Draft').trim();
      final draftDescription = description ?? 'Draft from studio preview';
      final recVideoPath = (videoUrl ?? state.recordedVideoPath ?? '').trim();
      final tags = (hashtags != null && hashtags.isNotEmpty)
          ? hashtags
          : <String>['dance', 'talent', 'artable'];
      final durSecs = _parseDurationSeconds(durationSeconds);
      final resolvedThumb = _fallbackThumb(
        recVideoPath: recVideoPath,
        currentThumb: (thumbnailUrl ?? state.selectedThumbnailPath ?? '').trim(),
        challenge: challenge,
      );

      final filterFields = Map<String, dynamic>.from(_filterPersistFields());
      final embeddedDescription = _descriptionWithFilter(draftDescription);
      final draftTrack =
          state.selectedTrack ?? MusicApiService.resolveByName(state.selectedMusic);
      final localId = 'd${DateTime.now().millisecondsSinceEpoch}';
      final localDraft = <String, dynamic>{
        'id': localId,
        'challengeId': cleanChallengeId,
        'challengeTitle': draftTitle,
        'title': draftTitle,
        'description': embeddedDescription,
        'duration': state.recordedDuration,
        'durationSeconds': durSecs,
        'recordedAt': DateTime.now().toIso8601String(),
        'thumbnailUrl': resolvedThumb,
        'thumbnailPath': resolvedThumb,
        'videoPath': recVideoPath,
        'videoUrl': recVideoPath,
        if (state.mergedClipPaths != null) 'mergedClipPaths': state.mergedClipPaths,
        if (state.mergedClipDurations != null)
          'mergedClipDurations': state.mergedClipDurations,
        if (state.mergedClipFilterIds != null)
          'mergedClipFilterIds': state.mergedClipFilterIds,
        if (draftTrack != null) ...{
          'musicUrl': draftTrack.audioUrl,
          'musicName':
              state.selectedMusic ?? '${draftTrack.title} — ${draftTrack.artist}',
          'musicStartSeconds': state.musicStartSeconds,
          'musicCropDuration': state.musicCropDuration,
        },
        ...state.recordingEffectsPayload,
      };
      _attachFilterToDraftMap(localDraft, videoUrl: recVideoPath);
      if (draftTrack != null) {
        ReelHelpers.cacheMusic(
          localId,
          ReelMusicMeta(
            url: draftTrack.audioUrl,
            name: state.selectedMusic ?? '${draftTrack.title} — ${draftTrack.artist}',
            startSeconds: state.musicStartSeconds,
            durationSeconds: state.musicCropDuration,
          ),
        );
      }

      final updated = List<Map<String, dynamic>>.from(state.drafts)..insert(0, localDraft);
      emit(state.copyWith(
        drafts: updated,
        isSavingDraft: false,
        activeDraftId: localId,
      ));

      unawaited(_syncNewDraftInBackground(
        localId: localId,
        title: draftTitle,
        description: embeddedDescription,
        recVideoPath: recVideoPath,
        thumbPath: resolvedThumb,
        hashtags: tags,
        durationSeconds: durSecs,
        cleanChallengeId: cleanChallengeId,
        cleanCategoryId: cleanCategoryId,
        filterFields: filterFields,
      ));

      return localDraft;
    } finally {
      _draftWriteLock = false;
    }
  }

  Future<Map<String, dynamic>?> updateDraftDetails({
    required String videoId,
    Map<String, dynamic>? challenge,
    String? challengeId,
    String? categoryId,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<String>? hashtags,
    int? durationSeconds,
  }) async {
    final cleanVideoId = videoId.trim();
    if (cleanVideoId.isEmpty) return null;
    if (_draftWriteLock) return null;
    _draftWriteLock = true;

    try {
      emit(state.copyWith(clearSaveDraftError: true));

      final cleanChallengeId = (challengeId ??
              challenge?['id']?.toString() ??
              state.videoChallengeId ??
              '')
          .trim();
      final cleanCategoryId = (categoryId ??
              challenge?['categoryId']?.toString() ??
              state.videoCategoryId)
          ?.trim();
      final draftTitle =
          (title ?? challenge?['title']?.toString() ?? 'My Dance Entry').trim();
      final draftDescription = description ?? 'This is my challenge performance.';
      final recVideoPath = (state.recordedVideoPath ?? '').trim();
      final tags = (hashtags != null && hashtags.isNotEmpty)
          ? hashtags
          : <String>['dance', 'talent', 'artable'];
      final durSecs = _parseDurationSeconds(durationSeconds);
      final resolvedThumb = _fallbackThumb(
        recVideoPath: recVideoPath,
        currentThumb: (thumbnailUrl ?? state.selectedThumbnailPath ?? '').trim(),
        challenge: challenge,
      );

      final filterFields = Map<String, dynamic>.from(_filterPersistFields());
      final embeddedDescription = _descriptionWithFilter(draftDescription);
      final localPatch = <String, dynamic>{
        'id': cleanVideoId,
        'challengeId': cleanChallengeId,
        'challengeTitle': draftTitle,
        'title': draftTitle,
        'description': embeddedDescription,
        'thumbnailUrl': resolvedThumb,
        'thumbnailPath': resolvedThumb,
        'duration': state.recordedDuration,
        'durationSeconds': durSecs,
        'hashtags': tags,
      };
      if (recVideoPath.isNotEmpty) {
        localPatch['videoPath'] = recVideoPath;
        localPatch['videoUrl'] = recVideoPath;
      }
      if (state.mergedClipPaths != null && state.mergedClipPaths!.isNotEmpty) {
        localPatch['mergedClipPaths'] = state.mergedClipPaths;
      }
      if (state.mergedClipDurations != null && state.mergedClipDurations!.isNotEmpty) {
        localPatch['mergedClipDurations'] = state.mergedClipDurations;
      }
      if (state.mergedClipFilterIds != null && state.mergedClipFilterIds!.isNotEmpty) {
        localPatch['mergedClipFilterIds'] = state.mergedClipFilterIds;
      }
      _attachFilterToDraftMap(localPatch, videoUrl: recVideoPath);

      final updatedDrafts = state.drafts.map((d) {
        if (d['id'] == cleanVideoId) {
          return {...d, ...localPatch};
        }
        return d;
      }).toList();

      emit(state.copyWith(
        drafts: updatedDrafts,
        isSavingDraft: false,
      ));

      unawaited(_syncUpdateDraftInBackground(
        videoId: cleanVideoId,
        title: draftTitle,
        description: embeddedDescription,
        recVideoPath: recVideoPath,
        thumbPath: resolvedThumb,
        hashtags: tags,
        durationSeconds: durSecs,
        cleanChallengeId: cleanChallengeId,
        cleanCategoryId: cleanCategoryId,
        filterFields: filterFields,
      ));

      return localPatch;
    } finally {
      _draftWriteLock = false;
    }
  }

  Future<void> fetchDraftsList({String? challengeId, bool forceRefresh = false}) async {
    final hasCache = state.drafts.isNotEmpty;
    if (!forceRefresh && hasCache) {
      unawaited(_refreshDraftsFromNetwork(challengeId, showSpinner: false));
      return;
    }
    await _refreshDraftsFromNetwork(
      challengeId,
      showSpinner: !hasCache,
    );
  }

  Future<void> _refreshDraftsFromNetwork(
    String? challengeId, {
    required bool showSpinner,
  }) async {
    if (_draftsFetchInFlight) return;
    _draftsFetchInFlight = true;
    if (showSpinner) {
      emit(state.copyWith(isLoadingDrafts: true));
    }

    try {
      final res = await _repository.getDraftsList(
        challengeId: challengeId,
        sessionToken: _sessionToken(),
        refreshToken: _refreshTokenOrNull(),
      );

      if (res.success) {
        final uiDrafts = res.data.map((d) => d.toUiMap()).toList();
        emit(state.copyWith(
          drafts: _mergeIncomingDrafts(uiDrafts),
          isLoadingDrafts: false,
        ));
      } else if (state.isLoadingDrafts) {
        emit(state.copyWith(isLoadingDrafts: false));
      }
    } catch (e) {
      debugPrint('StudioCubit fetchDraftsList error: $e');
      if (state.isLoadingDrafts) {
        emit(state.copyWith(isLoadingDrafts: false));
      }
    } finally {
      _draftsFetchInFlight = false;
    }
  }

  String get recordedDuration => state.recordedDuration;
  String? get recordedVideoPath => state.recordedVideoPath;
  String? get selectedThumbnailPath => state.selectedThumbnailPath;
  String? get videoTitle => state.videoTitle;
  String? get videoDescription => state.videoDescription;
  String? get videoCategoryId => state.videoCategoryId;
  String? get videoHashtags => state.videoHashtags;
  String? get videoChallengeId => state.videoChallengeId;
  VideoPlayerController? get activeVideoController => state.activeVideoController;

  String? get activeDraftId => state.activeDraftId;

  void setActiveDraftId(String? draftId) {
    if (draftId == null) {
      emit(state.copyWith(clearActiveDraftId: true));
    } else {
      emit(state.copyWith(activeDraftId: draftId));
    }
  }

  void setSelectedThumbnailPath(String? path) {
    if (path == null) {
      emit(state.copyWith(clearSelectedThumbnailPath: true));
    } else {
      emit(state.copyWith(selectedThumbnailPath: path));
    }
  }

  String? getThumbnailForClip(String path) {
    if (path.isEmpty) return null;
    final clean = path.trim().replaceFirst('file://', '').replaceAll('\\', '/').toLowerCase();

    // 1. Check if it matches recorded video
    final rec = (state.recordedVideoPath ?? '').trim().replaceFirst('file://', '').replaceAll('\\', '/').toLowerCase();
    if (rec.isNotEmpty && rec == clean) {
      if (state.selectedThumbnailPath != null && state.selectedThumbnailPath!.isNotEmpty) {
        return state.selectedThumbnailPath;
      }
    }

    // 2. Search in drafts
    for (final d in state.drafts) {
      final vp = (d['videoPath']?.toString() ?? d['videoUrl']?.toString() ?? '')
          .trim().replaceFirst('file://', '').replaceAll('\\', '/').toLowerCase();
      if (vp.isNotEmpty && vp == clean) {
        final t = (d['thumbnailPath'] as String?) ?? (d['thumbnailUrl'] as String?);
        if (t != null && t.isNotEmpty) return t;
      }
      if (d['mergedClipPaths'] is List && d['mergedClipThumbnails'] is List) {
        final mPaths = List<String>.from(d['mergedClipPaths'] as List);
        final mThumbs = List<String>.from(d['mergedClipThumbnails'] as List);
        for (int i = 0; i < mPaths.length && i < mThumbs.length; i++) {
          final p = mPaths[i].trim().replaceFirst('file://', '').replaceAll('\\', '/').toLowerCase();
          if (p == clean && mThumbs[i].isNotEmpty) {
            return mThumbs[i];
          }
        }
      }
    }
    return null;
  }

  void setVideoSubmissionDetails({
    required String title,
    String? description,
    String? categoryId,
    String? hashtags,
    String? challengeId,
    String? draftId,
  }) {
    emit(state.copyWith(
      videoTitle: title,
      videoDescription: description,
      videoCategoryId: categoryId,
      videoHashtags: hashtags,
      videoChallengeId: challengeId,
      activeDraftId: draftId,
    ));
  }
  String? get selectedMusic => state.selectedMusic;
  FreeToUseTrack? get selectedTrack => state.selectedTrack;
  double get musicStartSeconds => state.musicStartSeconds;
  double get musicCropDuration => state.musicCropDuration;
  double get musicEndSeconds => state.musicEndSeconds;
  String get videoCropAspectRatio => state.videoCropAspectRatio;
  StudioCameraMode get cameraMode => state.cameraMode;
  bool get isFrontCamera => state.isFrontCamera;
  String get selectedFilter => state.selectedFilter;
  String get selectedSpeed => state.selectedSpeed;
  bool get beautyOn => state.beautyOn;

  double get effectiveVideoDuration {
    // 1. If multiple clips exist, total duration is the sum of all clips' durations!
    if (state.mergedClipDurations != null && state.mergedClipDurations!.isNotEmpty) {
      final sum = state.mergedClipDurations!.fold(0.0, (acc, d) => acc + d);
      if (sum > 0) return sum;
    }
    // 2. Parse recordedDuration formatted string (e.g. "0:22")
    final parts = state.recordedDuration.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      final total = m * 60 + s;
      if (total > 0) return total.toDouble();
    }
    final start = state.videoTrimStartSeconds;
    final end = state.videoTrimEndSeconds;
    if (end != null && end > start) {
      return end - start;
    }
    return 15.0;
  }

  void setSelectedTrack(
    FreeToUseTrack? track, {
    double start = 0.0,
    double? duration,
  }) {
    // Force music service to reload the new (or cleared) track.
    StudioMusicPlaybackService.invalidateLoadedTrack();
    if (track != null) {
      final targetDuration = duration ?? effectiveVideoDuration;
      final validStart = start.clamp(0.0, track.duration);
      final maxRemain = (track.duration - validStart).clamp(1.0, track.duration);
      final validDuration = targetDuration.clamp(1.0, maxRemain);
      emit(state.copyWith(
        selectedTrack: track,
        selectedMusic: '${track.title} — ${track.artist}',
        musicStartSeconds: validStart,
        musicCropDuration: validDuration,
      ));
    } else {
      emit(state.copyWith(
        clearSelectedMusic: true,
        musicStartSeconds: 0.0,
        musicCropDuration: effectiveVideoDuration,
      ));
    }
  }
  double get beautyIntensity => state.beautyIntensity;
  String get recordingFilter => state.recordingFilter;
  bool get recordingBeautyOn => state.recordingBeautyOn;
  double get recordingBeautyIntensity => state.recordingBeautyIntensity;
  bool get isMuted => state.isMuted;
  List<Map<String, dynamic>> get drafts => state.drafts;
  Map<String, dynamic> get recordingEffectsPayload => state.recordingEffectsPayload;

  void toggleMute() {
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void setMuted(bool value) {
    emit(state.copyWith(isMuted: value));
  }

  double get speedMultiplier {
    final clean = state.selectedSpeed.replaceAll('x', '').trim();
    return double.tryParse(clean) ?? 1.0;
  }

  void snapshotRecordingEffects() {
    emit(state.copyWith(
      recordingFilter: state.selectedFilter,
      recordingBeautyOn: state.beautyOn,
      recordingBeautyIntensity: state.beautyIntensity,
    ));
  }

  void restoreRecordingEffects({
    String? filterId,
    bool? beautyOn,
    double? beautyIntensity,
    String? cropAspectRatio,
    double? trimStart,
    double? trimEnd,
    bool? isMuted,
    String? speed,
  }) {
    final id = filterId?.trim();
    final hasFilter = id != null && id.isNotEmpty;
    emit(state.copyWith(
      recordingFilter: hasFilter ? id : state.recordingFilter,
      selectedFilter: hasFilter ? id : state.selectedFilter,
      recordingBeautyOn: beautyOn ?? state.recordingBeautyOn,
      beautyOn: beautyOn ?? state.beautyOn,
      recordingBeautyIntensity: beautyIntensity ?? state.recordingBeautyIntensity,
      beautyIntensity: beautyIntensity ?? state.beautyIntensity,
      videoCropAspectRatio: cropAspectRatio ?? state.videoCropAspectRatio,
      videoTrimStartSeconds: trimStart ?? state.videoTrimStartSeconds,
      videoTrimEndSeconds: trimEnd ?? state.videoTrimEndSeconds,
      isMuted: isMuted ?? state.isMuted,
      selectedSpeed: speed ?? state.selectedSpeed,
    ));
  }

  static String normalizeFilterId(String? id) {
    final v = (id ?? '').trim();
    return v.isEmpty ? 'natural' : v;
  }

  static String filterIdOfDraft(Map<String, dynamic> d) {
    final meta = ReelHelpers.resolveFilter(
      filterId: d['filterId']?.toString() ?? d['filter_id']?.toString(),
      beautyOn: d['beautyOn'] == true || d['beauty_on'] == true,
      beautyIntensity: (d['beautyIntensity'] as num?)?.toDouble() ??
          (d['beauty_intensity'] as num?)?.toDouble(),
      description: d['description']?.toString(),
      videoId: d['id']?.toString(),
      videoUrl: (d['videoUrl'] ?? d['videoPath'])?.toString(),
    );
    return normalizeFilterId(meta?.filterId ?? d['filterId']?.toString());
  }

  static List<String> clipFilterIdsOfDraft(Map<String, dynamic> d, {int? pathCount}) {
    final n = pathCount ??
        ((d['mergedClipPaths'] is List && (d['mergedClipPaths'] as List).isNotEmpty)
            ? (d['mergedClipPaths'] as List).length
            : 1);
    final count = n < 1 ? 1 : n;
    final raw = d['mergedClipFilterIds'];
    if (raw is List && raw.isNotEmpty) {
      final ids = raw.map((e) => normalizeFilterId(e?.toString())).toList();
      if (ids.length >= count) return ids.sublist(0, count);
      final fallback = filterIdOfDraft(d);
      return [...ids, ...List<String>.filled(count - ids.length, fallback)];
    }
    return List<String>.filled(count, filterIdOfDraft(d));
  }

  void applyDraftFilterToSession(Map<String, dynamic>? draft) {
    if (draft == null) return;
    final meta = ReelHelpers.resolveFilter(
      filterId: draft['filterId']?.toString() ?? draft['filter_id']?.toString(),
      beautyOn: draft['beautyOn'] == true || draft['beauty_on'] == true,
      beautyIntensity: (draft['beautyIntensity'] as num?)?.toDouble() ??
          (draft['beauty_intensity'] as num?)?.toDouble(),
      description: draft['description']?.toString(),
      videoId: draft['id']?.toString(),
      videoUrl: (draft['videoUrl'] ?? draft['videoPath'])?.toString(),
    );
    restoreRecordingEffects(
      filterId: meta?.filterId ?? 'natural',
      beautyOn: meta?.beautyOn ?? false,
      beautyIntensity: meta?.beautyIntensity ?? 0,
    );
    _restoreMusicFromDraft(draft);
  }

  void _restoreMusicFromDraft(Map<String, dynamic> draft) {
    final music = ReelHelpers.resolveMusic(
      description: draft['description']?.toString(),
      musicUrl: draft['musicUrl']?.toString() ?? draft['music_url']?.toString(),
      musicName: draft['musicName']?.toString() ?? draft['music']?.toString(),
      startSeconds: (draft['musicStartSeconds'] as num?)?.toDouble(),
      durationSeconds: (draft['musicCropDuration'] as num?)?.toDouble(),
      videoId: draft['id']?.toString(),
      videoUrl: (draft['videoUrl'] ?? draft['videoPath'])?.toString(),
    );
    if (music == null || music.url.isEmpty) return;
    final resolved = MusicApiService.resolveByUrl(music.url) ??
        MusicApiService.resolveByName(
          music.name.isNotEmpty ? music.name : state.selectedMusic,
        );
    final track = resolved ??
        FreeToUseTrack(
          id: 'draft_music',
          title: music.name.isNotEmpty ? music.name.split(' — ').first : 'Track',
          artist: music.name.contains(' — ')
              ? music.name.split(' — ').skip(1).join(' — ')
              : 'Unknown',
          duration: music.durationSeconds > 0 ? music.durationSeconds : 180,
          coverUrl: '',
          audioUrl: music.url,
          waveform: const [],
          category: 'All',
        );
    setSelectedTrack(
      track,
      start: music.startSeconds,
      duration: music.durationSeconds > 0 ? music.durationSeconds : null,
    );
  }

  Map<String, dynamic> _filterPersistFields() {
    final id = state.recordingFilter.trim();
    return {
      'filterId': id.isEmpty ? 'natural' : id,
      'beautyOn': state.recordingBeautyOn,
      'beautyIntensity': state.recordingBeautyIntensity,
    };
  }

  String _descriptionWithFilter(String? description, {String? filterId}) {
    final withFilter = ReelHelpers.embedFilterInDescription(
      description,
      filterId: filterId ?? state.recordingFilter,
      beautyOn: state.recordingBeautyOn,
      beautyIntensity: state.recordingBeautyIntensity,
    );
    final track = state.selectedTrack ?? MusicApiService.resolveByName(state.selectedMusic);
    if (track == null || track.audioUrl.trim().isEmpty) return withFilter;
    return ReelHelpers.embedMusicInDescription(
      withFilter,
      ReelMusicMeta(
        url: track.audioUrl.trim(),
        name: state.selectedMusic ?? '${track.title} — ${track.artist}',
        startSeconds: state.musicStartSeconds,
        durationSeconds: state.musicCropDuration,
      ),
    );
  }

  void _attachFilterToDraftMap(Map<String, dynamic> draft, {String? videoUrl, String? filterId}) {
    final fields = Map<String, dynamic>.from(_filterPersistFields());
    if (filterId != null) {
      fields['filterId'] = normalizeFilterId(filterId);
    }
    draft.addAll(fields);
    final id = draft['id']?.toString();
    final url = videoUrl ?? draft['videoUrl']?.toString() ?? draft['videoPath']?.toString();
    ReelHelpers.cacheFilter(
      id,
      (
        filterId: fields['filterId'] as String,
        beautyOn: fields['beautyOn'] as bool,
        beautyIntensity: (fields['beautyIntensity'] as num).toDouble(),
      ),
    );
    ReelHelpers.cacheFilter(url, (
      filterId: fields['filterId'] as String,
      beautyOn: fields['beautyOn'] as bool,
      beautyIntensity: (fields['beautyIntensity'] as num).toDouble(),
    ));
  }

  void setRecordedDuration(String duration) {
    double? recSecs;
    final parts = duration.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      final total = m * 60 + s;
      if (total > 0) recSecs = total.toDouble();
    }
    if (recSecs != null && recSecs > 0) {
      emit(state.copyWith(
        recordedDuration: duration,
        musicCropDuration: recSecs,
        videoTrimStartSeconds: 0.0,
        videoTrimEndSeconds: recSecs,
      ));
    } else {
      emit(state.copyWith(recordedDuration: duration));
    }
  }

  void setRecordedVideoPath(String? path, {List<String>? mergedClipPaths, bool clearMergedClips = false}) {
    if (path == null) {
      emit(state.copyWith(
        clearRecordedVideoPath: true,
        clearMergedClipPaths: true,
        videoTrimStartSeconds: 0.0,
        clearVideoTrimEndSeconds: true,
        recordingFilter: state.selectedFilter,
        recordingBeautyOn: state.beautyOn,
        recordingBeautyIntensity: state.beautyIntensity,
      ));
    } else {
      // New recording — reset trim so Edit doesn't reuse a stale range.
      emit(state.copyWith(
        recordedVideoPath: path,
        mergedClipPaths: mergedClipPaths,
        clearMergedClipPaths: clearMergedClips && (mergedClipPaths == null || mergedClipPaths.isEmpty),
        videoTrimStartSeconds: 0.0,
        clearVideoTrimEndSeconds: true,
      ));
    }
  }

  void setMergedClipPaths(List<String>? paths, [List<double>? durations, List<String>? filterIds]) {
    if (paths == null || paths.isEmpty) {
      emit(state.copyWith(
        clearMergedClipPaths: true,
      ));
    } else {
      emit(state.copyWith(
        mergedClipPaths: paths,
        mergedClipDurations: durations,
        mergedClipFilterIds: filterIds,
      ));
    }
  }

  Future<VideoPlayerController?> prepareVideoPreview(String path) async {
    if (state.recordedVideoPath != path && state.activeVideoController != null) {
      await state.activeVideoController?.dispose();
      emit(state.copyWith(clearActiveVideoController: true));
    }

    if (state.activeVideoController != null &&
        state.activeVideoController!.value.isInitialized) {
      return state.activeVideoController;
    }

    String cleanPath = path;
    if (cleanPath.startsWith('file://')) {
      cleanPath = cleanPath.replaceFirst('file://', '');
    }

    try {
      final controller = cleanPath.startsWith('http://') ||
              cleanPath.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(cleanPath))
          : VideoPlayerController.file(File(cleanPath));

      await controller.initialize();
      await controller.setLooping(true);
      emit(state.copyWith(activeVideoController: controller));
      return controller;
    } catch (e) {
      debugPrint('StudioCubit prepareVideoPreview error for $path: $e');
      return null;
    }
  }

  void clearActiveVideoController({bool dispose = true}) {
    if (dispose) {
      state.activeVideoController?.dispose();
    }
    emit(state.copyWith(clearActiveVideoController: true));
  }

  void setSelectedMusic(String? music) {
    if (music == null) {
      emit(state.copyWith(clearSelectedMusic: true));
    } else {
      emit(state.copyWith(selectedMusic: music));
    }
  }

  void updateMusicCrop(double start, double duration) {
    emit(state.copyWith(
      musicStartSeconds: start,
      musicCropDuration: duration,
    ));
  }

  void setVideoCropAspectRatio(String aspectRatio) {
    emit(state.copyWith(videoCropAspectRatio: aspectRatio));
  }

  void setVideoTrimRange({
    required double start,
    required double end,
    required String formattedDuration,
  }) {
    emit(state.copyWith(
      videoTrimStartSeconds: start,
      videoTrimEndSeconds: end,
      recordedDuration: formattedDuration,
    ));
  }

  void toggleCameraMode() {
    final nextMode = state.cameraMode == StudioCameraMode.back
        ? StudioCameraMode.front
        : StudioCameraMode.back;
    emit(state.copyWith(cameraMode: nextMode));
  }

  void setCameraMode(StudioCameraMode mode) {
    emit(state.copyWith(cameraMode: mode));
  }

  void setFilter(String filter) {
    emit(state.copyWith(
      selectedFilter: filter,
      recordingFilter: filter,
    ));
  }

  void setSpeed(String speed) {
    emit(state.copyWith(selectedSpeed: speed));
  }

  void setBeautyOn(bool value) {
    emit(state.copyWith(
      beautyOn: value,
      recordingBeautyOn: value,
    ));
  }

  void setBeautyIntensity(double value) {
    emit(state.copyWith(
      beautyIntensity: value,
      recordingBeautyIntensity: value,
    ));
  }

  void addDraft(Map<String, dynamic> draft) {
    if (state.drafts.length >= maxDraftsLimit) return;
    final updated = List<Map<String, dynamic>>.from(state.drafts);
    updated.insert(0, draft);
    emit(state.copyWith(drafts: updated));
  }

  void updateDraftMap(Map<String, dynamic> draft) {
    final id = draft['id']?.toString();
    if (id == null || id.isEmpty) return;
    final updated = state.drafts.map((d) {
      if (d['id'] == id) {
        return {...d, ...draft};
      }
      return d;
    }).toList();
    emit(state.copyWith(drafts: updated));
  }

  Future<bool> deleteDraft(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    final previousDrafts = List<Map<String, dynamic>>.from(state.drafts);
    final updated = List<Map<String, dynamic>>.from(state.drafts)
      ..removeWhere((d) => d['id'] == cleanId);
    emit(state.copyWith(drafts: updated));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _repository.deleteDraft(
        videoId: cleanId,
        sessionToken: (token != null && token != 'design_preview') ? token : null,
        refreshToken: (refresh != null && refresh != 'design_preview') ? refresh : null,
      );

      final isSuccess = res['success'] == true;
      if (!isSuccess && !cleanId.startsWith('d')) {
        emit(state.copyWith(drafts: previousDrafts));
      }
      return isSuccess || cleanId.startsWith('d');
    } catch (e) {
      debugPrint('StudioCubit deleteDraft error for $cleanId: $e');
      if (!cleanId.startsWith('d')) {
        emit(state.copyWith(drafts: previousDrafts));
      }
      return cleanId.startsWith('d');
    }
  }

  void resetSession() {
    prepareFreshRecording();
  }

  /// Clears leftover draft music/filter/mute so a new in-app recording starts clean.
  void prepareFreshRecording() {
    state.activeVideoController?.dispose();
    StudioMusicPlaybackService.invalidateLoadedTrack();
    unawaited(StudioMusicPlaybackService.stop());
    emit(state.copyWith(
      recordedDuration: '0:00',
      clearRecordedVideoPath: true,
      clearSelectedThumbnailPath: true,
      clearSelectedMusic: true,
      clearActiveVideoController: true,
      musicStartSeconds: 0.0,
      musicCropDuration: 30.0,
      videoCropAspectRatio: '9:16',
      videoTrimStartSeconds: 0.0,
      clearVideoTrimEndSeconds: true,
      cameraMode: StudioCameraMode.back,
      selectedFilter: 'natural',
      selectedSpeed: '1x',
      beautyOn: false,
      beautyIntensity: 50,
      recordingFilter: 'natural',
      recordingBeautyOn: false,
      recordingBeautyIntensity: 50,
      isMuted: false,
      clearMergedClipPaths: true,
      clearActiveDraftId: true,
      videoTitle: '',
      videoDescription: '',
      videoHashtags: '',
    ));
  }

  @override
  Future<void> close() {
    state.activeVideoController?.dispose();
    return super.close();
  }
}
