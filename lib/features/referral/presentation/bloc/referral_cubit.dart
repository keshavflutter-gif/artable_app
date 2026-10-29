import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/referral/data/models/referral_models.dart';
import 'package:artable_app/features/referral/data/repositories/referral_repository.dart';
import 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit({
    AuthCubit? authCubit,
    ReferralRepository? repository,
  })  : _authCubit = authCubit,
        _repository = repository ??
            ReferralRepository(
              onTokensRefreshed: authCubit?.applyRefreshedTokens,
              onSessionRefreshFailed: authCubit?.handleSessionRefreshFailed,
            ),
        super(const ReferralState());

  final AuthCubit? _authCubit;
  final ReferralRepository _repository;

  String? get _sessionToken {
    final token = _authCubit?.sessionToken;
    if (token == null || token.isEmpty || token == 'design_preview') return null;
    return token;
  }

  String? get _refreshToken {
    final token = _authCubit?.refreshToken;
    if (token == null || token.isEmpty || token == 'design_preview') return null;
    return token;
  }

  Future<void> loadInvite({bool forceRefresh = false}) async {
    if (state.isInviteLoading) return;
    if (state.hasInviteLoaded && !forceRefresh) return;

    emit(state.copyWith(isInviteLoading: true, clearInviteError: true));
    try {
      final res = await _repository.getInvite(
        sessionToken: _sessionToken,
        refreshToken: _refreshToken,
      );
      emit(state.copyWith(
        isInviteLoading: false,
        hasInviteLoaded: true,
        invite: res.data,
        inviteError: res.success ? null : (res.message ?? 'Failed to load invite'),
        clearInviteError: res.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInviteLoading: false,
        hasInviteLoaded: true,
        inviteError: e.toString(),
      ));
    }
  }

  Future<void> loadTracking({bool forceRefresh = false}) async {
    if (state.isTrackingLoading) return;
    if (state.hasTrackingLoaded && !forceRefresh) return;

    emit(state.copyWith(isTrackingLoading: true, clearTrackingError: true));
    try {
      final res = await _repository.getTracking(
        sessionToken: _sessionToken,
        refreshToken: _refreshToken,
      );
      emit(state.copyWith(
        isTrackingLoading: false,
        hasTrackingLoaded: true,
        tracking: res.data,
        trackingError: res.success ? null : (res.message ?? 'Failed to load tracking'),
        clearTrackingError: res.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTrackingLoading: false,
        hasTrackingLoaded: true,
        trackingError: e.toString(),
      ));
    }
  }

  Future<ApplyReferralResponse> applyReferralCode(String referralCode) async {
    final code = referralCode.trim();
    if (code.isEmpty) {
      const empty = ApplyReferralResponse(
        success: false,
        message: 'Referral code is required',
      );
      emit(state.copyWith(
        applySuccess: false,
        applyMessage: empty.message,
      ));
      return empty;
    }
    if (state.isApplying) {
      return ApplyReferralResponse(
        success: false,
        message: state.applyMessage ?? 'Please wait',
      );
    }

    emit(state.copyWith(
      isApplying: true,
      clearApplyMessage: true,
      clearApplySuccess: true,
    ));
    try {
      final res = await _repository.applyReferral(
        referralCode: code,
        sessionToken: _sessionToken,
        refreshToken: _refreshToken,
      );
      emit(state.copyWith(
        isApplying: false,
        applySuccess: res.success,
        applyMessage: res.message,
      ));
      if (res.success) {
        await loadTracking(forceRefresh: true);
      }
      return res;
    } catch (e) {
      final failed = ApplyReferralResponse(success: false, message: e.toString());
      emit(state.copyWith(
        isApplying: false,
        applySuccess: false,
        applyMessage: failed.message,
      ));
      return failed;
    }
  }
}
