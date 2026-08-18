import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/challenges/data/models/categories_response.dart';
import 'package:artable_app/features/challenges/data/models/challenge_detail_response.dart';
import 'package:artable_app/features/challenges/data/repositories/categories_repository.dart';
import 'package:artable_app/features/challenges/data/repositories/challenges_repository.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_state.dart';
import 'challenges_state.dart';

class ChallengesCubit extends Cubit<ChallengesState> {
  ChallengesCubit({
    AuthCubit? authCubit,
    CategoriesRepository? categoriesRepository,
    ChallengesRepository? challengesRepository,
  })  : _authCubit = authCubit,
        _categoriesRepository = categoriesRepository ??
            CategoriesRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        _challengesRepository = challengesRepository ??
            ChallengesRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(ChallengesState()) {
    if (authCubit != null) {
      _authSubscription = authCubit.stream.listen(_onAuthStateChanged);
    }
  }

  AuthCubit? _authCubit;
  final CategoriesRepository _categoriesRepository;
  final ChallengesRepository _challengesRepository;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSessionToken;

  CategoriesResponse? get categoriesResponse => state.categoriesResponse;
  CategorySummary? get categorySummary => state.categorySummary;
  bool get isLoadingCategories => state.isLoadingCategories;
  bool get hasLoadedCategories => state.hasLoadedCategories;
  String? get categoriesErrorMessage => state.categoriesErrorMessage;
  List<Map<String, dynamic>> get categories => state.categories;
  List<Map<String, dynamic>> get challenges => state.challenges;
  String get categoryQuery => state.categoryQuery;
  String get challengeQuery => state.challengeQuery;
  String? get selectedCategoryId => state.selectedCategoryId;
  List<Map<String, dynamic>> get filteredCategories => state.filteredCategories;
  List<Map<String, dynamic>> get filteredChallenges => state.filteredChallenges;

  ChallengeDetailData? getChallengeDetail(String challengeId) =>
      state.getChallengeDetail(challengeId);
  bool isLoadingChallengeDetail(String challengeId) =>
      state.isLoadingChallengeDetail(challengeId);
  String? getChallengeDetailError(String challengeId) =>
      state.getChallengeDetailError(challengeId);
  bool isLoadingTabChallenges(String tab) => state.isLoadingTabChallenges(tab);
  bool hasLoadedTabChallenges(String tab) => state.hasLoadedTabChallenges(tab);
  String? getTabChallengesError(String tab) => state.getTabChallengesError(tab);
  bool isLoadingCategoryChallenges(String categoryId) =>
      state.isLoadingCategoryChallenges(categoryId);
  bool hasLoadedCategoryChallenges(String categoryId) =>
      state.hasLoadedCategoryChallenges(categoryId);
  String? getCategoryChallengesError(String categoryId) =>
      state.getCategoryChallengesError(categoryId);
  bool isJoiningChallenge(String challengeId) =>
      state.isJoiningChallenge(challengeId);

  List<Map<String, dynamic>> getChallengesForCategory(
    String categoryId, {
    String? query,
  }) =>
      state.getChallengesForCategory(categoryId, query: query);

  List<Map<String, dynamic>> getChallengesForTab(
    String tab, {
    String? categoryId,
    String? query,
  }) =>
      state.getChallengesForTab(tab, categoryId: categoryId, query: query);

  Map<String, dynamic>? getChallengeById(String id) => state.getChallengeById(id);

  void _onAuthStateChanged(AuthState authState) {
    final newToken = authState.sessionToken;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        _lastSessionToken != newToken) {
      _lastSessionToken = newToken;
      emit(ChallengesState(
        categoryQuery: state.categoryQuery,
        challengeQuery: state.challengeQuery,
        selectedCategoryId: state.selectedCategoryId,
      ));
      loadTabChallenges('ACTIVE', forceRefresh: true);
    }
  }

  Future<void> loadCategories({
    String? query,
    bool forceRefresh = false,
  }) async {
    if (state.isLoadingCategories) return;
    if (state.hasLoadedCategories && !forceRefresh && query == null) return;

    final effectiveQuery = query ?? state.categoryQuery;

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    emit(state.copyWith(
      isLoadingCategories: true,
      categoryQuery: effectiveQuery,
      clearCategoryError: true,
    ));

    try {
      final response = await _categoriesRepository.getCategories(
        query: effectiveQuery,
        sessionToken: token,
        refreshToken: refresh,
      );
      emit(state.copyWith(
        categoriesResponse: response,
        isLoadingCategories: false,
        hasLoadedCategories: true,
        clearCategoryError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCategories: false,
        hasLoadedCategories: true,
        categoriesErrorMessage: e.toString(),
      ));
    }
  }

  Future<List<ChallengeDetailData>> loadTabChallenges(
    String tab, {
    bool forceRefresh = false,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final normTab = tab.toUpperCase();
    final effectiveQuery = query ?? state.challengeQuery;

    if (!forceRefresh &&
        state.tabChallenges.containsKey(normTab) &&
        effectiveQuery.isEmpty) {
      return state.tabChallenges[normTab]!;
    }
    if (state.loadingTabChallenges[normTab] == true) {
      return state.tabChallenges[normTab] ?? const [];
    }

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final updatedLoading = Map<String, bool>.from(state.loadingTabChallenges);
    updatedLoading[normTab] = true;
    final updatedErrors = Map<String, String>.from(state.errorTabChallenges);
    updatedErrors.remove(normTab);

    emit(state.copyWith(
      loadingTabChallenges: updatedLoading,
      errorTabChallenges: updatedErrors,
    ));

    try {
      final response = await _challengesRepository.getChallenges(
        tab: normTab,
        page: page,
        limit: limit,
        query: effectiveQuery.isNotEmpty ? effectiveQuery : null,
        sessionToken: token,
        refreshToken: refresh,
      );

      final updatedTabChallenges =
          Map<String, List<ChallengeDetailData>>.from(state.tabChallenges);
      updatedTabChallenges[normTab] = response.data;

      final updatedDetails =
          Map<String, ChallengeDetailData>.from(state.challengeDetails);
      for (final challenge in response.data) {
        updatedDetails[challenge.id] = challenge;
      }

      final updatedHasLoaded =
          Map<String, bool>.from(state.loadedTabChallenges);
      updatedHasLoaded[normTab] = true;

      final loadingDone = Map<String, bool>.from(state.loadingTabChallenges);
      loadingDone[normTab] = false;

      emit(state.copyWith(
        tabChallenges: updatedTabChallenges,
        challengeDetails: updatedDetails,
        loadedTabChallenges: updatedHasLoaded,
        loadingTabChallenges: loadingDone,
      ));

      return response.data;
    } catch (e) {
      final updatedErrorsCatch =
          Map<String, String>.from(state.errorTabChallenges);
      updatedErrorsCatch[normTab] = e.toString();

      final loadingDone = Map<String, bool>.from(state.loadingTabChallenges);
      loadingDone[normTab] = false;

      final updatedHasLoaded =
          Map<String, bool>.from(state.loadedTabChallenges);
      updatedHasLoaded[normTab] = true;

      emit(state.copyWith(
        errorTabChallenges: updatedErrorsCatch,
        loadingTabChallenges: loadingDone,
        loadedTabChallenges: updatedHasLoaded,
      ));
      return state.tabChallenges[normTab] ?? const [];
    }
  }

  Future<List<ChallengeDetailData>> loadChallengesByCategory(
    String categoryId, {
    bool forceRefresh = false,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    if (categoryId.isEmpty) return const [];
    final effectiveQuery = query ?? state.challengeQuery;

    if (!forceRefresh &&
        state.categoryChallenges.containsKey(categoryId) &&
        effectiveQuery.isEmpty) {
      return state.categoryChallenges[categoryId]!;
    }
    if (state.loadingCategoryChallenges[categoryId] == true) {
      return state.categoryChallenges[categoryId] ?? const [];
    }

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final updatedLoading =
        Map<String, bool>.from(state.loadingCategoryChallenges);
    updatedLoading[categoryId] = true;
    final updatedErrors =
        Map<String, String>.from(state.errorCategoryChallenges);
    updatedErrors.remove(categoryId);

    emit(state.copyWith(
      loadingCategoryChallenges: updatedLoading,
      errorCategoryChallenges: updatedErrors,
    ));

    try {
      final response = await _challengesRepository.getChallenges(
        categoryId: categoryId,
        page: page,
        limit: limit,
        query: effectiveQuery.isNotEmpty ? effectiveQuery : null,
        sessionToken: token,
        refreshToken: refresh,
      );

      final updatedCategoryChallenges =
          Map<String, List<ChallengeDetailData>>.from(state.categoryChallenges);
      updatedCategoryChallenges[categoryId] = response.data;

      final updatedDetails =
          Map<String, ChallengeDetailData>.from(state.challengeDetails);
      for (final challenge in response.data) {
        updatedDetails[challenge.id] = challenge;
      }

      final updatedHasLoaded =
          Map<String, bool>.from(state.loadedCategoryChallenges);
      updatedHasLoaded[categoryId] = true;

      final loadingDone =
          Map<String, bool>.from(state.loadingCategoryChallenges);
      loadingDone[categoryId] = false;

      emit(state.copyWith(
        categoryChallenges: updatedCategoryChallenges,
        challengeDetails: updatedDetails,
        loadedCategoryChallenges: updatedHasLoaded,
        loadingCategoryChallenges: loadingDone,
      ));

      return response.data;
    } catch (e) {
      final updatedErrorsCatch =
          Map<String, String>.from(state.errorCategoryChallenges);
      updatedErrorsCatch[categoryId] = e.toString();

      final loadingDone =
          Map<String, bool>.from(state.loadingCategoryChallenges);
      loadingDone[categoryId] = false;

      final updatedHasLoaded =
          Map<String, bool>.from(state.loadedCategoryChallenges);
      updatedHasLoaded[categoryId] = true;

      emit(state.copyWith(
        errorCategoryChallenges: updatedErrorsCatch,
        loadingCategoryChallenges: loadingDone,
        loadedCategoryChallenges: updatedHasLoaded,
      ));

      return state.categoryChallenges[categoryId] ?? const [];
    }
  }

  Future<ChallengeDetailData?> loadChallengeDetail(
    String challengeId, {
    bool forceRefresh = false,
  }) async {
    if (challengeId.isEmpty) return null;
    if (!forceRefresh && state.challengeDetails.containsKey(challengeId)) {
      return state.challengeDetails[challengeId];
    }
    if (state.loadingChallengeDetails[challengeId] == true) {
      return state.challengeDetails[challengeId];
    }

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final updatedLoading = Map<String, bool>.from(state.loadingChallengeDetails);
    updatedLoading[challengeId] = true;
    final updatedErrors = Map<String, String>.from(state.errorChallengeDetails);
    updatedErrors.remove(challengeId);

    emit(state.copyWith(
      loadingChallengeDetails: updatedLoading,
      errorChallengeDetails: updatedErrors,
    ));

    try {
      final response = await _challengesRepository.getChallengeDetail(
        challengeId: challengeId,
        sessionToken: token,
        refreshToken: refresh,
      );

      final updatedDetails =
          Map<String, ChallengeDetailData>.from(state.challengeDetails);
      if (response.data != null) {
        updatedDetails[challengeId] = response.data!;
      }

      final loadingDone =
          Map<String, bool>.from(state.loadingChallengeDetails);
      loadingDone[challengeId] = false;

      emit(state.copyWith(
        challengeDetails: updatedDetails,
        loadingChallengeDetails: loadingDone,
      ));

      return response.data;
    } catch (e) {
      final updatedErrorsCatch =
          Map<String, String>.from(state.errorChallengeDetails);
      updatedErrorsCatch[challengeId] = e.toString();

      final loadingDone =
          Map<String, bool>.from(state.loadingChallengeDetails);
      loadingDone[challengeId] = false;

      emit(state.copyWith(
        errorChallengeDetails: updatedErrorsCatch,
        loadingChallengeDetails: loadingDone,
      ));
      return null;
    }
  }

  void setCategoryQuery(String query) {
    emit(state.copyWith(categoryQuery: query));
    loadCategories(query: query, forceRefresh: true);
  }

  void setChallengeQuery(String query, {String? tab, String? categoryId}) {
    emit(state.copyWith(challengeQuery: query));
    if (categoryId != null && categoryId.isNotEmpty) {
      loadChallengesByCategory(categoryId, query: query, forceRefresh: true);
    } else {
      final targetTab = tab ?? 'ACTIVE';
      loadTabChallenges(targetTab, query: query, forceRefresh: true);
    }
  }

  void selectCategory(String? id) {
    emit(state.copyWith(selectedCategoryId: id));
  }

  Future<JoinChallengeResponse> joinChallenge(String challengeId) async {
    if (challengeId.isEmpty) {
      return const JoinChallengeResponse(
        success: false,
        message: 'Invalid challenge ID',
      );
    }

    final token = _authCubit?.sessionToken;
    final refresh = _authCubit?.refreshToken;

    final updatedJoining = Map<String, bool>.from(state.joiningChallenges);
    updatedJoining[challengeId] = true;
    emit(state.copyWith(joiningChallenges: updatedJoining));

    try {
      final response = await _challengesRepository.joinChallenge(
        challengeId: challengeId,
        sessionToken: token,
        refreshToken: refresh,
      );
      if (response.success) {
        final challenge = getChallengeById(challengeId);
        if (challenge != null) {
          final count = (challenge['participants'] as int? ?? 0) + 1;
          challenge['participants'] = count;
          challenge['joined'] = true;
        }
      }
      return response;
    } catch (e) {
      return JoinChallengeResponse(
        success: false,
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      final updatedJoiningDone =
          Map<String, bool>.from(state.joiningChallenges);
      updatedJoiningDone[challengeId] = false;
      emit(state.copyWith(joiningChallenges: updatedJoiningDone));
    }
  }

  void submitEntry({
    required String challengeId,
    required String title,
    required String description,
    required String category,
    required List<String> hashtags,
  }) {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      final count = (challenge['participants'] as int? ?? 0) + 1;
      challenge['participants'] = count;
      emit(state.copyWith());
    }
  }

  void updateAuth(AuthCubit authCubit) {
    final oldToken = _lastSessionToken;
    final newToken = authCubit.sessionToken;
    _authCubit = authCubit;
    if (newToken != null &&
        newToken.isNotEmpty &&
        newToken != 'design_preview' &&
        oldToken != newToken) {
      _lastSessionToken = newToken;
      emit(ChallengesState(
        categoryQuery: state.categoryQuery,
        challengeQuery: state.challengeQuery,
        selectedCategoryId: state.selectedCategoryId,
      ));
      loadTabChallenges('ACTIVE', forceRefresh: true);
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
