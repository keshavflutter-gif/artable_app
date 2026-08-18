import 'dart:convert';
import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/challenges/presentation/bloc/challenges_cubit.dart';
import 'package:artable_app/features/challenges/data/models/challenge_detail_response.dart';
import 'package:artable_app/features/challenges/data/repositories/challenges_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Challenge Detail & Tab List API Tests', () {
    const mockApiResponse = {
      "success": true,
      "message": "Successfully",
      "data": [
        {
          "id": "cmssjscj2000sq1h8qdsicupj",
          "title": "Monthly Mega Dance Battle",
          "description":
              "Show off your best choreography — solo or group —\nfor a shot at this month’s biggest dance prize pool.\nJudged on technique, creativity, and stage presence.",
          "rules": [
            "One entry per user for this challenge.",
            "Video must be recorded in the Artable in-app studio.",
            "Maximum entry length: 60 seconds.",
            "Content must be original choreography or a credited routine."
          ],
          "prizeBreakdown": [
            {
              "position": 1,
              "title": "1st Place",
              "prize": "2500",
              "badge": "Champion Badge"
            },
            {
              "position": 2,
              "title": "2st Place",
              "prize": "1500",
              "badge": "Rising Star Badge"
            },
            {
              "position": 3,
              "title": "3st Place",
              "prize": "100",
              "badge": "Participation Badge"
            }
          ],
          "rewardPool": "5000",
          "prizePoolLabel": r"$5,000",
          "participationFee": "0",
          "bannerUrl":
              "https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg",
          "category": {
            "id": "cmssjtraw000tq1h82oan31my",
            "name": "Dance",
            "description": null,
            "imageUrl":
                "https://plain-apac-prod-public.komododecks.com/202608/14/KaH1xskYRPv2QzQQg7nI/image.jpg",
            "isActive": true,
            "liveChallenges": 1,
            "approvedVideos": 1,
            "updatedAt": "2026-08-14T06:11:09.560Z"
          },
          "startDate": "2026-08-08T18:30:00.000Z",
          "endDate": "2026-08-29T18:29:59.999Z",
          "status": "ACTIVE",
          "isFeatured": true,
          "joinedCount": 0,
          "approvedVideosCount": 0,
          "averageRating": 0,
          "joinedLabel": "0 joined",
          "daysLeft": 16,
          "daysLeftLabel": "16 days left",
          "endDateLabel": "Aug 29, 2026",
          "joined": false
        }
      ]
    };

    test('1. ChallengeDetailItem fromJson parses full detail schema correctly', () {
      final response = ChallengeDetailResponse.fromJson(mockApiResponse);

      expect(response.success, isTrue);
      expect(response.message, 'Successfully');
      expect(response.data, isNotNull);

      final item = response.data!;
      expect(item.id, 'cmssjscj2000sq1h8qdsicupj');
      expect(item.title, 'Monthly Mega Dance Battle');
      expect(item.description, contains('Show off your best choreography'));
      expect(item.rules.length, 4);
      expect(item.rules.first, 'One entry per user for this challenge.');
      expect(item.prizeBreakdown.length, 3);
      expect(item.prizeBreakdown.first.prize, '2500');
      expect(item.prizeBreakdown.first.badge, 'Champion Badge');
      expect(item.rewardPool, '5000');
      expect(item.prizePoolLabel, r'$5,000');
      expect(item.participationFee, '0');
      expect(item.bannerUrl, contains('image.jpg'));
      expect(item.category, isNotNull);
      expect(item.category!.name, 'Dance');
      expect(item.categoryName, 'Dance');
      expect(item.status, 'ACTIVE');
      expect(item.isFeatured, isTrue);
      expect(item.joinedCount, 0);
    });

    test('2. ChallengesRepository calls GET /app/challenges/cmssjscj2000sq1h8qdsicupj with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges/cmssjscj2000sq1h8qdsicupj',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_detail_123');
        expect(request.headers['Refresh-Token'], 'refresh_detail_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);

      final result = await repo.getChallengeDetail(
        challengeId: 'cmssjscj2000sq1h8qdsicupj',
        sessionToken: 'session_detail_123',
        refreshToken: 'refresh_detail_456',
      );

      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.title, 'Monthly Mega Dance Battle');
    });

    test('3. ChallengesCubit loads and caches challenge detail', () async {
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
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      final detail = await cubit.loadChallengeDetail('cmssjscj2000sq1h8qdsicupj');

      expect(detail, isNotNull);
      expect(detail!.title, 'Monthly Mega Dance Battle');
      expect(cubit.getChallengeDetail('cmssjscj2000sq1h8qdsicupj'), isNotNull);
      expect(cubit.getChallengeById('cmssjscj2000sq1h8qdsicupj')?['title'],
          'Monthly Mega Dance Battle');
    });

    test('4. ChallengesRepository calls GET /app/challenges?tab=ACTIVE&page=1&limit=20', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges?tab=ACTIVE&page=1&limit=20',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_active_123');
        expect(request.headers['Refresh-Token'], 'refresh_active_456');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);

      final response = await repo.getChallenges(
        tab: 'ACTIVE',
        page: 1,
        limit: 20,
        sessionToken: 'session_active_123',
        refreshToken: 'refresh_active_456',
      );

      expect(response.success, isTrue);
      expect(response.data.length, 1);
      expect(response.data.first.title, 'Monthly Mega Dance Battle');
      expect(response.data.first.status, 'ACTIVE');
    });

    test('5. ChallengesCubit loads and filters challenges for tab ACTIVE', () async {
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
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      final challenges = await cubit.loadTabChallenges('ACTIVE');

      expect(challenges.length, 1);
      expect(challenges.first.title, 'Monthly Mega Dance Battle');
      expect(cubit.hasLoadedTabChallenges('ACTIVE'), isTrue);

      final tabList = cubit.getChallengesForTab('ACTIVE');
      expect(tabList.length, 1);
      expect(tabList.first['title'], 'Monthly Mega Dance Battle');
      expect(tabList.first['prize'], '₹5,000');
    });

    test('6. ChallengesRepository & Cubit execute search GET /app/challenges?tab=ACTIVE&q=dance&page=1&limit=20', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges?tab=ACTIVE&q=dance&page=1&limit=20',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_search_123');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authCubit = AuthCubit();
      authCubit.applyRefreshedTokens(
        sessionToken: 'session_search_123',
        refreshToken: 'refresh_search_456',
      );

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      cubit.setChallengeQuery('dance', tab: 'ACTIVE');

      // Wait a tick for async load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final results = cubit.getChallengesForTab('ACTIVE');
      expect(results.length, 1);
      expect(results.first['title'], 'Monthly Mega Dance Battle');
      expect(cubit.challengeQuery, 'dance');
    });

    test('7. ChallengesRepository & Cubit load FEATURED tab GET /app/challenges?tab=FEATURED&page=1&limit=20', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges?tab=FEATURED&page=1&limit=20',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_featured_123');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authCubit = AuthCubit();
      authCubit.applyRefreshedTokens(
        sessionToken: 'session_featured_123',
        refreshToken: 'refresh_featured_456',
      );

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      final featuredChallenges = await cubit.loadTabChallenges('FEATURED');
      expect(featuredChallenges.length, 1);
      expect(featuredChallenges.first.title, 'Monthly Mega Dance Battle');
      expect(featuredChallenges.first.isFeatured, isTrue);

      final tabList = cubit.getChallengesForTab('FEATURED');
      expect(tabList.length, 1);
      expect(tabList.first['title'], 'Monthly Mega Dance Battle');
    });

    test('8. ChallengesRepository & Cubit load Challenges By Category GET /app/challenges?categoryId=cmssjtraw000tq1h82oan31my&page=1&limit=20', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges?categoryId=cmssjtraw000tq1h82oan31my&page=1&limit=20',
        );
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer session_cat_chal_123');

        return http.Response(
          jsonEncode(mockApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authCubit = AuthCubit();
      authCubit.applyRefreshedTokens(
        sessionToken: 'session_cat_chal_123',
        refreshToken: 'refresh_cat_chal_456',
      );

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      final categoryChallenges = await cubit.loadChallengesByCategory('cmssjtraw000tq1h82oan31my');
      expect(categoryChallenges.length, 1);
      expect(categoryChallenges.first.title, 'Monthly Mega Dance Battle');
      expect(categoryChallenges.first.categoryName, 'Dance');

      final categoryList = cubit.getChallengesForCategory('cmssjtraw000tq1h82oan31my');
      expect(categoryList.length, 1);
      expect(categoryList.first['title'], 'Monthly Mega Dance Battle');
      expect(categoryList.first['prize'], '₹5,000');
    });

    test('9. ChallengesRepository & Cubit joinChallenge calls POST /app/challenges/{{challengeId}}/join', () async {
      const mockJoinResponse = {
        "success": true,
        "message": "Challenge joined successfully",
        "data": {
          "id": "cmssvn2jx000htexy5nm0yok1",
          "userId": "cmssjncz7000cq1h8unn0r6uk",
          "challengeId": "cmssjscj2000sq1h8qdsicupj",
          "videoId": null,
          "status": "DRAFT",
          "submittedAt": null,
          "createdAt": "2026-08-14T11:41:52.941Z",
          "updatedAt": "2026-08-14T11:41:52.941Z"
        }
      };

      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/app/challenges/cmssjscj2000sq1h8qdsicupj/join',
        );
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer session_join_123');

        return http.Response(
          jsonEncode(mockJoinResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authCubit = AuthCubit();
      authCubit.applyRefreshedTokens(
        sessionToken: 'session_join_123',
        refreshToken: 'refresh_join_456',
      );

      final apiClient = ApiClient(client: mockClient);
      final repo = ChallengesRepository(apiClient: apiClient);
      final cubit = ChallengesCubit(
        authCubit: authCubit,
        challengesRepository: repo,
      );

      final result = await cubit.joinChallenge('cmssjscj2000sq1h8qdsicupj');
      expect(result.success, isTrue);
      expect(result.message, 'Challenge joined successfully');
      expect(result.data?.id, 'cmssvn2jx000htexy5nm0yok1');
      expect(result.data?.challengeId, 'cmssjscj2000sq1h8qdsicupj');
      expect(result.data?.status, 'DRAFT');
    });
  });
}

