import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/rewards/data/models/rewards_dashboard_response.dart';
import 'package:artable_app/features/rewards/data/repositories/rewards_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'rewards_state.dart';

class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit({
    AuthCubit? authCubit,
    RewardsRepository? rewardsRepository,
  })  : _authCubit = authCubit,
        _rewardsRepository = rewardsRepository ??
            RewardsRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const RewardsState());

  AuthCubit? _authCubit;
  final RewardsRepository _rewardsRepository;

  int get coins => state.effectiveCoins;
  int get streakDays => state.streakDays;
  bool get claimedToday => state.claimedToday;
  List<Map<String, dynamic>> get notifications => state.notifications;
  int get unreadNotificationsCount => state.unreadNotificationsCount;
  String get selectedTab => state.selectedTab;
  bool get isLoading => state.isLoading;
  bool get hasLoaded => state.hasLoaded;
  String? get errorMessage => state.errorMessage;
  RewardsDashboardResponse? get response => state.response;
  RewardsWallet? get wallet => state.wallet;
  RewardItem? get featuredReward => state.featuredReward;
  List<RewardItem> get rewards => state.rewards;
  List<String> get availableTabs => state.availableTabs;
  String get availableBalanceFormatted => state.availableBalanceFormatted;
  String get totalEarnedFormatted => state.totalEarnedFormatted;
  Map<String, dynamic>? get featuredRewardAsUiMap => state.featuredRewardAsUiMap;
  List<Map<String, dynamic>> get rewardsAsUiMaps => state.rewardsAsUiMaps;

  Future<void> loadRewards({String? tab, bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !forceRefresh && tab == null) return;

    final targetTab = tab ?? state.selectedTab;
    emit(state.copyWith(
      isLoading: true,
      selectedTab: targetTab,
      clearError: true,
    ));

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    try {
      final res = await _rewardsRepository.getRewards(
        tab: targetTab.toLowerCase() != 'all' ? targetTab : null,
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      List<String> tabs = state.tabs;
      if (res.data != null && res.data!.tabs.isNotEmpty) {
        final merged = <String>[...res.data!.tabs];
        for (final dTab in RewardsState.defaultTabs) {
          if (!merged.contains(dTab)) {
            merged.add(dTab);
          }
        }
        tabs = merged;
      }

      emit(state.copyWith(
        response: res,
        wallet: res.data?.wallet,
        featuredReward: res.data?.featuredReward,
        rewards: res.data?.rewards ?? const [],
        tabs: tabs,
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
  }

  void selectTab(String tab) {
    if (state.selectedTab.toLowerCase() == tab.toLowerCase()) return;
    emit(state.copyWith(selectedTab: tab));
    loadRewards(tab: tab, forceRefresh: true);
  }

  void claimDailyBonus(int amount) {
    if (!state.claimedToday) {
      emit(state.copyWith(
        coins: state.coins + amount,
        streakDays: state.streakDays + 1,
        claimedToday: true,
      ));
    }
  }

  Future<bool> claimReward(String rewardId) async {
    final cleanId = rewardId.trim();
    if (cleanId.isEmpty) return false;

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;
    if (token == null || token.isEmpty || token == 'design_preview') {
      return false;
    }

    try {
      final res = await _rewardsRepository.claimReward(
        rewardId: cleanId,
        sessionToken: token,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      if (res['success'] == false) return false;

      final updated = state.rewards.map((r) {
        if (r.id != cleanId) return r;
        return RewardItem(
          id: r.id,
          title: r.title,
          subtitle: r.subtitle,
          description: r.description,
          type: r.type,
          value: r.value,
          valueLabel: r.valueLabel,
          stock: r.stock,
          sponsorName: r.sponsorName,
          imageUrl: r.imageUrl,
          isActive: r.isActive,
          status: 'claimed',
          statusLabel: 'CLAIMED',
          isClaimed: true,
          isAvailable: false,
          claim: r.claim,
          featured: r.featured,
          expiresAt: r.expiresAt,
          brand: r.brand,
          code: r.code,
        );
      }).toList();

      RewardItem? featured = state.featuredReward;
      if (featured != null && featured.id == cleanId) {
        featured = RewardItem(
          id: featured.id,
          title: featured.title,
          subtitle: featured.subtitle,
          description: featured.description,
          type: featured.type,
          value: featured.value,
          valueLabel: featured.valueLabel,
          stock: featured.stock,
          sponsorName: featured.sponsorName,
          imageUrl: featured.imageUrl,
          isActive: featured.isActive,
          status: 'claimed',
          statusLabel: 'CLAIMED',
          isClaimed: true,
          isAvailable: false,
          claim: featured.claim,
          featured: featured.featured,
          expiresAt: featured.expiresAt,
          brand: featured.brand,
          code: featured.code,
        );
      }

      emit(state.copyWith(
        rewards: updated,
        featuredReward: featured,
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  void markAllNotificationsAsRead() {
    final updated = state.notifications.map((n) {
      final map = Map<String, dynamic>.from(n);
      map['read'] = true;
      return map;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  void markNotificationAsRead(String id) {
    final updated = state.notifications.map((n) {
      final map = Map<String, dynamic>.from(n);
      if (map['id'] == id) {
        map['read'] = true;
      }
      return map;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  void addCoins(int amount) {
    emit(state.copyWith(coins: state.coins + amount));
  }

  bool deductCoins(int amount) {
    if (state.effectiveCoins >= amount) {
      emit(state.copyWith(coins: state.coins - amount));
      return true;
    }
    return false;
  }

  void updateAuth(AuthCubit authCubit) {
    _authCubit = authCubit;
  }
}
