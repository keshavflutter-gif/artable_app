import 'dart:convert';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/profile/presentation/bloc/achievements_cubit.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/profile/data/models/achievements_response.dart';
import 'package:artable_app/features/profile/data/repositories/achievements_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Achievements API & Repository Tests', () {
    const mockApiResponse = {
      "success": true,
      "message": "Successfully",
      "data": {
        "currentLevel": "Starter",
        "earnedCount": 0,
        "totalCount": 1,
        "earnedLabel": "0/1",
        "nextMilestone": "TEt",
        "levelCard": {
          "title": "Current Level",
          "value": "Starter",
          "earnedLabel": "0/1",
          "earnedText": "Badges Earned",
          "nextMilestone": "TEt",
          "nextMilestoneText": "Next Milestone"
        },
        "groups": [
          {
            "title": "Group",
            "items": [
              {
                "key": "cmsr80t1h0004arpbs2w3xk7w",
                "title": "TEt",
                "description": "",
                "icon": "lock",
                "imageUrl": null,
                "unlocked": false,
                "locked": true,
                "progress": 0,
                "target": 1,
                "progressPercent": 0,
                "awardedAt": null
              }
            ]
          }
        ],
        "awardedBadges": []
      }
    };

    test('1. AchievementsResponse fromJson parses all nested fields correctly', () {
      final response = AchievementsResponse.fromJson(mockApiResponse);

      expect(response.success, isTrue);
      expect(response.message, 'Successfully');
      expect(response.data.currentLevel, 'Starter');
      expect(response.data.earnedCount, 0);
      expect(response.data.totalCount, 1);
      expect(response.data.earnedLabel, '0/1');
      expect(response.data.nextMilestone, 'TEt');

      // levelCard checks
      expect(response.data.levelCard, isNotNull);
      expect(response.data.levelCard!.title, 'Current Level');
      expect(response.data.levelCard!.value, 'Starter');
      expect(response.data.levelCard!.earnedLabel, '0/1');
      expect(response.data.levelCard!.earnedText, 'Badges Earned');
      expect(response.data.levelCard!.nextMilestone, 'TEt');
      expect(response.data.levelCard!.nextMilestoneText, 'Next Milestone');

      // groups checks
      expect(response.data.groups.length, 1);
      final group = response.data.groups.first;
      expect(group.title, 'Group');
      expect(group.items.length, 1);

      final item = group.items.first;
      expect(item.key, 'cmsr80t1h0004arpbs2w3xk7w');
      expect(item.title, 'TEt');
      expect(item.description, '');
      expect(item.icon, 'lock');
      expect(item.imageUrl, isNull);
      expect(item.unlocked, isFalse);
      expect(item.locked, isTrue);
      expect(item.isEarned, isFalse);
      expect(item.progress, 0);
      expect(item.target, 1);
      expect(item.progressPercent, 0);
      expect(item.awardedAt, isNull);
    });

    test('2. AchievementsRepository calls GET /app/profile/achievements with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/profile/achievements',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_123');
        expect(request.headers['Refresh-Token'], 'refresh_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AchievementsRepository(apiClient: apiClient);

      final result = await repo.getAchievements(
        sessionToken: 'session_123',
        refreshToken: 'refresh_456',
      );

      expect(result.success, isTrue);
      expect(result.data.currentLevel, 'Starter');
      expect(result.data.groups.first.items.first.title, 'TEt');
    });

    test('3. AchievementsCubit loads achievements and handles state correctly', () async {
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
      final repo = AchievementsRepository(apiClient: apiClient);
      final cubit = AchievementsCubit(
        authCubit: authCubit,
        achievementsRepository: repo,
      );

      expect(cubit.hasLoaded, isFalse);
      await cubit.loadAchievements();

      expect(cubit.hasLoaded, isTrue);
      expect(cubit.isLoading, isFalse);
      expect(cubit.data, isNotNull);
      expect(cubit.data!.currentLevel, 'Starter');
      expect(cubit.data!.groups.length, 1);
    });
  });
}
