import 'dart:convert';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:artable_app/features/profile/data/models/profile_stats_response.dart';
import 'package:artable_app/features/profile/data/repositories/stats_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Stats API & Repository Tests', () {
    const mockApiResponse = {
      "success": true,
      "message": "Successfully",
      "data": {
        "overallTalentScore": 0,
        "overallTalentScoreLabel": "0.0",
        "avgRating": 0,
        "avgRatingLabel": "0.0",
        "totalVotes": 0,
        "totalVotesLabel": "0",
        "ratingTrend": "NO_RECENT_RATINGS",
        "winRate": 0,
        "heroMetrics": [],
        "statTiles": [],
        "stats": {
          "totalVideos": 0,
          "approvedVideos": 0,
          "totalLikes": 0,
          "totalViews": 0,
          "talentScore": 0,
          "wins": 0,
          "joinedChallenges": 0,
          "topThree": 0,
          "rewardEarnings": 0,
          "referrals": 0,
          "maxVideoLikes": 0,
          "maxRatingCount": 0
        },
        "ratingBreakdown": [
          {
            "score": 1,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 2,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 3,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 4,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 5,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 6,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 7,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 8,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 9,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          },
          {
            "score": 10,
            "count": 0,
            "percent": 0,
            "barPercent": 0
          }
        ],
        "recentChallengePerformance": [],
        "note": null,
        "screenConfig": {}
      }
    };

    test('1. ProfileStatsResponse fromJson parses all nested fields correctly', () {
      final response = ProfileStatsResponse.fromJson(mockApiResponse);

      expect(response.success, isTrue);
      expect(response.message, 'Successfully');
      expect(response.data.overallTalentScore, 0);
      expect(response.data.overallTalentScoreLabel, '0.0');
      expect(response.data.avgRating, 0);
      expect(response.data.avgRatingLabel, '0.0');
      expect(response.data.totalVotes, 0);
      expect(response.data.totalVotesLabel, '0');
      expect(response.data.ratingTrend, 'NO_RECENT_RATINGS');
      expect(response.data.winRate, 0);

      // stats checks
      expect(response.data.stats.totalVideos, 0);
      expect(response.data.stats.approvedVideos, 0);
      expect(response.data.stats.totalLikes, 0);
      expect(response.data.stats.totalViews, 0);
      expect(response.data.stats.wins, 0);
      expect(response.data.stats.rewardEarnings, 0);

      // ratingBreakdown checks
      expect(response.data.ratingBreakdown.length, 10);
      expect(response.data.ratingBreakdown.first.score, 1);
      expect(response.data.ratingBreakdown.last.score, 10);
    });

    test('2. StatsRepository calls GET /app/profile/stats with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/profile/stats',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_stats_123');
        expect(request.headers['Refresh-Token'], 'refresh_stats_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = StatsRepository(apiClient: apiClient);

      final result = await repo.getProfileStats(
        sessionToken: 'session_stats_123',
        refreshToken: 'refresh_stats_456',
      );

      expect(result.success, isTrue);
      expect(result.data.ratingTrend, 'NO_RECENT_RATINGS');
      expect(result.data.ratingBreakdown.length, 10);
    });

    test('3. StatsCubit loads stats and manages state correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authCubit = AuthCubit();
      authCubit.applyRefreshedTokens(
        sessionToken: 'session_test',
        refreshToken: 'refresh_test',
      );

      final apiClient = ApiClient(client: mockClient);
      final repo = StatsRepository(apiClient: apiClient);
      final cubit = StatsCubit(
        authCubit: authCubit,
        statsRepository: repo,
      );

      expect(cubit.hasLoaded, isFalse);
      await cubit.loadStats();

      expect(cubit.hasLoaded, isTrue);
      expect(cubit.isLoading, isFalse);
      expect(cubit.data, isNotNull);
      expect(cubit.data!.ratingBreakdown.length, 10);
    });
  });
}
