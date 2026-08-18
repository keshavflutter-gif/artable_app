import 'package:artable_app/features/rewards/data/models/rewards_dashboard_response.dart';

class RewardsState {
  const RewardsState({
    this.coins = 0,
    this.streakDays = 0,
    this.claimedToday = false,
    this.notifications = const [],
    this.selectedTab = 'All',
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.response,
    this.wallet,
    this.featuredReward,
    this.rewards = const [],
    this.tabs = defaultTabs,
  });

  static const List<String> defaultTabs = [
    'All',
    'Cash',
    'Vouchers',
    'Products',
    'Sponsor',
  ];

  final int coins;
  final int streakDays;
  final bool claimedToday;
  final List<Map<String, dynamic>> notifications;
  final String selectedTab;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final RewardsDashboardResponse? response;
  final RewardsWallet? wallet;
  final RewardItem? featuredReward;
  final List<RewardItem> rewards;
  final List<String> tabs;

  int get effectiveCoins => wallet?.coins ?? coins;

  int get unreadNotificationsCount =>
      notifications.where((n) => (n['read'] as bool? ?? false) == false).length;

  List<String> get availableTabs => tabs.isNotEmpty ? tabs : defaultTabs;

  String get availableBalanceFormatted {
    if (response?.data != null) {
      return response!.data!.displayAvailableBalance;
    }
    return '₹0';
  }

  String get totalEarnedFormatted {
    if (response?.data != null) {
      return response!.data!.displayTotalEarned;
    }
    return '₹0';
  }

  Map<String, dynamic>? get featuredRewardAsUiMap {
    if (featuredReward != null) {
      return featuredReward!.toUiMap();
    }
    return null;
  }

  List<Map<String, dynamic>> get rewardsAsUiMaps {
    return rewards.map((r) => r.toUiMap()).toList();
  }

  RewardsState copyWith({
    int? coins,
    int? streakDays,
    bool? claimedToday,
    List<Map<String, dynamic>>? notifications,
    String? selectedTab,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    RewardsDashboardResponse? response,
    RewardsWallet? wallet,
    RewardItem? featuredReward,
    List<RewardItem>? rewards,
    List<String>? tabs,
    bool clearError = false,
  }) {
    return RewardsState(
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      claimedToday: claimedToday ?? this.claimedToday,
      notifications: notifications ?? this.notifications,
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      response: response ?? this.response,
      wallet: wallet ?? this.wallet,
      featuredReward: featuredReward ?? this.featuredReward,
      rewards: rewards ?? this.rewards,
      tabs: tabs ?? this.tabs,
    );
  }
}
