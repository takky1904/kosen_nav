class Env {
  Env._();

  // TODO: 実運用値に置き換える
  static const String msClientId = 'c621ac65-bf44-4372-bc8e-2212a7102cc0';
  static const String msTenantId = 'common';
  static const String msRedirectUri =
      'https://login.live.com/oauth20_desktop.srf';
  static const String msGraphScope =
      'openid profile offline_access User.Read EduAssignments.ReadBasic EduAssignments.Read';
}
