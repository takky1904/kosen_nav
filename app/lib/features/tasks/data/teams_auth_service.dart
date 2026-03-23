import 'dart:typed_data';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../core/router/app_navigator_key.dart';

class TeamsAuthService {
  TeamsAuthService({AadOAuth? oauth})
    : _oauth = oauth ?? AadOAuth(_buildConfig());

  final AadOAuth _oauth;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://graph.microsoft.com/v1.0',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String> signInAndGetAccessToken() async {
    if (Env.msClientId.isEmpty || Env.msClientId == 'YOUR_MS_CLIENT_ID') {
      throw Exception('MS_CLIENT_ID が未設定です。env.dart を更新してください。');
    }

    await _oauth.login();
    final token = await _oauth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Microsoftアクセストークンを取得できませんでした。');
    }
    return token;
  }

  Future<Uint8List?> fetchProfilePhotoBytes(String accessToken) async {
    try {
      final response = await _dio.get<List<int>>(
        r'/me/photo/$value',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        return null;
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) {
        // プロフィール画像未設定時は null で返してUI側でデフォルト表示にフォールバック。
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Config _buildConfig() {
    return Config(
      tenant: Env.msTenantId,
      clientId: Env.msClientId,
      scope: Env.msGraphScope,
      redirectUri: Env.msRedirectUri,
      navigatorKey: appNavigatorKey,
      webUseRedirect: true,
    );
  }
}
