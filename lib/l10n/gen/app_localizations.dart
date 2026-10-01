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

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'TEApoya TEAcompaña'**
  String get appTagline;

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
  /// **'Se eliminará tu cuenta y los perfiles infantiles vinculados, incluidos sus avatares y progresos. Las métricas anónimas ya enviadas no se pueden eliminar. Escribe BORRAR para continuar.'**
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

  /// No description provided for @telemetryConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayúdanos a mejorar'**
  String get telemetryConsentTitle;

  /// No description provided for @telemetryConsentBody.
  ///
  /// In es, this message translates to:
  /// **'Para mejorar la experiencia, Appy puede enviar métricas anónimas sobre el uso de las actividades. No se envían datos personales y puedes revisarlo cuando quieras en Ajustes.'**
  String get telemetryConsentBody;

  /// No description provided for @telemetryConsentAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get telemetryConsentAccept;

  /// No description provided for @telemetryConsentDecline.
  ///
  /// In es, this message translates to:
  /// **'No, gracias'**
  String get telemetryConsentDecline;

  /// No description provided for @parentalSection.
  ///
  /// In es, this message translates to:
  /// **'Control parental'**
  String get parentalSection;

  /// No description provided for @parentalAllowedModules.
  ///
  /// In es, this message translates to:
  /// **'Módulos permitidos'**
  String get parentalAllowedModules;

  /// No description provided for @parentalNoLimit.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get parentalNoLimit;

  /// No description provided for @profileOpenAllLevels.
  ///
  /// In es, this message translates to:
  /// **'Abrir todos los niveles'**
  String get profileOpenAllLevels;

  /// No description provided for @profileOpenAllLevelsHint.
  ///
  /// In es, this message translates to:
  /// **'Muestra abiertos todos los niveles de los módulos permitidos. Las monedas y estrellas solo se ganan al completar cada actividad.'**
  String get profileOpenAllLevelsHint;

  /// No description provided for @openLevelsActive.
  ///
  /// In es, this message translates to:
  /// **'Modo libre'**
  String get openLevelsActive;

  /// No description provided for @downloadsTitle.
  ///
  /// In es, this message translates to:
  /// **'Contenido sin conexión'**
  String get downloadsTitle;

  /// No description provided for @downloadsIntro.
  ///
  /// In es, this message translates to:
  /// **'Descarga un módulo para usarlo sin internet. Para descargar necesitas conexión. El progreso se guarda y se envía cuando vuelve la red.'**
  String get downloadsIntro;

  /// No description provided for @downloadsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay módulos para descargar.'**
  String get downloadsEmpty;

  /// No description provided for @downloadsNotDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Sin descargar'**
  String get downloadsNotDownloaded;

  /// No description provided for @downloadsPartial.
  ///
  /// In es, this message translates to:
  /// **'Descarga incompleta'**
  String get downloadsPartial;

  /// No description provided for @downloadsDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Descargado, {size}'**
  String downloadsDownloaded(String size);

  /// No description provided for @downloadsInProgress.
  ///
  /// In es, this message translates to:
  /// **'Descargando {done} de {total}'**
  String downloadsInProgress(int done, int total);

  /// No description provided for @downloadsAction.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get downloadsAction;

  /// No description provided for @downloadsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get downloadsRetry;

  /// No description provided for @downloadsDeleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Borrar descarga'**
  String get downloadsDeleteTooltip;

  /// No description provided for @downloadsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar la descarga?'**
  String get downloadsDeleteTitle;

  /// No description provided for @downloadsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se libera el espacio del teléfono. Puedes volver a descargarlo cuando quieras.'**
  String get downloadsDeleteBody;

  /// No description provided for @downloadsErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar. Revisa tu conexión e inténtalo de nuevo.'**
  String get downloadsErrorNetwork;

  /// No description provided for @downloadsErrorNoSpace.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio suficiente en el teléfono.'**
  String get downloadsErrorNoSpace;

  /// No description provided for @downloadsErrorOther.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la descarga.'**
  String get downloadsErrorOther;

  /// No description provided for @parentalModulesUnit.
  ///
  /// In es, this message translates to:
  /// **'módulos'**
  String get parentalModulesUnit;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña de la cuenta'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña nueva'**
  String get newPasswordLabel;

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

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get privacyPolicy;

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

  /// No description provided for @profileHubTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfiles de la familia'**
  String get profileHubTitle;

  /// No description provided for @profileHubBody.
  ///
  /// In es, this message translates to:
  /// **'Elige un perfil para comenzar o edita sus ajustes.'**
  String get profileHubBody;

  /// No description provided for @profileWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Vamos a empezar!'**
  String get profileWelcomeTitle;

  /// No description provided for @profileWelcomeBody.
  ///
  /// In es, this message translates to:
  /// **'Crea el primer perfil para guardar el aprendizaje y el avatar de forma independiente.'**
  String get profileWelcomeBody;

  /// No description provided for @profileAddTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar perfil infantil'**
  String get profileAddTitle;

  /// No description provided for @profileAddFirst.
  ///
  /// In es, this message translates to:
  /// **'Crear primer perfil'**
  String get profileAddFirst;

  /// No description provided for @profileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del perfil'**
  String get profileNameLabel;

  /// No description provided for @profileManageTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfiles infantiles'**
  String get profileManageTitle;

  /// No description provided for @profileManageBody.
  ///
  /// In es, this message translates to:
  /// **'Cada perfil guarda su propio progreso, avatar, ajustes y límite de módulos.'**
  String get profileManageBody;

  /// No description provided for @profileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEdit;

  /// No description provided for @profileAllowedModules.
  ///
  /// In es, this message translates to:
  /// **'Límite de módulos'**
  String get profileAllowedModules;

  /// No description provided for @profileSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el perfil. Revisa tu conexión e inténtalo de nuevo.'**
  String get profileSaveFailed;

  /// No description provided for @profileLegacyMigrated.
  ///
  /// In es, this message translates to:
  /// **'Encontramos el progreso y avatar anteriores. Se copiaron al perfil infantil; confirma o edita el nombre para continuar.'**
  String get profileLegacyMigrated;

  /// No description provided for @profileLegacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirma el perfil infantil'**
  String get profileLegacyTitle;

  /// No description provided for @profileConfirmName.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nombre'**
  String get profileConfirmName;

  /// No description provided for @profilePendingConfirmation.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de confirmación'**
  String get profilePendingConfirmation;

  /// No description provided for @profileRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get profileRetry;

  /// No description provided for @profileLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los perfiles. Revisa tu conexión e inténtalo de nuevo.'**
  String get profileLoadFailed;

  /// No description provided for @profileResetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Reiniciar el progreso?'**
  String get profileResetTitle;

  /// No description provided for @profileReset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar progreso'**
  String get profileReset;

  /// No description provided for @profileResetPrompt.
  ///
  /// In es, this message translates to:
  /// **'Se borrará el progreso de niveles de {name}. El avatar y sus monedas se conservarán. ¿Continuar?'**
  String profileResetPrompt(String name);

  /// No description provided for @profileResetDone.
  ///
  /// In es, this message translates to:
  /// **'Se reinició el progreso de {name}.'**
  String profileResetDone(String name);

  /// No description provided for @profileOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de la cuenta'**
  String get profileOpenSettings;

  /// No description provided for @profileOpenSettingsBody.
  ///
  /// In es, this message translates to:
  /// **'Tema, idioma, seguridad y privacidad.'**
  String get profileOpenSettingsBody;

  /// No description provided for @profileResetHint.
  ///
  /// In es, this message translates to:
  /// **'Borra estrellas y niveles sin tocar el avatar.'**
  String get profileResetHint;

  /// No description provided for @childSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de {name}'**
  String childSettingsTitle(String name);

  /// No description provided for @childSectionProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get childSectionProfile;

  /// No description provided for @childSectionLearning.
  ///
  /// In es, this message translates to:
  /// **'Aprendizaje'**
  String get childSectionLearning;

  /// No description provided for @childSectionDisplay.
  ///
  /// In es, this message translates to:
  /// **'Pantalla y accesibilidad'**
  String get childSectionDisplay;

  /// No description provided for @childSectionFeedback.
  ///
  /// In es, this message translates to:
  /// **'Sonido y vibración'**
  String get childSectionFeedback;

  /// No description provided for @childSectionReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get childSectionReminders;

  /// No description provided for @childEditName.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre del perfil'**
  String get childEditName;

  /// No description provided for @childSectionDanger.
  ///
  /// In es, this message translates to:
  /// **'Zona de peligro'**
  String get childSectionDanger;

  /// No description provided for @profileDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar perfil'**
  String get profileDelete;

  /// No description provided for @profileDeleteHint.
  ///
  /// In es, this message translates to:
  /// **'Elimina el perfil, su avatar y su progreso para siempre.'**
  String get profileDeleteHint;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {name}?'**
  String profileDeleteTitle(String name);

  /// No description provided for @profileDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará el perfil de {name}, incluyendo su avatar, ajustes y progreso. Esta acción no se puede deshacer.'**
  String profileDeleteBody(String name);

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar el perfil. Revisa tu conexión e inténtalo de nuevo.'**
  String get profileDeleteFailed;

  /// No description provided for @profileDeleteDone.
  ///
  /// In es, this message translates to:
  /// **'Se eliminó el perfil de {name}.'**
  String profileDeleteDone(String name);

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada correctamente.'**
  String get deleteAccountSuccess;
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
