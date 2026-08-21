import 'package:go_router/go_router.dart';

import 'package:artable_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/login_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:artable_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:artable_app/features/bonus/presentation/screens/daily_bonus_screen.dart';
import 'package:artable_app/features/challenges/presentation/screens/categories_screen.dart';
import 'package:artable_app/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:artable_app/features/membership/presentation/screens/membership_plan_screen.dart';
import 'package:artable_app/features/music/presentation/screens/music_library_screen.dart';
import 'package:artable_app/features/music/presentation/screens/music_preview_screen.dart';
import 'package:artable_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/achievements_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/my_videos_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:artable_app/features/profile/presentation/screens/talent_score_screen.dart';
import 'package:artable_app/features/reels/presentation/screens/comments_screen.dart';
import 'package:artable_app/features/reels/presentation/screens/reels_feed_screen.dart';
import 'package:artable_app/features/reels/presentation/screens/share_report_screen.dart';
import 'package:artable_app/features/reels/presentation/screens/talent_rating_screen.dart';
import 'package:artable_app/features/reels/presentation/screens/video_detail_screen.dart';
import 'package:artable_app/features/referral/presentation/screens/invite_friends_screen.dart';
import 'package:artable_app/features/rewards/presentation/screens/cash_rewards_screen.dart';
import 'package:artable_app/features/rewards/presentation/screens/reward_detail_screen.dart';
import 'package:artable_app/features/rewards/presentation/screens/rewards_screen.dart';
import 'package:artable_app/features/rewards/presentation/screens/voucher_rewards_screen.dart';
import 'package:artable_app/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:artable_app/features/trending/presentation/screens/search_results_screen.dart';
import 'package:artable_app/features/trending/presentation/screens/search_screen.dart';
import 'package:artable_app/features/trending/presentation/screens/trending_videos_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/help_support_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/logout_delete_confirm_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/terms_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/change_password_screen.dart';
import 'package:artable_app/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_camera_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_details_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_drafts_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_filters_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_music_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_preview_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_start_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_success_screen.dart';
import 'package:artable_app/features/studio/presentation/screens/studio_upload_screen.dart';
import 'package:artable_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:artable_app/features/wallet/presentation/screens/withdrawal_request_screen.dart';
import 'package:artable_app/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:artable_app/features/winners/presentation/screens/winners_screen.dart';
import 'package:artable_app/features/winners/presentation/screens/winner_detail_screen.dart';
import 'package:artable_app/features/winners/presentation/screens/prize_tracking_screen.dart';
import 'package:artable_app/features/shell/presentation/screens/main_tab_shell.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) {
            final extraMap = state.extra is Map ? (state.extra as Map) : null;
            final email = state.uri.queryParameters['email'] ??
                extraMap?['email']?.toString();
            final password = state.uri.queryParameters['password'] ??
                extraMap?['password']?.toString();
            return LoginScreen(
              initialEmail: email,
              initialPassword: password,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.otpVerification,
          builder: (context, state) {
            final from = state.uri.queryParameters['from'] ?? 'signup';
            final destination =
                state.uri.queryParameters['destination'] ?? '+1 •••• •• 123';
            final extraMap = state.extra is Map ? (state.extra as Map) : null;
            final verifyId = state.uri.queryParameters['verifyId'] ??
                extraMap?['verifyId']?.toString() ??
                '';
            final userId = state.uri.queryParameters['userId'] ??
                extraMap?['userId']?.toString() ??
                '';
            final channel = state.uri.queryParameters['channel'] ??
                extraMap?['channel']?.toString() ??
                'EMAIL';
            final email = state.uri.queryParameters['email'] ??
                extraMap?['email']?.toString();
            final password = state.uri.queryParameters['password'] ??
                extraMap?['password']?.toString();

            return OtpVerificationScreen(
              from: from,
              destination: destination,
              verifyId: verifyId,
              userId: userId,
              channel: channel,
              email: email,
              password: password,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) {
            final extraMap = state.extra is Map ? (state.extra as Map) : null;
            final email = state.uri.queryParameters['email'] ??
                extraMap?['email']?.toString();
            final token = state.uri.queryParameters['token'] ??
                state.uri.queryParameters['resetToken'] ??
                extraMap?['token']?.toString() ??
                extraMap?['resetToken']?.toString();
            return ResetPasswordScreen(
              email: email,
              token: token,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const MainTabShell(initialIndex: 0),
        ),
        GoRoute(
          path: AppRoutes.challenges,
          builder: (context, state) {
            final categoryId = state.uri.queryParameters['categoryId'] ??
                state.uri.queryParameters['category'];
            final tab = state.uri.queryParameters['tab'];
            return MainTabShell(
              initialIndex: 1,
              categoryFilter: categoryId,
              initialChallengesTab: tab ?? 'active',
            );
          },
        ),
        GoRoute(
          path: AppRoutes.categories,
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: AppRoutes.submitEntry,
          builder: (context, state) => MainTabShell(
            initialIndex: 2,
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.challengeDetail,
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? 'c1';
            return ChallengeDetailScreen(challengeId: id);
          },
        ),
        GoRoute(
          path: AppRoutes.studioStart,
          builder: (context, state) => StudioStartScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioDrafts,
          builder: (context, state) => StudioDraftsScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioCamera,
          builder: (context, state) => StudioCameraScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioMusic,
          builder: (context, state) => StudioMusicScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioFilters,
          builder: (context, state) => StudioFiltersScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioPreview,
          builder: (context, state) => StudioPreviewScreen(
            challengeId: state.uri.queryParameters['id'],
            draftId: state.uri.queryParameters['draft'],
            videoPath: state.uri.queryParameters['videoPath'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioDetails,
          builder: (context, state) => StudioDetailsScreen(
            challengeId: state.uri.queryParameters['id'],
            draftId: state.uri.queryParameters['draft'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioUpload,
          builder: (context, state) => StudioUploadScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.studioSuccess,
          builder: (context, state) => StudioSuccessScreen(
            challengeId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.reelsFeed,
          builder: (context, state) => const ReelsFeedScreen(),
        ),
        GoRoute(
          path: AppRoutes.talentRating,
          builder: (context, state) => TalentRatingScreen(
            reelId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.videoDetail,
          builder: (context, state) => VideoDetailScreen(
            reelId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.comments,
          builder: (context, state) => CommentsScreen(
            reelId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.shareReport,
          builder: (context, state) => ShareReportScreen(
            reelId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: AppRoutes.searchResults,
          builder: (context, state) => SearchResultsScreen(
            query: state.uri.queryParameters['q'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.trendingVideos,
          builder: (context, state) => const TrendingVideosScreen(),
        ),
        GoRoute(
          path: AppRoutes.leaderboard,
          builder: (context, state) => LeaderboardScreen(
            challengeId: state.uri.queryParameters['challengeId'],
          ),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.myProfile,
          builder: (context, state) => const MainTabShell(initialIndex: 4),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const MainTabShell(initialIndex: 4),
        ),
        GoRoute(
          path: AppRoutes.publicProfile,
          builder: (context, state) => PublicProfileScreen(
            userId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.myVideos,
          builder: (context, state) => const MyVideosScreen(),
        ),
        GoRoute(
          path: AppRoutes.achievements,
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: AppRoutes.talentScore,
          builder: (context, state) => const TalentScoreScreen(),
        ),
        GoRoute(
          path: AppRoutes.rewardDetail,
          builder: (context, state) => RewardDetailScreen(
            rewardId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.wallet,
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: AppRoutes.withdrawalRequest,
          builder: (context, state) => const WithdrawalRequestScreen(),
        ),
        GoRoute(
          path: AppRoutes.prizeTracking,
          builder: (context, state) => PrizeTrackingScreen(
            rewardId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.winners,
          builder: (context, state) => const WinnersScreen(),
        ),
        GoRoute(
          path: AppRoutes.winnerDetail,
          builder: (context, state) => WinnerDetailScreen(
            winnerId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.inviteFriends,
          builder: (context, state) => const InviteFriendsScreen(),
        ),
        GoRoute(
          path: AppRoutes.referralTracking,
          builder: (context, state) => const ReferralTrackingScreen(),
        ),
        GoRoute(
          path: AppRoutes.musicLibrary,
          builder: (context, state) => const MusicLibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.musicPreview,
          builder: (context, state) => MusicPreviewScreen(
            trackId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: AppRoutes.dailyBonus,
          builder: (context, state) => const DailyBonusScreen(),
        ),
        GoRoute(
          path: AppRoutes.rewardCalendar,
          builder: (context, state) => const RewardCalendarScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscriptionSuccess,
          builder: (context, state) => const SubscriptionSuccessScreen(),
        ),
        GoRoute(
          path: AppRoutes.activityCenter,
          builder: (context, state) => const MainTabShell(initialIndex: 3),
        ),
        GoRoute(
          path: AppRoutes.membershipPlan,
          builder: (context, state) => const MembershipPlanScreen(),
        ),
        GoRoute(
          path: AppRoutes.primePayment,
          builder: (context, state) => const PrimePaymentScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacySettings,
          builder: (context, state) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.terms,
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacyPolicy,
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: AppRoutes.helpSupport,
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: AppRoutes.logoutDeleteConfirm,
          builder: (context, state) => LogoutDeleteConfirmScreen(
            mode: state.uri.queryParameters['mode'] ?? 'logout',
          ),
        ),
        GoRoute(
          path: AppRoutes.transactionHistory,
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.rewards,
          builder: (context, state) => const RewardsScreen(),
        ),
        GoRoute(
          path: AppRoutes.cashRewards,
          builder: (context, state) => const CashRewardsScreen(),
        ),
        GoRoute(
          path: AppRoutes.voucherRewards,
          builder: (context, state) => const VoucherRewardsScreen(),
        ),
        GoRoute(
          path: AppRoutes.productRewards,
          builder: (context, state) => const ProductRewardsScreen(),
        ),
        GoRoute(
          path: AppRoutes.sponsorRewards,
          builder: (context, state) => const SponsorRewardsScreen(),
        ),
      ],
    );
  }
}
/// Back-compat alias used by [ArtableApp] in `lib/app.dart`.
final GoRouter appRouter = AppRouter.create();

