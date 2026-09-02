import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'radial_focus_preview_selector.dart';
import 'level_play_screen.dart';
import 'popup_preview.dart';
import '../model/content_card_model.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../data/video_controller_manager.dart';

class LevelContentPreviewScreen extends StatefulWidget {
  final String levelName;
  final String? bgLevelImg;
  final List<ContentCardData> contents;

  // Parámetros opcionales para el minijuego (cuando se presiona "JUGAR")
  final Map<String, dynamic>? minigameData;
  final String? actividadType;
  final String? levelId;
  final String? moduleId;
  final String? levelTitle;

  /// URL del video para niveles de tipo 'video' (desde Firebase Storage)
  final String? videoUrl;

  const LevelContentPreviewScreen({
    super.key,
    required this.levelName,
    this.bgLevelImg,
    required this.contents,
    this.minigameData,
    this.actividadType,
    this.levelId,
    this.moduleId,
    this.levelTitle,
    this.videoUrl,
  });

  @override
  State<LevelContentPreviewScreen> createState() =>
      _LevelContentPreviewScreenState();
}

class _LevelContentPreviewScreenState extends State<LevelContentPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedCarouselIndex = 0;
  bool _isCarouselDragging =
      false; // Flag necesario en radial_focus_preview_selector para controlar hints de scroll
  // Cache en memoria por pantalla: retenemos los videos que el usuario ya
  // visitó/previsualizó para que al volver no reinicie el buffer desde cero.
  // Se libera completo en dispose para evitar fugas de memoria entre pantallas.
  final Set<String> _retainedPreloadedVideoPaths = <String>{};

  bool get _isSimpleSelectionEnabled {
    return _asBool(widget.minigameData?['isSimpleSelectionEnabled']);
  }

  ContentCardData? get _selectedContent {
    if (widget.contents.isEmpty) return null;
    final safeIndex = _selectedCarouselIndex.clamp(
      0,
      widget.contents.length - 1,
    );
    return widget.contents[safeIndex];
  }

  // Decisión de producto:
  // El botón principal "JUGAR" resuelve en runtime qué actividad abrir según
  // la tarjeta actualmente seleccionada en el carrusel. No dependemos del
  // `actividadType` ya que esta solo define la actividad inicial.
  bool get _canPlaySelectedContent {
    final selected = _selectedContent;
    if (selected == null) return false;

    switch (selected.type) {
      case ContentType.video:
        final hasVideo =
            (selected.videoPath?.isNotEmpty == true) ||
            (widget.videoUrl?.isNotEmpty == true) ||
            ((widget.minigameData?['videoUrl'] as String?)?.isNotEmpty ==
                true) ||
            ((widget.minigameData?['url'] as String?)?.isNotEmpty == true);
        return hasVideo;
      case ContentType.pictogram:
      case ContentType.audio:
        return widget.minigameData != null;
      case ContentType.miniGame:
        if (selected.miniGameType == 'simple_selection') {
          return _isSimpleSelectionEnabled && widget.minigameData != null;
        }
        if (selected.miniGameType == 'puzzle') {
          final puzzleUrl = widget.minigameData?['puzzleImageUrl'] as String?;
          final fallbackUrl = widget.minigameData?['pictogramaUrl'] as String?;
          final hasPuzzleImage =
              (puzzleUrl != null && puzzleUrl.trim().isNotEmpty) ||
              (fallbackUrl != null && fallbackUrl.trim().isNotEmpty);
          return hasPuzzleImage;
        }
        return false;
    }
  }

  String? get _selectedActivityType {
    final selected = _selectedContent;
    if (selected == null) return null;

    switch (selected.type) {
      case ContentType.video:
        return 'video';
      case ContentType.pictogram:
        return 'pictogram';
      case ContentType.audio:
        return 'audio';
      case ContentType.miniGame:
        return selected.miniGameType;
    }
  }

  String get _selectedLaunchLabel {
    return _selectedActivityType == 'video' ? 'VER VIDEO' : 'JUGAR';
  }

  String? get _selectedPreviewImageUrl {
    final selected = _selectedContent;
    if (selected == null) return null;

    if (selected.imagePath.trim().isNotEmpty) {
      return selected.imagePath;
    }
    if (selected.type == ContentType.miniGame &&
        selected.miniGameType == 'puzzle') {
      final puzzleUrl = widget.minigameData?['puzzleImageUrl'] as String?;
      if (puzzleUrl != null && puzzleUrl.trim().isNotEmpty) return puzzleUrl;
      final fallbackUrl = widget.minigameData?['pictogramaUrl'] as String?;
      return fallbackUrl;
    }

    final minigameImage = widget.minigameData?['pictogramaUrl'] as String?;
    return minigameImage;
  }

  String? get _selectedVideoPreviewPath {
    final selected = _selectedContent;
    if (selected == null || selected.type != ContentType.video) return null;

    final fromCard = selected.videoPath;
    if (fromCard != null && fromCard.isNotEmpty) return fromCard;

    final fromVideoUrl = widget.videoUrl;
    if (fromVideoUrl != null && fromVideoUrl.isNotEmpty) return fromVideoUrl;

    final fromMinigameVideo = widget.minigameData?['videoUrl'] as String?;
    if (fromMinigameVideo != null && fromMinigameVideo.isNotEmpty) {
      return fromMinigameVideo;
    }

    final fromMinigameUrl = widget.minigameData?['url'] as String?;
    if (fromMinigameUrl != null && fromMinigameUrl.isNotEmpty) {
      return fromMinigameUrl;
    }

    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
    _preloadSelectedVideoInBackground();
  }

  @override
  void dispose() {
    _releaseRetainedPreloadedVideos();
    _animController.dispose();
    super.dispose();
  }

  void _releaseRetainedPreloadedVideos() {
    if (_retainedPreloadedVideoPaths.isEmpty) return;

    final manager = VideoControllerManager();
    // Liberación simétrica: cada retain realizado con getOrCreateController
    // se devuelve aquí con releaseController.
    for (final path in _retainedPreloadedVideoPaths) {
      manager.releaseController(path);
    }
    _retainedPreloadedVideoPaths.clear();
  }

  void _preloadSelectedVideoInBackground() {
    final selectedPath = _selectedVideoPreviewPath;
    if (selectedPath == null || selectedPath.isEmpty) return;

    // Si ya fue retenido antes en esta pantalla, no duplicamos referencias.
    if (_retainedPreloadedVideoPaths.contains(selectedPath)) return;

    final manager = VideoControllerManager();

    // Retener + inicializar en segundo plano:
    // - Retener evita que cerrar popup/desenfocar nodo destruya el controller.
    // - Inicializar por adelantado reduce tiempo de espera al abrir preview.
    manager.getOrCreateController(selectedPath);
    _retainedPreloadedVideoPaths.add(selectedPath);

    manager.initializeController(selectedPath).catchError((_) {
      // La UI del popup ya tiene fallback de error; no interrumpimos el flujo.
    });
  }

  Future<void> _openSelectedPreviewFlow() async {
    final selected = _selectedContent;
    final activityType = _selectedActivityType;
    if (activityType == null || selected == null || !_canPlaySelectedContent)
      return;

    final shouldLaunch = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      // Flujo en dos pasos:
      // 1) Mostrar popup de vista previa (sin iniciar actividad)
      // 2) Iniciar actividad solo si usuario confirma con botón dinámico
      builder: (dialogContext) => PopupPreview(
        content: selected,
        launchLabel: _selectedLaunchLabel,
        canLaunch: _canPlaySelectedContent,
        previewImageUrl: _selectedPreviewImageUrl,
        videoPreviewPath: _selectedVideoPreviewPath,
        onLaunch: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    if (shouldLaunch != true || !mounted) {
      return;
    }

    // Para el rompecabezas se pide elegir la dificultad antes de entrar.
    int? puzzleGridSize;
    if (activityType == 'puzzle') {
      puzzleGridSize = await _showPuzzleDifficultyDialog();
      if (puzzleGridSize == null || !mounted) return;
    }

    // Inyectar la dificultad elegida en los datos del minijuego.
    final data = Map<String, dynamic>.from(widget.minigameData ?? const {});
    if (puzzleGridSize != null) {
      data['gridSize'] = puzzleGridSize;
    }

    // La actividad real inicia únicamente después de la
    // confirmación del popup (no al abrir la vista previa).
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelPlayScreen(
          levelTitle: widget.levelTitle ?? widget.levelName,
          minigameData: data,
          actividadType: activityType,
          levelId: widget.levelId ?? '',
          moduleId: widget.moduleId ?? '',
          videoUrl: widget.videoUrl,
          launchSimpleSelectionFromCard: activityType == 'simple_selection',
        ),
      ),
    );
    if (!mounted) return;

    // Recargar datos después de regresar
    if (widget.moduleId != null) {
      final learningViewModel = context.read<LearningViewModel>();
      await learningViewModel.getModuleLevels(
        widget.moduleId!,
        forceReload: true,
      );
    }
  }

  void _onFocusedNodePressed(int _) {
    _openSelectedPreviewFlow();
  }

  // Muestra el diálogo de selección de dificultad del rompecabezas.
  // Devuelve el tamaño de cuadrícula elegido (2/4/5/6) o null si se cancela.
  Future<int?> _showPuzzleDifficultyDialog() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        int selectedGrid = 3;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A3D52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.extension, color: Color(0xFF00E5FF), size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Elige la dificultad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDifficultyOption(
                    value: 3,
                    groupValue: selectedGrid,
                    title: 'Muy Fácil',
                    subtitle: '9 piezas',
                    onChanged: (v) => setDialogState(() => selectedGrid = v),
                  ),
                  _buildDifficultyOption(
                    value: 4,
                    groupValue: selectedGrid,
                    title: 'Fácil',
                    subtitle: '16 piezas',
                    onChanged: (v) => setDialogState(() => selectedGrid = v),
                  ),
                  _buildDifficultyOption(
                    value: 5,
                    groupValue: selectedGrid,
                    title: 'Normal',
                    subtitle: '25 piezas',
                    onChanged: (v) => setDialogState(() => selectedGrid = v),
                  ),
                  _buildDifficultyOption(
                    value: 6,
                    groupValue: selectedGrid,
                    title: 'Difícil',
                    subtitle: '36 piezas',
                    onChanged: (v) => setDialogState(() => selectedGrid = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedGrid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05E995),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Empezar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Construye una opción de dificultad como radio button.
  Widget _buildDifficultyOption({
    required int value,
    required int groupValue,
    required String title,
    required String subtitle,
    required ValueChanged<int> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF05E995),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF20D3B52), Color(0xFF091F2C)],
          ),
        ),
        child: Stack(
          children: [
            if (widget.bgLevelImg != null && widget.bgLevelImg!.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: _buildImageFromUrl(
                    widget.bgLevelImg!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),

                  // Hint anclado al flujo de la pantalla (debajo del label superior)
                  // para evitar desalineaciones por escalas/densidades distintas.
                  RadialScrollHint(isDragging: _isCarouselDragging),

                  const SizedBox(height: 12),

                  Expanded(
                    child: FadeTransition(
                      opacity: _animController,
                      child: _buildCarousel(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // El botón usa la tarjeta seleccionada para decidir qué actividad abrir.
                  // Así el usuario controla la actividad desde el carrusel + botón principal.
                  if (_canPlaySelectedContent)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _openSelectedPreviewFlow,
                        icon: Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        label: const Text(
                          'VISTA PREVIA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF92C5BC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                          shadowColor: const Color.fromARGB(180, 170, 163, 163),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila con botón de regreso y título
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Botón de regreso - centrado verticalmente
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  // Mueve el botón un poco más abajo
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x4DFFFFFF),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Título del nivel (centrado)
              Expanded(
                child: Center(
                  child: Text(
                    widget.levelName,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                      height:
                          1.2, // Ajustar altura de línea para mejor alineación
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Espaciador para balancear el botón de regreso (mismo ancho que el botón + padding)
              const SizedBox(width: 52),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Desliza para explorar',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xCCFFFFFF),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Construye el carrusel de tarjetas de contenido usando el nuevo widget radial personalizado.
  Widget _buildCarousel() {
    void onIndexChanged(int index) {
      if (_selectedCarouselIndex == index) return;
      setState(() {
        _selectedCarouselIndex = index;
      });
      // Al cambiar de nodo, precargamos el video seleccionado (si aplica)
      // para mantener respuesta fluida del popup de preview.
      _preloadSelectedVideoInBackground();
    }

    return RadialFocusPreviewSelector(
      contents: widget.contents,
      initialIndex: _selectedCarouselIndex,
      onIndexChanged: onIndexChanged,
      onFocusedNodePressed: _onFocusedNodePressed,
      onDragStateChanged: (isDragging) {
        if (_isCarouselDragging == isDragging) return;
        setState(() {
          _isCarouselDragging = isDragging;
        });
      },
    );
  }

  /// Helper function para construir imágenes desde URLs
  /// Detecta automáticamente si es un asset local o URL externa
  /// Permite usar URLs tal cual están en la base de datos sin agregar prefijos automáticos
  Widget _buildImageFromUrl(
    String url, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
  }) {
    // Si la URL es una URL externa (http/https), usar Image.network
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    // Si es un asset local, usar Image.asset directamente con la URL tal cual está
    // No agregamos "assets/" porque la URL ya viene completa desde la BD
    return Image.asset(
      url,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );
  }
}
