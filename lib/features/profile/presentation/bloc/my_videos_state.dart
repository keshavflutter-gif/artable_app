import 'package:artable_app/features/profile/data/models/my_videos_response.dart';

class MyVideosState {
  const MyVideosState({
    this.response,
    this.activeTab = 'ALL',
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final MyVideosResponse? response;
  final String activeTab;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  List<MyVideoItem> get videos => response?.data ?? const [];
  List<MyVideoTabItem> get tabs => response?.tabs ?? const [];
  MyVideoEmptyState? get emptyState => response?.emptyState;
  MyVideoPagination? get pagination => response?.pagination;

  MyVideosState copyWith({
    MyVideosResponse? response,
    String? activeTab,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyVideosState(
      response: response ?? this.response,
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
