import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda si el dispositivo ya vio la bienvenida.
///
/// Se guarda por dispositivo y no por cuenta porque se muestra antes de
/// iniciar sesion, cuando todavia no hay usuario.
class OnboardingService {
  static const _seenKey = 'onboardingSeen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
