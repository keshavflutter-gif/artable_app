import 'package:artable_app/features/profile/data/models/profile_response.dart';

class ProfileState {
  const ProfileState({
    this.response,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final ProfileResponse? response;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  ProfileData? get data => response?.data;

  ProfileState copyWith({
    ProfileResponse? response,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
