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
  String get appTagline => 'TEApoya TEAcompaña';

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
      'Your account and linked child profiles, including their avatars, progress and usage metrics, will be removed. Type DELETE to continue.';

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
  String get reminderPlaceholder => 'Turn on reminders to choose the time';

  @override
  String reminderDailyAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderNotificationTitle => 'Time to practice with Appy';

  @override
  String get reminderNotificationBody =>
      'There are activities waiting for you.';

  @override
  String get reminderPermissionDenied =>
      'Turn on Appy notifications in the phone settings to get reminders.';

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
      'To generate indicators of educational performance, Appy can collect pseudonymized metrics about activity usage. This data is associated with an account identifier and does not include names or email addresses.\nThis collection is optional. You can decline without losing access to activities and change your choice at any time in Settings.';

  @override
  String get telemetryConsentAccept => 'Accept';

  @override
  String get telemetryConsentDecline => 'No, thanks';

  @override
  String get parentalSection => 'Parental control';

  @override
  String get parentalAllowedModules => 'Allowed modules';

  @override
  String get parentalNoLimit => 'All';

  @override
  String get profileOpenAllLevels => 'Open all levels';

  @override
  String get profileOpenAllLevelsHint =>
      'Shows every level of the allowed modules as open. Coins and stars are only earned by completing each activity.';

  @override
  String get openLevelsActive => 'Free mode';

  @override
  String get downloadsTitle => 'Offline content';

  @override
  String get downloadsIntro =>
      'Download a module to use it without internet. You need a connection to download. Progress is saved and sent when the network returns.';

  @override
  String get downloadsEmpty => 'There are no modules to download yet.';

  @override
  String get downloadsNotDownloaded => 'Not downloaded';

  @override
  String get downloadsPartial => 'Incomplete download';

  @override
  String downloadsDownloaded(String size) {
    return 'Downloaded, $size';
  }

  @override
  String downloadsInProgress(int done, int total) {
    return 'Downloading $done of $total';
  }

  @override
  String get downloadsAction => 'Download';

  @override
  String get downloadsRetry => 'Retry';

  @override
  String get downloadsDeleteTooltip => 'Delete download';

  @override
  String get downloadsDeleteTitle => 'Delete the download?';

  @override
  String get downloadsDeleteBody =>
      'This frees the space on the phone. You can download it again whenever you want.';

  @override
  String get downloadsErrorNetwork =>
      'The download failed. Check your connection and try again.';

  @override
  String get downloadsErrorNoSpace => 'There is not enough space on the phone.';

  @override
  String get downloadsErrorOther => 'The download could not be completed.';

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

  @override
  String get childSectionDanger => 'Danger zone';

  @override
  String get profileDelete => 'Delete profile';

  @override
  String get profileDeleteHint =>
      'Permanently deletes the profile, its avatar and its progress.';

  @override
  String profileDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String profileDeleteBody(String name) {
    return 'This will permanently delete $name’s profile, including avatar, settings, progress and usage metrics. This cannot be undone.';
  }

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleteFailed =>
      'Could not delete the profile. Check your connection and try again.';

  @override
  String profileDeleteDone(String name) {
    return '$name\'s profile was deleted.';
  }

  @override
  String get deleteAccountSuccess => 'Account deleted successfully.';

  @override
  String get completionRewardsPending => 'Rewards pending synchronization.';

  @override
  String get completionSaveFailed =>
      'The result could not be saved. You can return and try again.';

  @override
  String get downloadsCancelling => 'Cancelling…';

  @override
  String get completionRewardsConfirmed => 'Rewards synchronized.';

  @override
  String get completionRewardsLoading => 'Loading rewards';

  @override
  String get legalConsentTitle => 'Before you continue';

  @override
  String get legalConsentSubtitle =>
      'Read and accept the documents that govern the use of Appy and the processing of personal data.';

  @override
  String get legalConsentRead => 'Read';

  @override
  String get legalConsentUnread => 'Not read';

  @override
  String get legalConsentSensitiveNote =>
      'Appy is designed to support people with Autism Spectrum Disorder. Because of this, using the app may relate to information about the child\'s health, which is sensitive personal data. The law requires consent to be given expressly.';

  @override
  String get legalConsentCheckbox =>
      'I have read and accept the Terms and Conditions and the Privacy Notice, and I declare that I am of legal age and the parent or legal guardian of the person who will use the app.';

  @override
  String get legalConsentReadBothHint =>
      'Open and read both documents to be able to accept.';

  @override
  String get legalConsentDecline => 'I don\'t accept';

  @override
  String get legalConsentAccept => 'I accept';

  @override
  String get legalConsentSaveFailed =>
      'Your acceptance could not be saved. Check your connection and try again.';

  @override
  String get legalConsentDeclineTitle => 'Continue without accepting';

  @override
  String get legalConsentDeclineBody =>
      'To use Appy you need to accept the Terms and Conditions and the Privacy Notice. If you\'d rather not do it now, we\'ll sign you out and you can come back whenever you like.';

  @override
  String get legalConsentKeepReading => 'Keep reading';

  @override
  String get verifyEmailTitle => 'Confirm your email';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a link to $email. Open it to confirm that you are the adult responsible for the account. This step is required before a child uses Appy.';
  }

  @override
  String get verifyEmailSpamHint =>
      'If you don\'t see it, check your spam folder.';

  @override
  String get verifyEmailConfirmed => 'I\'ve confirmed it';

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String verifyEmailResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get verifyEmailSent => 'We sent you a new link.';

  @override
  String get verifyEmailSendFailed =>
      'The email could not be sent. Check your connection and try again.';

  @override
  String get verifyEmailNotYet =>
      'Your email isn\'t confirmed yet. Open the link and try again.';
}
