import 'package:artable_app/features/profile/data/models/achievements_response.dart';

class AchievementsState {
  const AchievementsState({
    this.response,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final AchievementsResponse? response;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  AchievementsData? get data => response?.data;

  AchievementsState copyWith({
    AchievementsResponse? response,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AchievementsState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
