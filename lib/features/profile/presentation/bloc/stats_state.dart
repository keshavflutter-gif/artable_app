import 'package:artable_app/features/profile/data/models/profile_stats_response.dart';

class StatsState {
  const StatsState({
    this.response,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final ProfileStatsResponse? response;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  ProfileStatsData? get data => response?.data;

  StatsState copyWith({
    ProfileStatsResponse? response,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatsState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
