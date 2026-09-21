import 'package:flutter/services.dart';

import 'feedback_preferences.dart';

/// Vibracion de apoyo para abrir/cerrar elementos y confirmar respuestas.
/// Respeta el switch "Feedback haptico" de Ajustes via [FeedbackPreferences].
class HapticsService {
  /// Apertura y cierre de popups, dialogos y paneles.
  static void selection() {
    if (!FeedbackPreferences.hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Confirmacion de una accion correcta.
  static void success() {
    if (!FeedbackPreferences.hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Aviso de accion incorrecta o bloqueada.
  static void warning() {
    if (!FeedbackPreferences.hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }
}
