import 'dart:convert';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:artable_app/features/home/data/models/home_dashboard_response.dart';
import 'package:artable_app/features/home/data/models/home_ui_mapper.dart';
import 'package:artable_app/features/home/data/repositories/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Home Dashboard API & Repository Tests', () {
    const mockApiResponse = {
      "success": true,
      "message": "Successfully",
      "data": {
        "banners": [
          {
            "id": "cmssiziau0012afkmr3uv1ona",
            "title": "ONLY YOUR TALENT WINS!",
            "imageUrl":
                "https://placehold.co/600x400/EEE/31343C?font=raleway&text=Raleway",
            "linkUrl": "https://google.com",
            "placement": "HOME",
            "startsAt": "2026-08-03T18:30:00.000Z",
            "endsAt": "2026-08-26T18:29:59.999Z",
            "isActive": true,
            "createdAt": "2026-08-14T05:47:38.214Z",
            "updatedAt": "2026-08-14T06:27:43.857Z"
          }
        ],
        "featuredChallenges": [
          {
            "id": "cmssjscj2000sq1h8qdsicupj",
            "title": "Monthly Mega Dance Battle",
            "rules": [],
            "prizeBreakdown": [],
            "prizePoolLabel": "",
            "bannerUrl":
                "https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg",
            "categoryName": null,
            "startDate": "2026-08-08T18:30:00.000Z",
            "endDate": "2026-08-29T18:29:59.999Z",
            "endDateLabel": "Aug 29, 2026",
            "daysLeft": 16,
            "daysLeftLabel": "16 days left",
            "joinedCount": 0,
            "joinedLabel": "0 joined",
            "approvedVideosCount": 0,
            "averageRating": 0
          }
        ],
        "trendingVideos": [
          {
            "id": "cmssl4xnv0003ead21lsgh07x",
            "views": 0,
            "shares": 0,
            "title": "My singing entry",
            "thumbnailUrl": "https://storage.example/thumb.jpg",
            "categoryId": null,
            "user": {
              "id": "cmsr6ar5c00002nh51l0he489",
              "fullName": "Demo User1",
              "username": "demouser7314",
              "profilePhotoUrl": null,
              "badges": []
            },
            "category": null
          }
        ],
        "categories": [
          {
            "id": "cmssjtraw000tq1h82oan31my",
            "name": "Dance",
            "description": null,
            "imageUrl":
                "https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg",
            "isActive": true,
            "createdAt": "2026-08-14T06:11:09.560Z",
            "updatedAt": "2026-08-14T06:11:09.560Z"
          }
        ]
      }
    };

    test('1. HomeDashboardResponse fromJson parses all nested sections correctly', () {
      final response = HomeDashboardResponse.fromJson(mockApiResponse);

      expect(response.success, isTrue);
      expect(response.message, 'Successfully');
      expect(response.data.banners.length, 1);
      expect(response.data.banners.first.id, 'cmssiziau0012afkmr3uv1ona');
      expect(response.data.banners.first.title, 'ONLY YOUR TALENT WINS!');

      expect(response.data.featuredChallenges.length, 1);
      expect(response.data.featuredChallenges.first['title'],
          'Monthly Mega Dance Battle');
      expect(response.data.featuredChallenges.first['daysLeftLabel'],
          '16 days left');

      expect(response.data.trendingVideos.length, 1);
      expect(response.data.trendingVideos.first['title'], 'My singing entry');

      expect(response.data.categories.length, 1);
      expect(response.data.categories.first['name'], 'Dance');
    });

    test('2. HomeUiMapper correctly maps real API payload to UI maps', () {
      final response = HomeDashboardResponse.fromJson(mockApiResponse);

      // Banner mapping
      final megaPromo =
          HomeUiMapper.bannerToMegaPromo(response.data.banners.first);
      expect(megaPromo['title'], 'ONLY YOUR TALENT WINS!');
      expect(megaPromo['id'], 'cmssiziau0012afkmr3uv1ona');

      // Featured Challenge mapping
      final challenge = HomeUiMapper.featuredChallengeToUiMap(
          response.data.featuredChallenges.first);
      expect(challenge['id'], 'cmssjscj2000sq1h8qdsicupj');
      expect(challenge['title'], 'Monthly Mega Dance Battle');
      expect(challenge['timeLeft'], '16 days left');
      expect(challenge['imageUrl'],
          'https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg');

      // Trending Video mapping
      final video = HomeUiMapper.trendingVideoToUiMap(
          response.data.trendingVideos.first);
      expect(video['id'], 'cmssl4xnv0003ead21lsgh07x');
      expect(video['title'], 'My singing entry');
      expect(video['imageUrl'], 'https://storage.example/thumb.jpg');
      expect(video['handle'], '@demouser7314');
      expect(video['creator'], 'Demo User1');
    });

    test('3. HomeRepository calls GET /app/home with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/home',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_home_123');
        expect(request.headers['Refresh-Token'], 'refresh_home_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = HomeRepository(apiClient: apiClient);

      final result = await repo.getHomeDashboard(
        sessionToken: 'session_home_123',
        refreshToken: 'refresh_home_456',
      );

      expect(result.success, isTrue);
      expect(result.data.banners.length, 1);
      expect(result.data.featuredChallenges.length, 1);
      expect(result.data.trendingVideos.length, 1);
      expect(result.data.categories.length, 1);
    });

    test('4. HomeCubit loads home dashboard data and exposes getters', () async {
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
      final repo = HomeRepository(apiClient: apiClient);
      final cubit = HomeCubit(
        authCubit: authCubit,
        homeRepository: repo,
      );

      expect(cubit.hasLoaded, isFalse);
      await cubit.loadHomeDashboard();

      expect(cubit.hasLoaded, isTrue);
      expect(cubit.isLoading, isFalse);
      expect(cubit.megaPromoBanners.first['title'], 'ONLY YOUR TALENT WINS!');
      expect(cubit.activeChallenges.first['title'], 'Monthly Mega Dance Battle');
      expect(cubit.trendingReels.first['title'], 'My singing entry');
      expect(cubit.categories.first['name'], 'Dance');
    });
  });
}
