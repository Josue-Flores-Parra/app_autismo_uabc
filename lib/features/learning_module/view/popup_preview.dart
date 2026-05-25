import 'dart:ui';

import 'package:flutter/material.dart';

import '../model/content_card_model.dart';
import 'preview_cards.dart';

class PopupPreview extends StatelessWidget {
  final ContentCardData content;
  final String launchLabel;
  final bool canLaunch;
  final VoidCallback onLaunch;
  final String? previewImageUrl;
  final String? videoPreviewPath;

  const PopupPreview({
    super.key,
    required this.content,
    required this.launchLabel,
    required this.canLaunch,
    required this.onLaunch,
    this.previewImageUrl,
    this.videoPreviewPath,
  });

  String get _typeLabel {
    switch (content.type) {
      case ContentType.pictogram:
        return 'PICTOGRAMA';
      case ContentType.video:
        return 'VIDEO';
      case ContentType.audio:
        return 'AUDIO';
      case ContentType.miniGame:
        return 'MINIJUEGO';
    }
  }

  // Helper para detectar casos específicos de minijuegos sin imagen de preview válida.
  bool get _isPuzzleMissingImage {
    if (content.type != ContentType.miniGame || content.miniGameType != 'puzzle') {
      return false;
    }
    final source = (previewImageUrl ?? content.imagePath).trim();
    return source.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxPopupHeight = (screenSize.height - 48).clamp(280.0, screenSize.height);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              // UX: en lugar de oscurecer el fondo, desenfocamos para
              // dirigir la atención al popup sin "apagar" el contexto visual.
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withAlpha(10)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: maxPopupHeight,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Contenedor intencionalmente transparente: la sensación
                    // de foco la produce el blur del fondo + bordes/sombra.
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x8CFFFFFF), width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isVideo = content.type == ContentType.video;
                      final minPreviewHeight = isVideo ? 170.0 : 140.0;
                      final maxPreviewHeight = isVideo ? 380.0 : 320.0;

                      // Reservar espacio para controles para que el preview se ajuste
                      // y no desborde en frames transitorios tras rotacion.
                      final controlsHeight =
                          56.0 + // boton cerrar
                          16.0 + // separador principal
                          56.0 + // boton de accion
                          (!canLaunch ? 24.0 : 0.0) +
                          (!isVideo ? 64.0 : 0.0);

                      final availablePreviewHeight =
                          (constraints.maxHeight - controlsHeight)
                              .clamp(minPreviewHeight, maxPreviewHeight);

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x66000000),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x55FFFFFF), width: 1),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: availablePreviewHeight,
                            child: _buildPopupPreviewBody(),
                          ),
                          if (!isVideo) ...[
                            const SizedBox(height: 16),
                            Text(
                              content.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: canLaunch ? onLaunch : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: content.type == ContentType.video
                                    ? const Color(0xFF5A97B8)
                                    : const Color(0xFF00E5FF),
                                disabledBackgroundColor: const Color(0x553A5160),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 10,
                                shadowColor: const Color.fromARGB(204, 0, 229, 255),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    content.type == ContentType.video
                                        ? Icons.play_circle_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      launchLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!canLaunch)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _isPuzzleMissingImage
                                    ? 'Imagen no disponible para este rompecabezas'
                                    : 'Actividad no disponible para este contenido.',
                                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupPreviewBody() {
    final videoPath = (videoPreviewPath ?? '').trim();
    if (content.type == ContentType.video && videoPath.isNotEmpty) {
      // Reusar el mismo flujo de preview de video para mantener
      // comportamiento visual, controles y lifecycle consistente con preview_cards.dart.
      return VideoPreviewCard(
        videoPath: videoPath,
        videoTitle: content.title,
        videoDesc: null,
        isPreview: true,
        isActive: true,
      );
    }

    return BasePreviewCard(
      isPreview: true,
      typeOfPreviewCard: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _PopupMediaWithTypeLabel(
                label: _typeLabel,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x001A3D52),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x997BA5C9),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.78, // escala ligeramente menor para que quede centrado dentro del marco decorativo
                        heightFactor: 0.78,
                        child: _buildPreviewImage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    // Para minijuegos usamos siempre la miniatura local dedicada.
    // Evita depender de miniGameType exacto y de rutas dinámicas inconsistentes.
    final source = (content.type == ContentType.miniGame)
        ? (content.miniGameType == 'simple_selection'
            ? 'assets/imgs/simple_selection_preview.png'
            : (previewImageUrl ?? content.imagePath).trim())
        : (previewImageUrl ?? content.imagePath).trim();
    if (source.isEmpty) {
      // Fallback explícito para recursos ausentes o no mapeados.
      return _buildPlaceholder();
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 72,
        color: Color(0xB3FFFFFF),
      ),
    );
  }
}

class _PopupMediaWithTypeLabel extends StatelessWidget {
  final Widget child;
  final String label;

  const _PopupMediaWithTypeLabel({
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: -11,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5B7A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
