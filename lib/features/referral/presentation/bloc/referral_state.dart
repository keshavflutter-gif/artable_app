import 'package:artable_app/features/referral/data/models/referral_models.dart';

class ReferralState {
  const ReferralState({
    this.isInviteLoading = false,
    this.hasInviteLoaded = false,
    this.inviteError,
    this.invite,
    this.isTrackingLoading = false,
    this.hasTrackingLoaded = false,
    this.trackingError,
    this.tracking,
    this.isApplying = false,
    this.applyMessage,
    this.applySuccess,
  });

  final bool isInviteLoading;
  final bool hasInviteLoaded;
  final String? inviteError;
  final ReferralInviteData? invite;

  final bool isTrackingLoading;
  final bool hasTrackingLoaded;
  final String? trackingError;
  final ReferralTrackingData? tracking;

  final bool isApplying;
  final String? applyMessage;
  final bool? applySuccess;

  ReferralState copyWith({
    bool? isInviteLoading,
    bool? hasInviteLoaded,
    String? inviteError,
    bool clearInviteError = false,
    ReferralInviteData? invite,
    bool? isTrackingLoading,
    bool? hasTrackingLoaded,
    String? trackingError,
    bool clearTrackingError = false,
    ReferralTrackingData? tracking,
    bool? isApplying,
    String? applyMessage,
    bool clearApplyMessage = false,
    bool? applySuccess,
    bool clearApplySuccess = false,
  }) {
    return ReferralState(
      isInviteLoading: isInviteLoading ?? this.isInviteLoading,
      hasInviteLoaded: hasInviteLoaded ?? this.hasInviteLoaded,
      inviteError: clearInviteError ? null : (inviteError ?? this.inviteError),
      invite: invite ?? this.invite,
      isTrackingLoading: isTrackingLoading ?? this.isTrackingLoading,
      hasTrackingLoaded: hasTrackingLoaded ?? this.hasTrackingLoaded,
      trackingError: clearTrackingError ? null : (trackingError ?? this.trackingError),
      tracking: tracking ?? this.tracking,
      isApplying: isApplying ?? this.isApplying,
      applyMessage: clearApplyMessage ? null : (applyMessage ?? this.applyMessage),
      applySuccess: clearApplySuccess ? null : (applySuccess ?? this.applySuccess),
    );
  }
}
