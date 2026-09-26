// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Appy';

  @override
  String get navModules => 'Modules';

  @override
  String get navAvatar => 'Avatar';

  @override
  String get navSettings => 'PIN';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileSectionTitle => 'User profile';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get editDisplayName => 'Edit name';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get emailLabel => 'Email';

  @override
  String get accountSecuritySection => 'Account & security';

  @override
  String get changePassword => 'Change password';

  @override
  String get logout => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmBody =>
      'Your account and linked child profiles, including their avatars and progress, will be removed. Anonymous metrics already sent cannot be deleted. Type DELETE to continue.';

  @override
  String get deleteAccountConfirmAction => 'DELETE';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSizeLabel => 'Font size';

  @override
  String get fontSmall => 'Small';

  @override
  String get fontMedium => 'Medium';

  @override
  String get fontLarge => 'Large';

  @override
  String get accessibilitySection => 'Accessibility';

  @override
  String get highContrast => 'High contrast';

  @override
  String get reduceAnimations => 'Reduce animations';

  @override
  String get audioFeedback => 'Audio feedback';

  @override
  String get hapticFeedback => 'Haptic feedback';

  @override
  String get notificationsSection => 'Notifications & reminders';

  @override
  String get enableReminders => 'Enable practice reminders';

  @override
  String get scheduleReminder => 'Suggested schedule';

  @override
  String get reminderPlaceholder => 'Scheduling coming soon';

  @override
  String get privacySection => 'Privacy & data';

  @override
  String get clearCache => 'Clear cached resources';

  @override
  String get sendMetrics => 'Send anonymous metrics';

  @override
  String get telemetryConsentTitle => 'Help us improve';

  @override
  String get telemetryConsentBody =>
      'To improve the experience, Appy can send anonymous metrics about activity usage. No personal data is sent and you can review it anytime in Settings.';

  @override
  String get telemetryConsentAccept => 'Accept';

  @override
  String get telemetryConsentDecline => 'No, thanks';

  @override
  String get parentalSection => 'Parental control';

  @override
  String get parentalAllowedModules => 'Allowed modules';

  @override
  String get parentalNoLimit => 'No limit';

  @override
  String get parentalModulesUnit => 'modules';

  @override
  String get currentPasswordLabel => 'Account password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get infoSection => 'Info & support';

  @override
  String get appVersion => 'App version';

  @override
  String get termsPrivacy => 'Terms & Privacy';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get feedbackSupport => 'Send feedback / support';

  @override
  String get savedSnackbar => 'Settings updated';

  @override
  String get errorSnackbar => 'Something went wrong';

  @override
  String get cacheClearedSnackbar => 'Cache cleaned';

  @override
  String get reminderNotImplemented =>
      'Reminder scheduling will be available soon';

  @override
  String get logoutSuccess => 'You signed out';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get displayNameUpdated => 'Name updated';

  @override
  String get deleteAccountFailed => 'Could not delete the account';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileHubTitle => 'Family profiles';

  @override
  String get profileHubBody =>
      'Choose a profile to start learning, or edit its settings.';

  @override
  String get profileWelcomeTitle => 'Let’s get started!';

  @override
  String get profileWelcomeBody =>
      'Create the first profile to keep learning progress and avatar data separate.';

  @override
  String get profileAddTitle => 'Add child profile';

  @override
  String get profileAddFirst => 'Create first profile';

  @override
  String get profileNameLabel => 'Profile name';

  @override
  String get profileManageTitle => 'Child profiles';

  @override
  String get profileManageBody =>
      'Each profile has its own progress, avatar, settings, and module limit.';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileAllowedModules => 'Module limit';

  @override
  String get profileSaveFailed =>
      'Could not save the profile. Check your connection and try again.';

  @override
  String get profileLegacyMigrated =>
      'We found the existing progress and avatar and copied them to a child profile. Confirm or edit the name to continue.';

  @override
  String get profileLegacyTitle => 'Confirm child profile';

  @override
  String get profileConfirmName => 'Confirm name';

  @override
  String get profilePendingConfirmation => 'Pending confirmation';

  @override
  String get profileRetry => 'Retry';

  @override
  String get profileLoadFailed =>
      'Could not load profiles. Check your connection and try again.';

  @override
  String get profileResetTitle => 'Reset progress?';

  @override
  String get profileReset => 'Reset progress';

  @override
  String profileResetPrompt(String name) {
    return 'This will erase $name’s level progress. Their avatar and coins will be kept. Continue?';
  }

  @override
  String profileResetDone(String name) {
    return 'Reset $name’s progress.';
  }

  @override
  String get profileOpenSettings => 'Account settings';

  @override
  String get profileOpenSettingsBody =>
      'Theme, language, security, and privacy.';

  @override
  String get profileResetHint =>
      'Clears stars and levels without touching the avatar.';

  @override
  String childSettingsTitle(String name) {
    return '$name’s settings';
  }

  @override
  String get childSectionProfile => 'Profile';

  @override
  String get childSectionLearning => 'Learning';

  @override
  String get childSectionDisplay => 'Display and accessibility';

  @override
  String get childSectionFeedback => 'Sound and vibration';

  @override
  String get childSectionReminders => 'Reminders';

  @override
  String get childEditName => 'Change profile name';
}
