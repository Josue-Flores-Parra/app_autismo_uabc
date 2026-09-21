import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/haptics_service.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../settings/viewmodel/settings_viewmodel.dart';
import '../data/legal_documents.dart';
import '../viewmodel/legal_viewmodel.dart';
import 'legal_document_screen.dart';
import 'legal_theme.dart';

/// Aceptación de los documentos legales antes de entrar a la app.
///
/// Se muestra cuando la cuenta no ha aceptado la versión vigente, ya sea
/// porque acaba de registrarse o porque solo aceptó una versión anterior.
///
/// Cada documento se abre y se lee por separado. La casilla de aceptación se
/// habilita cuando ambos se leyeron hasta el final, de modo que la constancia
/// refleje una lectura real y no un toque accidental.
class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({super.key});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _termsRead = false;
  bool _privacyRead = false;
  bool _accepted = false;
  bool _isSaving = false;

  bool get _bothRead => _termsRead && _privacyRead;
  bool get _canAccept => _bothRead && _accepted && !_isSaving;

  Future<void> _openDocument(LegalDocument document, bool isTerms) async {
    HapticsService.selection();
    final leido = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LegalDocumentScreen(document: document, trackReading: true),
      ),
    );

    if (leido != true || !mounted) return;
    setState(() {
      if (isTerms) {
        _termsRead = true;
      } else {
        _privacyRead = true;
      }
    });
  }

  Future<void> _accept() async {
    if (!_canAccept) return;
    HapticsService.success();
    setState(() => _isSaving = true);

    final saved = await context.read<LegalViewModel>().accept();
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo registrar tu aceptación. Revisa tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _decline() async {
    HapticsService.selection();
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LegalPalette.paper,
        surfaceTintColor: LegalPalette.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Continuar sin aceptar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: LegalPalette.ink,
          ),
        ),
        content: const Text(
          'Para usar Appy es necesario aceptar los Términos y Condiciones y el '
          'Aviso de Privacidad. Si prefieres no hacerlo ahora, cerraremos tu '
          'sesión y podrás volver cuando quieras.',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            color: LegalPalette.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: LegalPalette.inkSoft),
            child: const Text('Seguir leyendo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (salir != true || !mounted) return;
    context.read<LegalViewModel>().reset();
    await context.read<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<SettingsViewModel>().locale.languageCode;
    final terms = termsOfUse(locale);
    final privacy = privacyNotice(locale);

    return PopScope(
      // No se puede esquivar con el botón atrás: o se acepta, o se cierra sesión.
      canPop: false,
      child: Scaffold(
        backgroundColor: LegalPalette.paper,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: LegalPalette.rule,
                    ),
                    _buildDocumentRow(
                      title: terms.shortTitle,
                      read: _termsRead,
                      onTap: () => _openDocument(terms, true),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: LegalPalette.rule,
                    ),
                    _buildDocumentRow(
                      title: privacy.shortTitle,
                      read: _privacyRead,
                      onTap: () => _openDocument(privacy, false),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: LegalPalette.rule,
                    ),
                    const SizedBox(height: 24),
                    _buildConsentNote(),
                    const SizedBox(height: 20),
                    _buildCheckbox(),
                  ],
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 52, height: 52),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Antes de continuar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: LegalPalette.ink,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Lee y acepta los documentos que rigen el uso de Appy y el '
                'tratamiento de los datos personales.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: LegalPalette.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentRow({
    required String title,
    required bool read,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: LegalPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    read ? 'Leído' : 'Sin leer',
                    style: TextStyle(
                      fontSize: 13,
                      color: read ? LegalPalette.brand : LegalPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (read)
              const Icon(Icons.check, size: 20, color: LegalPalette.brand)
            else
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: LegalPalette.inkSoft,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentNote() {
    return const Text(
      'Appy está dirigida al apoyo de personas con Trastorno del Espectro '
      'Autista. Por ello, el uso de la aplicación puede relacionarse con '
      'información sobre la salud de la persona menor de edad, considerada dato '
      'personal sensible. La legislación exige que el consentimiento se otorgue '
      'de forma expresa.',
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: LegalPalette.inkSoft,
      ),
    );
  }

  Widget _buildCheckbox() {
    return InkWell(
      onTap: _bothRead
          ? () {
              HapticsService.selection();
              setState(() => _accepted = !_accepted);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _accepted,
                onChanged: _bothRead
                    ? (value) {
                        HapticsService.selection();
                        setState(() => _accepted = value ?? false);
                      }
                    : null,
                activeColor: LegalPalette.brand,
                side: const BorderSide(color: LegalPalette.inkSoft, width: 1.6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'He leído y acepto los Términos y Condiciones y el Aviso de '
                'Privacidad, y manifiesto que soy mayor de edad y que soy madre, '
                'padre o tutor legal de quien usará la aplicación.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: _bothRead ? LegalPalette.ink : LegalPalette.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        color: LegalPalette.paper,
        border: Border(top: BorderSide(color: LegalPalette.rule)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_bothRead)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Abre y lee ambos documentos para poder aceptar.',
                style: TextStyle(fontSize: 13, color: LegalPalette.inkSoft),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSaving ? null : _decline,
                  style: TextButton.styleFrom(
                    foregroundColor: LegalPalette.inkSoft,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'No acepto',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canAccept ? _accept : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: LegalPalette.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: LegalPalette.rule,
                    disabledForegroundColor: LegalPalette.inkSoft,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Acepto',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
