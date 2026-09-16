import 'package:artable_app/features/winners/data/models/winners_response.dart';

class WinnersState {
  const WinnersState({
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.selectedTab = 'Challenge',
    this.availableTabs = const ['Challenge', 'Weekly', 'Monthly'],
    this.response,
    this.featuredWinner,
    this.winners = const [],
    this.moreWinners = const [],
  });

  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final String selectedTab;
  final List<String> availableTabs;
  final WinnersResponse? response;
  final WinnerItem? featuredWinner;
  final List<WinnerItem> winners;
  final List<WinnerItem> moreWinners;

  WinnersState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
    String? selectedTab,
    List<String>? availableTabs,
    WinnersResponse? response,
    WinnerItem? featuredWinner,
    bool clearFeaturedWinner = false,
    List<WinnerItem>? winners,
    List<WinnerItem>? moreWinners,
  }) {
    return WinnersState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedTab: selectedTab ?? this.selectedTab,
      availableTabs: availableTabs ?? this.availableTabs,
      response: response ?? this.response,
      featuredWinner: clearFeaturedWinner
          ? null
          : (featuredWinner ?? this.featuredWinner),
      winners: winners ?? this.winners,
      moreWinners: moreWinners ?? this.moreWinners,
    );
  }
}
