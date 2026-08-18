import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artable_app/core/network/api_client.dart';
import 'package:artable_app/core/network/api_config.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/auth/data/models/forgot_password_request.dart';
import 'package:artable_app/features/auth/data/models/login_request.dart';
import 'package:artable_app/features/auth/data/models/register_request.dart';
import 'package:artable_app/features/auth/data/models/resend_otp_request.dart';
import 'package:artable_app/features/auth/data/models/reset_password_request.dart';
import 'package:artable_app/features/auth/data/models/token_verify_request.dart';
import 'package:artable_app/features/auth/data/models/update_profile_request.dart';
import 'package:artable_app/features/auth/data/models/verify_otp_request.dart';
import 'package:artable_app/features/auth/data/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth API Repository & Models Tests', () {
    test('1. POST /auth/login parses response and stores session tokens', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'test@example.com');
        expect(body['password'], 'Password123!');

        return http.Response(
          jsonEncode({
            'status': 200,
            'message': 'Login successful',
            'sessionToken': 'mock_session_token_123',
            'refreshToken': 'mock_refresh_token_456',
            'userInfo': {
              'id': 'user_abc_789',
              'email': 'test@example.com',
              'username': 'testuser',
              'firstName': 'John',
              'lastName': 'Doe',
              'bio': 'Creative artist',
              'category': 'Art',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.login(
        const LoginRequest(email: 'test@example.com', password: 'Password123!'),
      );

      expect(response.sessionToken, 'mock_session_token_123');
      expect(response.refreshToken, 'mock_refresh_token_456');
      expect(response.userInfo?.id, 'user_abc_789');
      expect(response.userInfo?.displayName, 'John Doe');

      final session = await repo.loadStoredSession();
      expect(session?.sessionToken, 'mock_session_token_123');
      expect(session?.userId, 'user_abc_789');
    });

    test('2. POST /auth/register sends correct registration payload', () async {
      var requestReceived = false;

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/auth/register');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fullName'], 'Jane Doe');
        expect(body['email'], 'jane@example.com');
        expect(body['password'], 'SecurePass456!');
        expect(body['confirmPassword'], 'SecurePass456!');
        requestReceived = true;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User created successfully. OTP sent successfully',
            'userId': 'usr_123',
            'verifyId': 'vid_456',
            'otp': 123456,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.register(
        const RegisterRequest(
          fullName: 'Jane Doe',
          email: 'jane@example.com',
          password: 'SecurePass456!',
          confirmPassword: 'SecurePass456!',
        ),
      );

      expect(requestReceived, isTrue);
      expect(response.success, isTrue);
      expect(response.userId, 'usr_123');
      expect(response.verifyId, 'vid_456');
      expect(response.otp, 123456);
    });

    test('2b. POST /auth/verify-otp sends correct verification payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/auth/verify-otp');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['verifyId'], 'vid_456');
        expect(body['otp'], '123456');
        expect(body['channel'], 'EMAIL');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Otp Verified',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.verifyOtp(
        const VerifyOtpRequest(
          verifyId: 'vid_456',
          otp: '123456',
          channel: 'EMAIL',
        ),
      );

      expect(response.success, isTrue);
      expect(response.message, 'Otp Verified');
    });

    test('2c. POST /auth/resend-otp sends correct resend payload and updates verifyId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/auth/resend-otp');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userId'], 'usr_123');
        expect(body['email'], 'demo@example.com');
        expect(body['channel'], 'EMAIL');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OTP sent successfully',
            'verifyId': 'new_vid_789',
            'otp': 451770,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.resendOtp(
        const ResendOtpRequest(
          userId: 'usr_123',
          email: 'demo@example.com',
          channel: 'EMAIL',
        ),
      );

      expect(response.success, isTrue);
      expect(response.message, 'OTP sent successfully');
      expect(response.verifyId, 'new_vid_789');
      expect(response.otp, 451770);
    });

    test('2d. POST /auth/forgot-password sends email and returns success message', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/auth/forgot-password');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'test0@example.com');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Reset Password link sent on your E-mail address. Please check your inbox!',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.forgotPassword(
        const ForgotPasswordRequest(email: 'test0@example.com'),
      );

      expect(response.success, isTrue);
      expect(
        response.message,
        'Reset Password link sent on your E-mail address. Please check your inbox!',
      );
    });

    test('2e. POST /auth/reset-password/token-verify sends token and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/auth/reset-password/token-verify',
        );
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'valid_token_123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Token is valid',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.verifyResetToken(
        const TokenVerifyRequest(token: 'valid_token_123'),
      );

      expect(response.success, isTrue);
      expect(response.message, 'Token is valid');
    });

    test('2f. POST /auth/reset-password sends token and new password and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/auth/reset-password',
        );
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'reset_token_xyz');
        expect(body['password'], 'NewPassword@123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Password reset successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final response = await repo.resetPassword(
        const ResetPasswordRequest(
          token: 'reset_token_xyz',
          password: 'NewPassword@123',
        ),
      );

      expect(response.success, isTrue);
      expect(response.message, 'Password reset successfully');
    });

    test('3. GET /user/{userId} fetches user detail with auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/user/user_abc_789');
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer mock_session_token_123');
        expect(request.headers['Refresh-Token'], 'mock_refresh_token_456');

        return http.Response(
          jsonEncode({
            'status': 200,
            'data': {
              '_id': 'user_abc_789',
              'username': 'john_creator',
              'email': 'john@example.com',
              'firstName': 'John',
              'lastName': 'Creator',
              'bio': 'Pro Painter & Animator',
              'category': 'Painting',
              'socialLinks': [
                {'platform': 'Instagram', 'url': 'https://instagram.com/john'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final user = await repo.getUserDetails(
        userId: 'user_abc_789',
        sessionToken: 'mock_session_token_123',
        refreshToken: 'mock_refresh_token_456',
      );

      expect(user.id, 'user_abc_789');
      expect(user.username, 'john_creator');
      expect(user.displayName, 'John Creator');
      expect(user.bio, 'Pro Painter & Animator');
      expect(user.category, 'Painting');
      expect(user.socialLinks?.length, 1);
    });

    test('4. PUT /user updates current profile with PUT method and payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '${ApiConfig.baseUrl}/user');
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer mock_session_token_123');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['firstName'], 'Jane');
        expect(body['username'], 'jane_updated');
        expect(body['bio'], 'Updated artist bio');
        expect(body['category'], 'Dance');

        return http.Response(
          jsonEncode({
            'status': 200,
            'message': 'Profile updated successfully',
            'data': {
              'id': 'user_abc_789',
              'username': 'jane_updated',
              'firstName': 'Jane',
              'lastName': 'Doe',
              'bio': 'Updated artist bio',
              'category': 'Dance',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);

      final updatedUser = await repo.updateProfile(
        request: const UpdateProfileRequest(
          firstName: 'Jane',
          lastName: 'Doe',
          username: 'jane_updated',
          bio: 'Updated artist bio',
          category: 'Dance',
          socialLinks: [],
        ),
        sessionToken: 'mock_session_token_123',
        refreshToken: 'mock_refresh_token_456',
      );

      expect(updatedUser.username, 'jane_updated');
      expect(updatedUser.bio, 'Updated artist bio');
      expect(updatedUser.category, 'Dance');
    });

    test('5. AuthProvider state flows: Login -> Fetch details -> Save profile', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'sessionToken': 'token_999',
              'refreshToken': 'refresh_999',
              'userInfo': {
                'id': 'uid_100',
                'username': 'artuser',
                'firstName': 'Art',
                'lastName': 'Master',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path == '/user/uid_100') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'uid_100',
                'username': 'artuser',
                'firstName': 'Art',
                'lastName': 'Master',
                'bio': 'Detailed bio from server',
                'category': 'Music',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (path == '/user' && request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'uid_100',
                'username': 'artuser_new',
                'firstName': 'Arturo',
                'lastName': 'Master',
                'bio': 'New bio',
                'category': 'Photography',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);
      final cubit = AuthCubit(authRepository: repo);

      final loginSuccess = await cubit.login('art@test.com', 'secret');
      expect(loginSuccess, isTrue);
      expect(cubit.isLoggedIn, isTrue);
      expect(cubit.userName, 'Art Master');

      final userDetail = await cubit.fetchUserDetails();
      expect(userDetail?.bio, 'Detailed bio from server');
      expect(cubit.currentUser['bio'], 'Detailed bio from server');

      final saveSuccess = await cubit.saveProfile(
        fullName: 'Arturo Master',
        username: 'artuser_new',
        bio: 'New bio',
        category: 'Photography',
        socialLinkUrl: 'https://instagram.com/art',
      );
      expect(saveSuccess, isTrue);
      expect(cubit.userName, 'Arturo Master');
      expect(cubit.currentUser['handle'], '@artuser_new');
      expect(cubit.currentUser['category'], 'Photography');
    });

    test('6. User Detail GET parses nested bio and alias keys correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 200,
            'message': 'User details fetched',
            'data': {
              'user': {
                '_id': 'uid_custom_1',
                'username': 'raval123',
                'category': 'DANCE',
              },
              'bio': 'Passionate Hip-Hop Dancer & Choreographer',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);
      final user = await repo.getUserDetails(
        userId: 'uid_custom_1',
        sessionToken: 'token_mock',
        refreshToken: 'refresh_mock',
      );

      expect(user.id, 'uid_custom_1');
      expect(user.username, 'raval123');
      expect(user.category, 'DANCE');
      expect(user.bio, 'Passionate Hip-Hop Dancer & Choreographer');
    });

    test('7. AuthProvider saveProfile passes separate Full Name and Username', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/user' && request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['fullName'], 'Devendra Kumar Raval');
          expect(body['firstName'], 'Devendra');
          expect(body['middleName'], 'Kumar');
          expect(body['lastName'], 'Raval');
          expect(body['username'], 'raval_artist');
          expect(body['socialLinks'], {'instagramUrl': 'https://instagram.com/raval'});

          return http.Response(
            jsonEncode({
              'data': {
                'id': 'uid_custom_1',
                'username': 'raval_artist',
                'firstName': 'Devendra',
                'middleName': 'Kumar',
                'lastName': 'Raval',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);
      final cubit = AuthCubit(authRepository: repo);

      final saveSuccess = await cubit.saveProfile(
        fullName: 'Devendra Kumar Raval',
        username: 'raval_artist',
        bio: 'Artist bio',
        category: 'Dance',
        socialLinkUrl: 'https://instagram.com/raval',
      );

      expect(saveSuccess, isTrue);
      expect(cubit.fullName, 'Devendra Kumar Raval');
      expect(cubit.username, 'raval_artist');
    });

    test('8. GET /user/:id parses real backend schema with talentCategory and map socialLinks', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Successfully',
            'data': {
              'id': 'cmsrj3d22004g11pkhdpvvsam',
              'fullName': 'ki1',
              'email': 'ki1@yopmail.com',
              'username': 'ki13141',
              'gender': 'NOT_SPECIFY',
              'phoneNumber': null,
              'profilePhotoUrl': null,
              'coverImageUrl': null,
              'bio': 'Dfdsfds dhtejkhskj',
              'talentCategory': 'test',
              'socialLinks': {
                'websiteUrl': 'https://grandas.co.nz/',
              },
              'instagramUrl': null,
              'youtubeUrl': null,
              'websiteUrl': 'https://grandas.co.nz/',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);
      final user = await repo.getUserDetails(
        userId: 'cmsrj3d22004g11pkhdpvvsam',
        sessionToken: 'token_mock',
        refreshToken: 'refresh_mock',
      );

      expect(user.id, 'cmsrj3d22004g11pkhdpvvsam');
      expect(user.fullName, 'ki1');
      expect(user.username, 'ki13141');
      expect(user.category, 'test');
      expect(user.bio, 'Dfdsfds dhtejkhskj');
      expect(user.socialLinks?.first['url'], 'https://grandas.co.nz/');
    });

    test('9. POST /user/change-password passes currentPassword and newPassword and parses response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/user/change-password' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['currentPassword'], 'test@123');
          expect(body['newPassword'], 'NewPassword@123');

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Password Updated successfully',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepository(apiClient: apiClient);
      final cubit = AuthCubit(authRepository: repo);

      final success = await cubit.changePassword(
        currentPassword: 'test@123',
        newPassword: 'NewPassword@123',
      );

      expect(success, isTrue);
    });
  });
}
