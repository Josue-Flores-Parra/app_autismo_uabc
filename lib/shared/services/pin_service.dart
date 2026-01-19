import 'package:shared_preferences/shared_preferences.dart';

/// Servicio simple para guardar y leer el PIN de ajustes.
/// Se guarda en SharedPreferences bajo la llave 'settingsPin'.
class PinService {
  static const _pinKey = 'settingsPin';

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }
}

