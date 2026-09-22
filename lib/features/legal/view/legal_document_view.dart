import 'package:flutter/material.dart';

import '../data/legal_documents.dart';
import 'legal_theme.dart';

/// Render de un documento legal sobre papel blanco.
///
/// Se comparte entre la lectura desde Ajustes y la del flujo de aceptación,
/// para que el texto se vea igual en ambos casos.
class LegalDocumentView extends StatefulWidget {
  final LegalDocument document;

  /// Se invoca la primera vez que el documento se desplaza hasta el final.
  /// Un documento que cabe completo en pantalla lo invoca tras el primer frame.
  final VoidCallback? onReachedEnd;

  const LegalDocumentView({
    super.key,
    required this.document,
    this.onReachedEnd,
  });

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  final ScrollController _controller = ScrollController();
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    if (widget.onReachedEnd == null) return;
    _controller.addListener(_checkEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkEnd() {
    if (_reported || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;

    final llegoAlFinal =
        position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 24;
    if (!llegoAlFinal) return;

    _reported = true;
    widget.onReachedEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.document.blocks;

    return Scrollbar(
      controller: _controller,
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        itemCount: blocks.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _buildMasthead();
          if (index == blocks.length + 1) return _buildColophon();
          return _buildBlock(blocks[index - 1]);
        },
      ),
    );
  }

  Widget _buildMasthead() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.document.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: LegalPalette.ink,
              letterSpacing: 0.6,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última actualización: ${widget.document.lastUpdated}',
            style: const TextStyle(fontSize: 12.5, color: LegalPalette.inkSoft),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1, color: LegalPalette.rule),
        ],
      ),
    );
  }

  Widget _buildColophon() {
    return const Padding(
      padding: EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, thickness: 1, color: LegalPalette.rule),
          SizedBox(height: 14),
          Text(
            'Fin del documento.',
            style: TextStyle(fontSize: 12.5, color: LegalPalette.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(LegalBlock block) {
    switch (block.type) {
      case LegalBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 10),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: LegalPalette.brand,
              height: 1.35,
            ),
          ),
        );

      case LegalBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Text(
            block.text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.62,
              color: LegalPalette.ink,
            ),
          ),
        );

      case LegalBlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 11, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 10),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.62,
                    color: LegalPalette.inkSoft,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.62,
                    color: LegalPalette.ink,
                  ),
                ),
              ),
            ],
          ),
        );

      case LegalBlockType.note:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            color: LegalPalette.surface,
            border: Border(
              left: BorderSide(color: LegalPalette.brand, width: 3),
            ),
          ),
          child: Text(
            block.text,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: LegalPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}
