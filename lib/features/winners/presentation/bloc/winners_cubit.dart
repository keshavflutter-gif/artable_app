import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/winners/data/models/winners_response.dart';
import 'package:artable_app/features/winners/data/repositories/winners_repository.dart';
import 'winners_state.dart';

class WinnersCubit extends Cubit<WinnersState> {
  WinnersCubit({
    AuthCubit? authCubit,
    WinnersRepository? winnersRepository,
  })  : _authCubit = authCubit,
        _winnersRepository = winnersRepository ??
            WinnersRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const WinnersState());

  final AuthCubit? _authCubit;
  final WinnersRepository _winnersRepository;

  bool get hasLoaded => state.hasLoaded;

  Future<void> loadWinners({bool forceRefresh = false, String? tab}) async {
    final targetTab = tab ?? state.selectedTab;
    if (state.hasLoaded && !forceRefresh && !state.isLoading && targetTab == state.selectedTab) {
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      selectedTab: targetTab,
      clearError: true,
    ));

    try {
      final res = await _winnersRepository.getWinners(
        tab: targetTab,
        sessionToken: _authCubit?.sessionToken,
        refreshToken: _authCubit?.refreshToken,
      );

      final tabsList = res.tabs.isNotEmpty ? res.tabs : state.availableTabs;

      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
        response: res,
        availableTabs: tabsList,
        featuredWinner: res.featuredWinner,
        clearFeaturedWinner: res.featuredWinner == null,
        winners: res.winners,
        moreWinners: res.moreWinners,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load winners: $e',
      ));
    }
  }

  void selectTab(String tab) {
    if (state.selectedTab.toLowerCase() == tab.toLowerCase() && state.hasLoaded) return;
    loadWinners(forceRefresh: true, tab: tab);
  }

  WinnerItem? getWinnerById(String id) {
    if (state.featuredWinner?.id == id) {
      return state.featuredWinner;
    }
    for (final w in state.winners) {
      if (w.id == id) return w;
    }
    for (final w in state.moreWinners) {
      if (w.id == id) return w;
    }
    return null;
  }
}
