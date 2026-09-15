import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Appy'**
  String get appTitle;

  /// No description provided for @navModules.
  ///
  /// In es, this message translates to:
  /// **'Módulos'**
  String get navModules;

  /// No description provided for @navAvatar.
  ///
  /// In es, this message translates to:
  /// **'Avatar'**
  String get navAvatar;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'PIN'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @profileSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil de usuario'**
  String get profileSectionTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre para mostrar'**
  String get displayNameLabel;

  /// No description provided for @editDisplayName.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get editDisplayName;

  /// No description provided for @changeAvatar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar avatar'**
  String get changeAvatar;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get emailLabel;

  /// No description provided for @accountSecuritySection.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y seguridad'**
  String get accountSecuritySection;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará tu cuenta y datos almacenados. Escribe BORRAR para continuar.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'BORRAR'**
  String get deleteAccountConfirmAction;

  /// No description provided for @languageSection.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSection;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get languageEnglish;

  /// No description provided for @appearanceSection.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearanceSection;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @fontSizeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de fuente'**
  String get fontSizeLabel;

  /// No description provided for @fontSmall.
  ///
  /// In es, this message translates to:
  /// **'Pequeño'**
  String get fontSmall;

  /// No description provided for @fontMedium.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get fontMedium;

  /// No description provided for @fontLarge.
  ///
  /// In es, this message translates to:
  /// **'Grande'**
  String get fontLarge;

  /// No description provided for @accessibilitySection.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get accessibilitySection;

  /// No description provided for @highContrast.
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get highContrast;

  /// No description provided for @reduceAnimations.
  ///
  /// In es, this message translates to:
  /// **'Reducir animaciones'**
  String get reduceAnimations;

  /// No description provided for @audioFeedback.
  ///
  /// In es, this message translates to:
  /// **'Feedback auditivo'**
  String get audioFeedback;

  /// No description provided for @hapticFeedback.
  ///
  /// In es, this message translates to:
  /// **'Feedback háptico'**
  String get hapticFeedback;

  /// No description provided for @notificationsSection.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones y recordatorios'**
  String get notificationsSection;

  /// No description provided for @enableReminders.
  ///
  /// In es, this message translates to:
  /// **'Activar recordatorios de práctica'**
  String get enableReminders;

  /// No description provided for @scheduleReminder.
  ///
  /// In es, this message translates to:
  /// **'Horario sugerido'**
  String get scheduleReminder;

  /// No description provided for @reminderPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Programación disponible pronto'**
  String get reminderPlaceholder;

  /// No description provided for @privacySection.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y datos'**
  String get privacySection;

  /// No description provided for @clearCache.
  ///
  /// In es, this message translates to:
  /// **'Limpiar caché de recursos'**
  String get clearCache;

  /// No description provided for @sendMetrics.
  ///
  /// In es, this message translates to:
  /// **'Enviar métricas anónimas'**
  String get sendMetrics;

  /// No description provided for @parentalSection.
  ///
  /// In es, this message translates to:
  /// **'Control parental'**
  String get parentalSection;

  /// No description provided for @parentalMinLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel mínimo requerido'**
  String get parentalMinLevel;

  /// No description provided for @infoSection.
  ///
  /// In es, this message translates to:
  /// **'Información y soporte'**
  String get infoSection;

  /// No description provided for @appVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get appVersion;

  /// No description provided for @termsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Términos y Privacidad'**
  String get termsPrivacy;

  /// No description provided for @feedbackSupport.
  ///
  /// In es, this message translates to:
  /// **'Enviar feedback / soporte'**
  String get feedbackSupport;

  /// No description provided for @savedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajustes actualizados'**
  String get savedSnackbar;

  /// No description provided for @errorSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema'**
  String get errorSnackbar;

  /// No description provided for @cacheClearedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Caché limpiada'**
  String get cacheClearedSnackbar;

  /// No description provided for @reminderNotImplemented.
  ///
  /// In es, this message translates to:
  /// **'La programación llegará pronto'**
  String get reminderNotImplemented;

  /// No description provided for @logoutSuccess.
  ///
  /// In es, this message translates to:
  /// **'Sesión cerrada'**
  String get logoutSuccess;

  /// No description provided for @passwordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordUpdated;

  /// No description provided for @displayNameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado'**
  String get displayNameUpdated;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta'**
  String get deleteAccountFailed;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
