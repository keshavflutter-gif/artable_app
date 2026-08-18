import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/home/data/models/home_dashboard_response.dart';
import 'package:artable_app/features/home/data/repositories/home_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AuthCubit authCubit,
    HomeRepository? homeRepository,
  })  : _authCubit = authCubit,
        _homeRepository = homeRepository ??
            HomeRepository(
              onTokensRefreshed: authCubit.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
            ),
        super(const HomeState()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
  }

  final AuthCubit _authCubit;
  final HomeRepository _homeRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;

  HomeDashboardResponse? get dashboard => state.dashboard;
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;
  List<Map<String, dynamic>> get megaPromoBanners => state.megaPromoBanners;
  List<Map<String, dynamic>> get heroBannerSlides => state.heroBannerSlides;
  List<Map<String, dynamic>> get activeChallenges => state.activeChallenges;
  List<Map<String, dynamic>> get trendingReels => state.trendingReels;
  List<Map<String, dynamic>> get categories => state.categories;

  void _onAuthStateChanged(AuthState authState) {
    final newToken = authState.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        _lastSessionToken != newToken) {
      _lastSessionToken = newToken;
      emit(state.copyWith(hasLoaded: false));
      loadHomeDashboard(forceRefresh: true);
    }
  }

  Future<void> loadHomeDashboard({bool forceRefresh = false}) async {
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
        final dashboard = await _homeRepository.getHomeDashboard(
          sessionToken: token,
          refreshToken: refresh,
        );
        emit(state.copyWith(
          dashboard: dashboard,
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

    // Design-only / unauthenticated: use mock data.
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
      loadHomeDashboard(forceRefresh: true);
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
