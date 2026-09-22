import 'package:flutter/material.dart';

import '../data/legal_documents.dart';
import 'legal_document_view.dart';
import 'legal_theme.dart';

/// Lectura de un documento legal a pantalla completa.
///
/// Se usa tanto desde Ajustes como desde el flujo de aceptación. En este
/// segundo caso devuelve `true` al cerrarse si el documento se leyó completo.
class LegalDocumentScreen extends StatefulWidget {
  final LegalDocument document;

  /// Cuando es `true`, la pantalla avisa al cerrarse si se llegó al final.
  final bool trackReading;

  const LegalDocumentScreen({
    super.key,
    required this.document,
    this.trackReading = false,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool _reachedEnd = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_reachedEnd);
      },
      child: Scaffold(
        backgroundColor: LegalPalette.paper,
        appBar: AppBar(
          backgroundColor: LegalPalette.paper,
          surfaceTintColor: LegalPalette.paper,
          foregroundColor: LegalPalette.ink,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: LegalPalette.rule,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_reachedEnd),
          ),
          title: Text(
            widget.document.shortTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LegalPalette.ink,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: LegalPalette.rule),
          ),
        ),
        body: SafeArea(
          child: LegalDocumentView(
            document: widget.document,
            onReachedEnd: widget.trackReading
                ? () {
                    if (!mounted || _reachedEnd) return;
                    setState(() => _reachedEnd = true);
                  }
                : null,
          ),
        ),
        bottomNavigationBar: widget.trackReading ? _buildReadingBar() : null,
      ),
    );
  }

  Widget _buildReadingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: LegalPalette.paper,
        border: Border(top: BorderSide(color: LegalPalette.rule)),
      ),
      child: SafeArea(
        top: false,
        child: _reachedEnd
            ? SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: LegalPalette.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Listo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : const Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: LegalPalette.inkSoft,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Desplázate hasta el final del documento para continuar.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: LegalPalette.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
