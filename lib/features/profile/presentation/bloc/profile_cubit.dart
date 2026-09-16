import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/profile/data/models/my_videos_response.dart';
import 'package:artable_app/features/profile/data/models/profile_response.dart';
import 'package:artable_app/features/profile/data/repositories/profile_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthCubit authCubit,
    ProfileRepository? profileRepository,
  })  : _authCubit = authCubit,
        _profileRepository = profileRepository ??
            ProfileRepository(
              onTokensRefreshed: authCubit.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
            ),
        super(const ProfileState()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
  }

  final AuthCubit _authCubit;
  final ProfileRepository _profileRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;

  ProfileResponse? get response => state.response;
  ProfileData? get data => state.data;
  ProfileUser? get user => state.data?.user;
  ProfileStats? get stats => state.data?.stats;
  List<ProfileStatCard> get statCards => state.data?.statCards ?? const [];
  List<MyVideoItem> get recentVideos => state.data?.recentVideos ?? const [];
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;

  void _onAuthStateChanged(AuthState authState) {
    final newToken = authState.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        _lastSessionToken != newToken) {
      _lastSessionToken = newToken;
      emit(state.copyWith(hasLoaded: false));
      loadProfile(forceRefresh: true);
    }
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !forceRefresh) return;

    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;

    if (token != null &&
        token.isNotEmpty &&
        token != 'design_preview' &&
        refresh != null &&
        refresh.isNotEmpty) {
      emit(state.copyWith(isLoading: true, clearError: true));

      try {
        final response = await _profileRepository.getProfile(
          sessionToken: token,
          refreshToken: refresh,
        );
        emit(state.copyWith(
          response: response,
          isLoading: false,
          hasLoaded: true,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          hasLoaded: true,
          errorMessage: e.toString(),
        ));
      }
      return;
    }

    emit(state.copyWith(
      hasLoaded: true,
      clearError: true,
    ));
  }

  void updateAuth(AuthCubit authCubit) {
    final oldToken = _lastSessionToken;
    final newToken = authCubit.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        oldToken != newToken) {
      _lastSessionToken = newToken;
      emit(state.copyWith(hasLoaded: false));
      loadProfile(forceRefresh: true);
    }
  }

  Future<bool> deleteVideo(String videoId) async {
    final token = _authCubit.sessionToken;
    final refresh = _authCubit.refreshToken;

    // Optimistically update UI state by removing the video
    if (state.data != null) {
      final updatedVideos = state.data!.recentVideos
          .where((v) => v.id != videoId)
          .toList();

      final updatedData = state.data!.copyWith(
        recentVideos: updatedVideos,
      );

      emit(state.copyWith(
        response: state.response?.copyWith(data: updatedData),
      ));
    }

    try {
      if (token != null &&
          token.isNotEmpty &&
          token != 'design_preview' &&
          refresh != null &&
          refresh.isNotEmpty) {
        await _profileRepository.deleteVideo(
          videoId: videoId,
          sessionToken: token,
          refreshToken: refresh,
        );
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

