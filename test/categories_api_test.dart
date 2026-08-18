import 'dart:convert';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/challenges/data/models/categories_response.dart';
import 'package:artable_app/features/challenges/data/repositories/categories_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Categories API & Repository Tests', () {
    const mockApiResponse = {
      "success": true,
      "message": "Successfully",
      "data": [
        {
          "id": "cmssjtraw000tq1h82oan31my",
          "name": "Dance",
          "description": null,
          "imageUrl":
              "https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg",
          "isActive": true,
          "liveChallenges": 1,
          "approvedVideos": 1,
          "updatedAt": "2026-08-14T06:11:09.560Z"
        }
      ],
      "summary": {
        "totalCategories": 1,
        "activeChallenges": 1,
        "updatedFrequency": "Daily"
      }
    };

    test('1. CategoriesResponse fromJson parses data list and summary correctly', () {
      final response = CategoriesResponse.fromJson(mockApiResponse);

      expect(response.success, isTrue);
      expect(response.message, 'Successfully');
      expect(response.data.length, 1);

      final item = response.data.first;
      expect(item.id, 'cmssjtraw000tq1h82oan31my');
      expect(item.name, 'Dance');
      expect(item.description, isNull);
      expect(item.imageUrl,
          'https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg');
      expect(item.isActive, isTrue);
      expect(item.liveChallenges, 1);
      expect(item.approvedVideos, 1);
      expect(item.updatedAt, '2026-08-14T06:11:09.560Z');

      expect(response.summary, isNotNull);
      expect(response.summary!.totalCategories, 1);
      expect(response.summary!.activeChallenges, 1);
      expect(response.summary!.updatedFrequency, 'Daily');
    });

    test('2. CategoryDetailItem.toUiMap maps to UI keys properly', () {
      final response = CategoriesResponse.fromJson(mockApiResponse);
      final item = response.data.first;
      final uiMap = item.toUiMap();

      expect(uiMap['id'], 'cmssjtraw000tq1h82oan31my');
      expect(uiMap['name'], 'Dance');
      expect(uiMap['count'], 1);
      expect(uiMap['liveChallenges'], 1);
      expect(uiMap['icon'], 'dance');
      expect(uiMap['imageUrl'],
          'https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg');
    });

    test('3. CategoriesRepository calls GET /app/categories?q= with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/categories?q=dance',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_cat_123');
        expect(request.headers['Refresh-Token'], 'refresh_cat_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = CategoriesRepository(apiClient: apiClient);

      final result = await repo.getCategories(
        query: 'dance',
        sessionToken: 'session_cat_123',
        refreshToken: 'refresh_cat_456',
      );

      expect(result.success, isTrue);
      expect(result.data.length, 1);
      expect(result.summary?.totalCategories, 1);
    });

    test('4. ChallengesCubit loads categories and manages state correctly', () async {
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
      final repo = CategoriesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        categoriesRepository: repo,
      );

      expect(cubit.hasLoadedCategories, isFalse);
      await cubit.loadCategories();

      expect(cubit.hasLoadedCategories, isTrue);
      expect(cubit.isLoadingCategories, isFalse);
      expect(cubit.categories.length, 1);
      expect(cubit.categories.first['name'], 'Dance');
      expect(cubit.categorySummary?.totalCategories, 1);
      expect(cubit.categorySummary?.activeChallenges, 1);
      expect(cubit.categorySummary?.updatedFrequency, 'Daily');
    });
  });
}
