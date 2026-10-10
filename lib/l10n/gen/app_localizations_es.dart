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
      'Se eliminará tu cuenta y los perfiles infantiles vinculados, incluidos sus avatares, progresos y métricas de uso. Escribe BORRAR para continuar.';

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
      'Para generar indicadores del desempeño educativo, Appy puede recopilar metricas seudonimizadas sobre el uso de actividades. Estos datos se asocian a un identificador de cuenta y no incluyen nombres ni correos electronicos.\nEsta recopilación es opcional. Puedes rechazarla sin perder acceso a las actividades y cambiar tu eleccion en cualquier momento desde las configuraciones';

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
    return 'Se eliminará el perfil de $name, incluyendo su avatar, ajustes, progreso y métricas de uso. Esta acción no se puede deshacer.';
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

  @override
  String get completionRewardsPending =>
      'Recompensas pendientes de sincronización.';

  @override
  String get completionSaveFailed =>
      'No se pudo guardar el resultado. Puedes volver e intentarlo de nuevo.';

  @override
  String get downloadsCancelling => 'Cancelando…';

  @override
  String get completionRewardsConfirmed => 'Recompensas sincronizadas.';

  @override
  String get completionRewardsLoading => 'Cargando recompensas';

  @override
  String get legalConsentTitle => 'Antes de continuar';

  @override
  String get legalConsentSubtitle =>
      'Lee y acepta los documentos que rigen el uso de Appy y el tratamiento de los datos personales.';

  @override
  String get legalConsentRead => 'Leído';

  @override
  String get legalConsentUnread => 'Sin leer';

  @override
  String get legalConsentSensitiveNote =>
      'Appy está dirigida al apoyo de personas con Trastorno del Espectro Autista. Por ello, el uso de la aplicación puede relacionarse con información sobre la salud de la persona menor de edad, considerada dato personal sensible. La legislación exige que el consentimiento se otorgue de forma expresa.';

  @override
  String get legalConsentCheckbox =>
      'He leído y acepto los Términos y Condiciones y el Aviso de Privacidad, y manifiesto que soy mayor de edad y que soy madre, padre o tutor legal de quien usará la aplicación.';

  @override
  String get legalConsentReadBothHint =>
      'Abre y lee ambos documentos para poder aceptar.';

  @override
  String get legalConsentDecline => 'No acepto';

  @override
  String get legalConsentAccept => 'Acepto';

  @override
  String get legalConsentSaveFailed =>
      'No se pudo registrar tu aceptación. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get legalConsentDeclineTitle => 'Continuar sin aceptar';

  @override
  String get legalConsentDeclineBody =>
      'Para usar Appy es necesario aceptar los Términos y Condiciones y el Aviso de Privacidad. Si prefieres no hacerlo ahora, cerraremos tu sesión y podrás volver cuando quieras.';

  @override
  String get legalConsentKeepReading => 'Seguir leyendo';

  @override
  String get verifyEmailTitle => 'Confirma tu correo';

  @override
  String verifyEmailBody(String email) {
    return 'Enviamos un enlace a $email. Ábrelo para confirmar que eres la persona adulta responsable de la cuenta. Este paso es necesario antes de que una niña o un niño use Appy.';
  }

  @override
  String get verifyEmailSpamHint =>
      'Si no lo ves, revisa la carpeta de correo no deseado.';

  @override
  String get verifyEmailConfirmed => 'Ya lo confirmé';

  @override
  String get verifyEmailResend => 'Reenviar correo';

  @override
  String verifyEmailResendIn(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get verifyEmailSent => 'Te enviamos un nuevo enlace.';

  @override
  String get verifyEmailSendFailed =>
      'No se pudo enviar el correo. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get verifyEmailNotYet =>
      'Todavía no vemos tu correo confirmado. Abre el enlace y vuelve a intentarlo.';
}
