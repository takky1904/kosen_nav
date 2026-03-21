import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';

import '../../../core/config/env.dart';
import '../../../core/router/app_navigator_key.dart';

class TeamsAuthService {
  TeamsAuthService({AadOAuth? oauth})
    : _oauth = oauth ?? AadOAuth(_buildConfig());

  final AadOAuth _oauth;

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
