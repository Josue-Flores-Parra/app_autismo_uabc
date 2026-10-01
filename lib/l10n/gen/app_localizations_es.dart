// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Appy';

  @override
  String get appTagline => 'TEApoya TEAcompaña';

  @override
  String get navModules => 'Módulos';

  @override
  String get navAvatar => 'Avatar';

  @override
  String get navSettings => 'PIN';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get profileSectionTitle => 'Perfil de usuario';

  @override
  String get displayNameLabel => 'Nombre para mostrar';

  @override
  String get editDisplayName => 'Editar nombre';

  @override
  String get changeAvatar => 'Cambiar avatar';

  @override
  String get emailLabel => 'Correo';

  @override
  String get accountSecuritySection => 'Cuenta y seguridad';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirmTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountConfirmBody =>
      'Se eliminará tu cuenta y los perfiles infantiles vinculados, incluidos sus avatares y progresos. Las métricas anónimas ya enviadas no se pueden eliminar. Escribe BORRAR para continuar.';

  @override
  String get deleteAccountConfirmAction => 'BORRAR';

  @override
  String get languageSection => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get fontSizeLabel => 'Tamaño de fuente';

  @override
  String get fontSmall => 'Pequeño';

  @override
  String get fontMedium => 'Medio';

  @override
  String get fontLarge => 'Grande';

  @override
  String get accessibilitySection => 'Accesibilidad';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get reduceAnimations => 'Reducir animaciones';

  @override
  String get audioFeedback => 'Feedback auditivo';

  @override
  String get hapticFeedback => 'Feedback háptico';

  @override
  String get notificationsSection => 'Notificaciones y recordatorios';

  @override
  String get enableReminders => 'Activar recordatorios de práctica';

  @override
  String get scheduleReminder => 'Horario sugerido';

  @override
  String get reminderPlaceholder =>
      'Activa los recordatorios para elegir la hora';

  @override
  String reminderDailyAt(String time) {
    return 'Todos los días a las $time';
  }

  @override
  String get reminderNotificationTitle => 'Hora de practicar con Appy';

  @override
  String get reminderNotificationBody => 'Hay actividades esperándote.';

  @override
  String get reminderPermissionDenied =>
      'Activa las notificaciones de Appy en los ajustes del teléfono para recibir recordatorios.';

  @override
  String get privacySection => 'Privacidad y datos';

  @override
  String get clearCache => 'Limpiar caché de recursos';

  @override
  String get sendMetrics => 'Enviar métricas anónimas';

  @override
  String get telemetryConsentTitle => 'Ayúdanos a mejorar';

  @override
  String get telemetryConsentBody =>
      'Para mejorar la experiencia, Appy puede enviar métricas anónimas sobre el uso de las actividades. No se envían datos personales y puedes revisarlo cuando quieras en Ajustes.';

  @override
  String get telemetryConsentAccept => 'Aceptar';

  @override
  String get telemetryConsentDecline => 'No, gracias';

  @override
  String get parentalSection => 'Control parental';

  @override
  String get parentalAllowedModules => 'Módulos permitidos';

  @override
  String get parentalNoLimit => 'Todos';

  @override
  String get profileOpenAllLevels => 'Abrir todos los niveles';

  @override
  String get profileOpenAllLevelsHint =>
      'Muestra abiertos todos los niveles de los módulos permitidos. Las monedas y estrellas solo se ganan al completar cada actividad.';

  @override
  String get openLevelsActive => 'Modo libre';

  @override
  String get downloadsTitle => 'Contenido sin conexión';

  @override
  String get downloadsIntro =>
      'Descarga un módulo para usarlo sin internet. Para descargar necesitas conexión. El progreso se guarda y se envía cuando vuelve la red.';

  @override
  String get downloadsEmpty => 'Aún no hay módulos para descargar.';

  @override
  String get downloadsNotDownloaded => 'Sin descargar';

  @override
  String get downloadsPartial => 'Descarga incompleta';

  @override
  String downloadsDownloaded(String size) {
    return 'Descargado, $size';
  }

  @override
  String downloadsInProgress(int done, int total) {
    return 'Descargando $done de $total';
  }

  @override
  String get downloadsAction => 'Descargar';

  @override
  String get downloadsRetry => 'Reintentar';

  @override
  String get downloadsDeleteTooltip => 'Borrar descarga';

  @override
  String get downloadsDeleteTitle => '¿Borrar la descarga?';

  @override
  String get downloadsDeleteBody =>
      'Se libera el espacio del teléfono. Puedes volver a descargarlo cuando quieras.';

  @override
  String get downloadsErrorNetwork =>
      'No se pudo descargar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get downloadsErrorNoSpace =>
      'No hay espacio suficiente en el teléfono.';

  @override
  String get downloadsErrorOther => 'No se pudo completar la descarga.';

  @override
  String get parentalModulesUnit => 'módulos';

  @override
  String get currentPasswordLabel => 'Contraseña de la cuenta';

  @override
  String get newPasswordLabel => 'Contraseña nueva';

  @override
  String get infoSection => 'Información y soporte';

  @override
  String get appVersion => 'Versión de la app';

  @override
  String get termsPrivacy => 'Términos y Privacidad';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get feedbackSupport => 'Enviar feedback / soporte';

  @override
  String get savedSnackbar => 'Ajustes actualizados';

  @override
  String get errorSnackbar => 'Ocurrió un problema';

  @override
  String get cacheClearedSnackbar => 'Caché limpiada';

  @override
  String get logoutSuccess => 'Sesión cerrada';

  @override
  String get passwordUpdated => 'Contraseña actualizada';

  @override
  String get displayNameUpdated => 'Nombre actualizado';

  @override
  String get deleteAccountFailed => 'No se pudo eliminar la cuenta';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get profileHubTitle => 'Perfiles de la familia';

  @override
  String get profileHubBody =>
      'Elige un perfil para comenzar o edita sus ajustes.';

  @override
  String get profileWelcomeTitle => '¡Vamos a empezar!';

  @override
  String get profileWelcomeBody =>
      'Crea el primer perfil para guardar el aprendizaje y el avatar de forma independiente.';

  @override
  String get profileAddTitle => 'Agregar perfil infantil';

  @override
  String get profileAddFirst => 'Crear primer perfil';

  @override
  String get profileNameLabel => 'Nombre del perfil';

  @override
  String get profileManageTitle => 'Perfiles infantiles';

  @override
  String get profileManageBody =>
      'Cada perfil guarda su propio progreso, avatar, ajustes y límite de módulos.';

  @override
  String get profileEdit => 'Editar perfil';

  @override
  String get profileAllowedModules => 'Límite de módulos';

  @override
  String get profileSaveFailed =>
      'No se pudo guardar el perfil. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get profileLegacyMigrated =>
      'Encontramos el progreso y avatar anteriores. Se copiaron al perfil infantil; confirma o edita el nombre para continuar.';

  @override
  String get profileLegacyTitle => 'Confirma el perfil infantil';

  @override
  String get profileConfirmName => 'Confirmar nombre';

  @override
  String get profilePendingConfirmation => 'Pendiente de confirmación';

  @override
  String get profileRetry => 'Reintentar';

  @override
  String get profileLoadFailed =>
      'No se pudieron cargar los perfiles. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get profileResetTitle => '¿Reiniciar el progreso?';

  @override
  String get profileReset => 'Reiniciar progreso';

  @override
  String profileResetPrompt(String name) {
    return 'Se borrará el progreso de niveles de $name. El avatar y sus monedas se conservarán. ¿Continuar?';
  }

  @override
  String profileResetDone(String name) {
    return 'Se reinició el progreso de $name.';
  }

  @override
  String get profileOpenSettings => 'Ajustes de la cuenta';

  @override
  String get profileOpenSettingsBody => 'Tema, idioma, seguridad y privacidad.';

  @override
  String get profileResetHint =>
      'Borra estrellas y niveles sin tocar el avatar.';

  @override
  String childSettingsTitle(String name) {
    return 'Ajustes de $name';
  }

  @override
  String get childSectionProfile => 'Perfil';

  @override
  String get childSectionLearning => 'Aprendizaje';

  @override
  String get childSectionDisplay => 'Pantalla y accesibilidad';

  @override
  String get childSectionFeedback => 'Sonido y vibración';

  @override
  String get childSectionReminders => 'Recordatorios';

  @override
  String get childEditName => 'Cambiar nombre del perfil';

  @override
  String get childSectionDanger => 'Zona de peligro';

  @override
  String get profileDelete => 'Eliminar perfil';

  @override
  String get profileDeleteHint =>
      'Elimina el perfil, su avatar y su progreso para siempre.';

  @override
  String profileDeleteTitle(String name) {
    return '¿Eliminar a $name?';
  }

  @override
  String profileDeleteBody(String name) {
    return 'Se eliminará el perfil de $name, incluyendo su avatar, ajustes y progreso. Esta acción no se puede deshacer.';
  }

  @override
  String get profileDeleteConfirm => 'Eliminar';

  @override
  String get profileDeleteFailed =>
      'No se pudo eliminar el perfil. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String profileDeleteDone(String name) {
    return 'Se eliminó el perfil de $name.';
  }

  @override
  String get deleteAccountSuccess => 'Cuenta eliminada correctamente.';
}
