import 'package:shared_preferences/shared_preferences.dart';

/// Servicio simple para guardar y leer el PIN de ajustes.
/// Se guarda en SharedPreferences bajo la llave `settingsPin_<uid>`, de modo
/// que el PIN no se comparte entre cuentas del mismo dispositivo.
class PinService {
  static const _legacyPinKey = 'settingsPin';

  static String _pinKey(String uid) => 'settingsPin_$uid';

  static Future<String?> getPin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    // La llave global anterior no identifica al dueño del PIN, así que se
    // descarta en lugar de heredarla a la cuenta que abra Ajustes primero.
    if (prefs.containsKey(_legacyPinKey)) {
      await prefs.remove(_legacyPinKey);
    }
    return prefs.getString(_pinKey(uid));
  }

  static Future<void> setPin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey(uid), pin);
  }

  static Future<void> clearPin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey(uid));
  }
}
