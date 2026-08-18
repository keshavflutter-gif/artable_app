import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/profile/data/models/profile_stats_response.dart';
import 'package:artable_app/features/profile/data/repositories/stats_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit({
    required AuthCubit authCubit,
    StatsRepository? statsRepository,
  })  : _authCubit = authCubit,
        _statsRepository = statsRepository ??
            StatsRepository(
              onTokensRefreshed: authCubit.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
            ),
        super(const StatsState()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
  }

  final AuthCubit _authCubit;
  final StatsRepository _statsRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;

  ProfileStatsResponse? get response => state.response;
  ProfileStatsData? get data => state.data;
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
      loadStats(forceRefresh: true);
    }
  }

  Future<void> loadStats({bool forceRefresh = false}) async {
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
        final response = await _statsRepository.getProfileStats(
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
      loadStats(forceRefresh: true);
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
