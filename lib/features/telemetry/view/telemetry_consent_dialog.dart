import 'package:flutter/material.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Diálogo de consentimiento de telemetría que se muestra inmediatamente
/// después de crear la cuenta por primera vez.
///
/// Devuelve `true` si el usuario acepta el envío de métricas anónimas,
/// `false` si lo rechaza. No es dismissible (el usuario debe elegir).
Future<bool> showTelemetryConsentDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1A3D52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.insights, color: Color(0xFF00E5FF), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n?.telemetryConsentTitle ?? 'Ayúdanos a mejorar',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        l10n?.telemetryConsentBody ??
            'Para mejorar la experiencia, Appy puede enviar métricas anónimas '
                'sobre el uso de las actividades. No se envían datos personales '
                'y puedes revisarlo cuando quieras en Ajustes.',
        style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            l10n?.telemetryConsentDecline ?? 'No, gracias',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF05E995),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            l10n?.telemetryConsentAccept ?? 'Aceptar',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return accepted ?? false;
}