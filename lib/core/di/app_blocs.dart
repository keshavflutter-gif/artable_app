import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:artable_app/features/trending/presentation/bloc/trending_videos_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/achievements_cubit.dart';
import 'package:artable_app/features/reels/presentation/bloc/reels_cubit.dart';
import 'package:artable_app/features/rewards/presentation/bloc/rewards_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:artable_app/features/winners/presentation/bloc/winners_cubit.dart';

class AppBlocs {
  AppBlocs._();

  static List<BlocProvider> get providers => [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<AchievementsCubit>(
          create: (context) => AchievementsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<StatsCubit>(
          create: (context) => StatsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<ReelsCubit>(
          create: (context) => ReelsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<MyVideosCubit>(
          create: (context) => MyVideosCubit(
            authCubit: context.read<AuthCubit>(),
            reelsCubit: context.read<ReelsCubit>(),
          ),
        ),
        BlocProvider<ChallengesCubit>(
          create: (context) => ChallengesCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<RewardsCubit>(
          create: (context) => RewardsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<StudioCubit>(
          create: (_) => StudioCubit(),
        ),
        BlocProvider<TrendingVideosCubit>(
          create: (context) => TrendingVideosCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<LeaderboardCubit>(
          create: (context) => LeaderboardCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider<WinnersCubit>(
          create: (context) => WinnersCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ];
}

