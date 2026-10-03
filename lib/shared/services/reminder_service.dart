import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Texto de un recordatorio, ya traducido al idioma de la app.
class ReminderMessage {
  const ReminderMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Lo que necesitan los perfiles para programar recordatorios de práctica.
/// Se separa del plugin para poder probar la lógica sin el sistema.
abstract class ReminderScheduler {
  /// Pide el permiso de notificaciones. `true` si se puede avisar al usuario.
  Future<bool> requestPermission();

  /// Programa un aviso diario a las [time] (`HH:mm`) para el perfil.
  Future<void> scheduleDaily({
    required String learnerId,
    required String time,
    required ReminderMessage message,
  });

  /// Quita el aviso del perfil.
  Future<void> cancel(String learnerId);
}

/// Recordatorios diarios con notificaciones locales.
///
/// Cada perfil infantil tiene su propio aviso, con un identificador derivado
/// de su id. El aviso se repite todos los días a la misma hora local y el
/// plugin lo reprograma solo tras reiniciar el teléfono. Se usa la entrega
/// inexacta, que no requiere el permiso de alarmas exactas: un recordatorio
/// de práctica no necesita llegar al minuto.
class ReminderService implements ReminderScheduler {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Instancia de la app.
  static final ReminderService instance = ReminderService();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const String _channelId = 'practice_reminders';
  static const String _channelName = 'Recordatorios de práctica';
  static const String _channelDescription =
      'Aviso diario para practicar con Appy';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Sin zona horaria local, el aviso saldría en hora UTC.
      debugPrint('ReminderService: zona horaria local no disponible: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? true;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: false,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }

  @override
  Future<void> scheduleDaily({
    required String learnerId,
    required String time,
    required ReminderMessage message,
  }) async {
    await _ensureReady();
    final parsed = parseReminderTime(time);
    await _plugin.zonedSchedule(
      id: reminderIdFor(learnerId),
      title: message.title,
      body: message.body,
      scheduledDate: nextReminderMoment(
        tz.TZDateTime.now(tz.local),
        parsed.hour,
        parsed.minute,
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(String learnerId) async {
    await _ensureReady();
    await _plugin.cancel(id: reminderIdFor(learnerId));
  }

  /// Identificador estable de la notificación de un perfil. Debe caber en un
  /// entero de 32 bits con signo, que es lo que acepta el sistema.
  @visibleForTesting
  static int reminderIdFor(String learnerId) {
    var hash = 0x811c9dc5;
    for (final unit in learnerId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  /// Lee una hora `HH:mm`. Si el valor no es válido usa las 18:00.
  @visibleForTesting
  static ({int hour, int minute}) parseReminderTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return (hour: hour, minute: minute);
      }
    }
    return (hour: 18, minute: 0);
  }

  /// Próxima vez que [hour]:[minute] ocurre después de [now]: hoy si todavía
  /// no pasó, y si no, mañana.
  @visibleForTesting
  static tz.TZDateTime nextReminderMoment(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    final today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (today.isAfter(now)) return today;
    return tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
}
