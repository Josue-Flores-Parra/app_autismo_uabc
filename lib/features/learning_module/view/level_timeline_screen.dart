/*
  Solo delimitamos la vista del level screen
  Obtiene su estado del ViewModel.
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/learning_module/viewmodel/level_timeline_viewmodel.dart';
import 'package:appy/features/learning_module/viewmodel/learning_viewmodel.dart';
import 'package:appy/features/learning_module/view/level_content_screen.dart';
import 'package:appy/features/learning_module/model/content_card_model.dart';

class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final List<StateOfStep?> nodeStates;
  /*
  Necesitamos pasarle las posiciones de los nodos y sus estados
  para dibujarlos correctamente.
  */

  PathPainter({required this.nodePositions, required this.nodeStates});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;
    final basePaint = Paint()
      ..color = const Color.fromARGB(102, 58, 44, 88) /* 40% de opacidad */
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    final completedPaint = Paint()
      ..color = const Color(0xFF05E995)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Dibujar líneas entre nodos con efecto de curva suave
    // Usamos cubicTo para crear una curva entre cada par de nodos, y el color depende del estado del nodo inicial
    // Si el nodo está completado, la línea se dibuja con el paint de completed, sino con el paint base.
    // Esto crea un efecto visual donde las líneas hacia los nodos completados se ven más brillantes
    // y resaltan, mientras que las líneas hacia los nodos bloqueados o en progreso se ven más tenues.
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final startPoint = nodePositions[i];
      final endPoint = nodePositions[i + 1];
      final state = nodeStates[i];
      final paint = state == StateOfStep.completed ? completedPaint : basePaint;
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.cubicTo(
        startPoint.dx,
        startPoint.dy + (endPoint.dy - startPoint.dy) / 2,
        endPoint.dx,
        startPoint.dy + (endPoint.dy - startPoint.dy) / 2,
        endPoint.dx,
        endPoint.dy,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LevelTimelineScreen extends StatelessWidget {
  const LevelTimelineScreen({
    super.key,
    required this.moduleId,
    this.backgroundImagePath,
  });

  final String moduleId;
  final String? backgroundImagePath;

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningViewModel>(
      builder: (context, learningViewModel, child) {
        return ChangeNotifierProvider(
          create: (_) => LevelTimelineViewModel(learningViewModel, moduleId),
          child: LevelTimelineContent(
            moduleId: moduleId,
            backgroundImagePath: backgroundImagePath,
          ),
        );
      },
    );
  }
}

class LevelTimelineContent extends StatefulWidget {
  final String moduleId;
  final String? backgroundImagePath;

  const LevelTimelineContent({
    super.key,
    required this.moduleId,
    this.backgroundImagePath,
  });

  @override
  State<LevelTimelineContent> createState() => _LevelTimelineScreenState();
}

class _LevelTimelineScreenState extends State<LevelTimelineContent>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final List<GlobalKey> _keys = [];
  final double _itemHeight = 175.0;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<LevelTimelineViewModel>();

    // Only generate keys and calculate positions if we have steps
    if (viewModel.steps.isNotEmpty) {
      _generateKeys(viewModel.steps.length);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.calculateNodePositions(
          MediaQuery.of(context).size,
          _itemHeight,
        );
      });
    }
  }

  void _generateKeys(int stepsCount) {
    // Only regenerate if the count has changed
    if (_keys.length != stepsCount) {
      _keys.clear();
      for (int i = 0; i < stepsCount; i++) {
        _keys.add(GlobalKey());
      }
    }
  }

  @override
  void dispose() {
    // Liberar los pines del ImageCache al salir del timeline.
    // Mientras la pantalla esté activa los pines mantienen las portadas en
    // memoria; al hacer pop() se liberan para que el GC pueda recuperarlas.
    context.read<LearningViewModel>().releasePinsForModule(widget.moduleId);
    _animationController?.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(
    BuildContext context,
    LevelStepInfo step,
    int index,
    LevelTimelineViewModel viewModel,
  ) {
    _removeOverlay();
    final RenderBox renderBox =
        _keys[index].currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final popupWidth = 250.0;
    final popupLeft = (MediaQuery.of(context).size.width - popupWidth) / 2;
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          GestureDetector(
            onTap: () => viewModel.clearSelection(),
            child: Container(color: const Color.fromARGB(178, 0, 0, 0)),
          ),
          Positioned(
            left: popupLeft,
            top: offset.dy > 300 ? offset.dy - 220 : offset.dy + 80,
            child: _buildPopupContent(overlayContext, step, viewModel),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LevelTimelineViewModel>(
      builder: (context, viewModel, child) {
        // Handle loading state
        if (viewModel.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.moduleTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF1A3D52),
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error state
        if (viewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.moduleTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF1A3D52),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Ensure keys are generated when steps are available
        if (_keys.length != viewModel.steps.length) {
          _generateKeys(viewModel.steps.length);
          // Schedule position calculation after keys are generated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              viewModel.calculateNodePositions(
                MediaQuery.of(context).size,
                _itemHeight,
              );
            }
          });
        }

        final activeStepIndex = viewModel.steps.indexWhere(
          (step) => step.whatState == StateOfStep.inProgress,
        );
        Offset? activeNodePosition;
        if (activeStepIndex != -1 &&
            viewModel.nodePositions.length > activeStepIndex) {
          activeNodePosition = viewModel.nodePositions[activeStepIndex];
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.selectedIndex != null && _overlayEntry == null) {
            final step = viewModel.steps[viewModel.selectedIndex!];
            _showOverlay(context, step, viewModel.selectedIndex!, viewModel);
          } else if (viewModel.selectedIndex == null && _overlayEntry != null) {
            _removeOverlay();
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(
              viewModel.moduleTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1A3D52),
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              // Always show a background (either image or gradient)
              Positioned.fill(
                child: widget.backgroundImagePath != null
                    ? Image.asset(
                        widget.backgroundImagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1A3D52), Color(0xFF091F2C)],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1A3D52), Color(0xFF091F2C)],
                          ),
                        ),
                      ),
              ),
              /*
                Como se nos pidió, wrapeamos Al Listview builder dentro de
                SingleChildScrollView para que se pueda scrollear tanto dentro de lo que es los niveles
                como fuera de ellos, en caso de que la pantalla sea muy pequeña.
              */
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: SizedBox(
                  height: (viewModel.steps.length * _itemHeight),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (viewModel.nodePositions.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: PathPainter(
                            nodePositions: viewModel.nodePositions,
                            nodeStates: viewModel.steps
                                .map((e) => e.whatState)
                                .toList(),
                          ),
                        ),
                      ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: viewModel.steps.length,
                        itemBuilder: (context, index) {
                          final step = viewModel.steps[index];
                          final isLeft = index % 2 == 0;
                          return Container(
                            height: _itemHeight,
                            alignment: isLeft
                                ? const Alignment(-0.25, 0)
                                : const Alignment(0.25, 0),
                            child: _buildNodeAndTitle(
                              context: context,
                              index: index,
                              step: step,
                            ),
                          );
                        },
                      ),
                      if (activeNodePosition != null)
                        Positioned(
                          top: activeNodePosition.dy - 1,
                          left: activeNodePosition.dx - 90,
                          child: Container(
                            width: 63,
                            height: 63,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(150, 6, 185, 176),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset('assets/images/appysittin.png'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (activeStepIndex != -1)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    child: _buildPlayButton(
                      context,
                      viewModel,
                      activeStepIndex,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(
    BuildContext context,
    LevelTimelineViewModel viewModel,
    int stepIndex,
  ) {
    const activeColor = Color(0xFF00E5FF);
    final step = viewModel.steps[stepIndex];

    return ElevatedButton.icon(
      onPressed: () async {
        // Obtener el nivel completo desde el ViewModel
        final levelInfo = viewModel.moduleLevels.firstWhere(
          (level) => level.id == step.levelId,
          orElse: () => throw Exception('Nivel no encontrado'),
        );

        // Construir el contenido del carrusel desde el nivel completo
        final contents = _buildContentFromLevel(levelInfo);

        // Primero navegar a la pantalla de preview con el carrusel
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelContentPreviewScreen(
              levelName: levelInfo.titulo,
              bgLevelImg: levelInfo.pictogramaUrl,
              contents: contents,
              // Pasar los datos del minijuego para cuando presionen "JUGAR"
              minigameData: step.minigameData,
              actividadType: step.actividadType,
              levelId: step.levelId,
              moduleId: step.moduleId,
              levelTitle: step.previewTitle,
              videoUrl: levelInfo.videoUrl,
            ),
          ),
        );
        // Recargar datos del módulo después de regresar.
        // Se hace await para que la relectura de Firestore termine antes de
        // reconstruir el timeline y no quedarse con progreso obsoleto.
        if (context.mounted) {
          await viewModel.reloadModuleData();
        }
      },
      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
      label: const Text(
        'JUGAR',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: activeColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        shadowColor: const Color.fromARGB(204, 0, 229, 255),
      ),
    );
  }

  Widget _buildNodeAndTitle({
    required BuildContext context,
    required int index,
    required LevelStepInfo step,
  }) {
    final viewModel = context.read<LevelTimelineViewModel>();

    // Safety check: ensure we have a valid key for this index
    if (index >= _keys.length) {
      // Return a placeholder while keys are being generated
      return const SizedBox.shrink();
    }

    final nodeWidget = GestureDetector(
      key: _keys[index],
      onTap: () => viewModel.handleTap(index),
      child: _buildStepCircle(step.whatState),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (step.whatState == StateOfStep.inProgress && _scaleAnimation != null)
          ScaleTransition(scale: _scaleAnimation!, child: nodeWidget)
        else
          nodeWidget,
        const SizedBox(height: 6),
        if (step.whatState != StateOfStep.blocked)
          _buildTimelineStars(step.stars ?? 0),
        const SizedBox(height: 6),
        _buildStepTitle(step.previewTitle),
      ],
    );
    return Opacity(
      opacity: step.whatState == StateOfStep.completed ? 0.6 : 1.0,
      child: content,
    );
  }

  Widget _buildTimelineStars(int starCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final bool earned = index < starCount;
        return Icon(
          earned ? Icons.star : Icons.star,
          size: 20,
          color: earned ? const Color(0xFFFFD700) : Colors.grey.shade800,
        );
      }),
    );
  }

  Widget _buildStepTitle(String title) {
    return Container(
      // Dimensiones ajustadas para el tamaño de fuente: vertical reducido para compensar el aumento del tamaño de fuente
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(216, 9, 31, 44),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color.fromARGB(51, 255, 255, 255)),
      ),
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 18, // Tamaño de fuente mas grande para mejor legibilidad
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Construye el contenido del popup al hacer tap en un nodo, mostrando la información del paso y el botón de JUGAR
  // Al presionar JUGAR, primero cierra el popup, luego navega a la pantalla de preview del nivel, pasando
  // toda la información necesaria para mostrar el carrusel y los datos del minijuego.
  Widget _buildPopupContent(
    BuildContext context,
    LevelStepInfo step,
    LevelTimelineViewModel viewModel,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(128, 0, 0, 0), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con título y botón de cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    step.previewTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón X para cerrar
                InkWell(
                  onTap: () {
                    viewModel.clearSelection();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            if (step.posibleImagePreview != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: _buildImageFromUrl(
                  step.posibleImagePreview!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (step.stars != null) _buildStarsPopup(step.stars!),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Cerrar el popup primero
                  viewModel.clearSelection();

                  // Obtener el nivel completo desde el ViewModel
                  final levelInfo = viewModel.moduleLevels.firstWhere(
                    (level) => level.id == step.levelId,
                    orElse: () => throw Exception('Nivel no encontrado'),
                  );

                  // Construir el contenido del carrusel desde el nivel completo
                  final contents = _buildContentFromLevel(levelInfo);

                  // Navegar y verificar montado con el contexto del State, que
                  // permanece montado al volver. El contexto del overlay se
                  // desmonta al cerrar el popup (clearSelection), por lo que
                  // usarlo aquí haría que la recarga se saltara por completo.
                  final timelineContext = this.context;
                  // Primero navegar a la pantalla de preview con el carrusel
                  await Navigator.push(
                    timelineContext,
                    MaterialPageRoute(
                      builder: (context) => LevelContentPreviewScreen(
                        levelName: levelInfo.titulo,
                        bgLevelImg: levelInfo.pictogramaUrl,
                        contents: contents,
                        // Pasar los datos del minijuego para cuando presionen "JUGAR"
                        minigameData: step.minigameData,
                        actividadType: step.actividadType,
                        levelId: step.levelId,
                        moduleId: step.moduleId,
                        levelTitle: step.previewTitle,
                        videoUrl: levelInfo.videoUrl,
                      ),
                    ),
                  );
                  // Recargar datos del módulo después de regresar.
                  // Se hace await para que la relectura de Firestore termine
                  // antes de reconstruir el timeline y no quedarse con progreso
                  // obsoleto.
                  if (timelineContext.mounted) {
                    await viewModel.reloadModuleData();
                  }
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'JUGAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(StateOfStep? state) {
    Color neonColor;
    IconData nodeIcon;
    double size = 65.0;
    double iconSize = 35.0;

    switch (state) {
      case StateOfStep.blocked:
        neonColor = Colors.grey.shade600;
        nodeIcon = Icons.lock_outline;
        break;
      case StateOfStep.inProgress:
        neonColor = const Color(0xFF00E5FF);
        nodeIcon = Icons.play_arrow_rounded;
        size = 75.0;
        iconSize = 45.0;
        break;
      case StateOfStep.completed:
        neonColor = const Color(0xFF05E995);
        nodeIcon = Icons.check_circle;
        break;
      default:
        neonColor = Colors.grey;
        nodeIcon = Icons.radio_button_unchecked;
    }

    final bool isCurrent = state == StateOfStep.inProgress;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: neonColor, width: 3.0),
        boxShadow: [
          BoxShadow(
            color: neonColor,
            blurRadius: isCurrent ? 25 : 12,
            spreadRadius: isCurrent ? 5 : 1,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(nodeIcon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildStarsPopup(int starCount) {
    // Mostrar máximo 3 estrellas (el máximo que se puede obtener)
    final maxStars = 3;
    final actualStars = starCount.clamp(0, maxStars);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          maxStars,
          (index) => Icon(
            index < actualStars ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFD700),
            size: 20,
            shadows: const [
              Shadow(color: Color.fromARGB(179, 255, 215, 0), blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el contenido del carrusel desde un ModuleLevelInfo
  List<ContentCardData> _buildContentFromLevel(ModuleLevelInfo level) {
    final List<ContentCardData> contents = [];
    final simpleSelectionEnabled = _asBool(
      level.actividadData?['isSimpleSelectionEnabled'],
    );
    final puzzleEnabled =
        _asBool(level.actividadData?['isPuzzleEnabled']) ||
        (level.actividadType?.toLowerCase() == 'puzzle');
    final puzzleImageUrl = level.puzzleImageUrl;
    final puzzleFallbackUrl = level.pictogramaUrl;
    final hasPuzzleImage =
        (puzzleImageUrl != null && puzzleImageUrl.isNotEmpty) ||
        (puzzleFallbackUrl != null && puzzleFallbackUrl.isNotEmpty);

    // 1. PRIMERO: Si hay pictograma, agregar tarjeta de pictograma
    if (level.pictogramaUrl != null && level.pictogramaUrl!.isNotEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.pictogram,
          title: level.titulo,
          description: 'Pictograma del nivel',
          imagePath: level.pictogramaUrl!,
        ),
      );
    }

    // 2. SEGUNDO: Si hay video, agregar tarjeta de video
    if (level.videoUrl != null && level.videoUrl!.isNotEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.video,
          title: level.titulo,
          description: 'Video educativo',
          imagePath: level.pictogramaUrl ?? '',
          videoPath: level.videoUrl,
        ),
      );
    }

    // 2.5: Si el nivel habilita seleccion simple, agregar su tarjeta en el carrusel.
    if (simpleSelectionEnabled) {
      contents.add(
        ContentCardData(
          type: ContentType.miniGame,
          miniGameType: 'simple_selection',
          title: 'Seleccion simple',
          description: 'Elige la imagen correcta para cada paso',
          imagePath: 'assets/images/salute.png',
        ),
      );
    }

    // 2.6: Si el nivel habilita rompecabezas, agregar su tarjeta en el carrusel.
    if (puzzleEnabled && hasPuzzleImage) {
      contents.add(
        ContentCardData(
          type: ContentType.miniGame,
          miniGameType: 'puzzle',
          title: 'Rompecabezas',
          description: 'Arma la imagen arrastrando las piezas',
          imagePath: puzzleImageUrl?.isNotEmpty == true
              ? puzzleImageUrl!
              : (puzzleFallbackUrl ?? ''),
        ),
      );
    }

    // 3. TERCERO: Si hay audio, agregar tarjeta de audio
    if (level.audioUrl != null && level.audioUrl!.isNotEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.audio,
          title: level.titulo,
          description: 'Audio educativo',
          imagePath: level.pictogramaUrl ?? '',
          audioPath: level.audioUrl,
        ),
      );
    }

    // Si no hay contenido, mostrar mensaje
    if (contents.isEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.pictogram,
          title: level.titulo,
          description: 'Contenido pendiente de agregar',
          imagePath: '',
        ),
      );
    }

    return contents;
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

  /// Construye una imagen desde una URL, detectando automáticamente si es un asset local o URL externa
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
          // Mostrar skeleton animado mientras la imagen de portada carga desde Firestore
          return _TimelineImageSkeleton(height: height, width: width);
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

// ---------------------------------------------------------------------------
// Widgets de esqueleto para la imagen de portada del nivel en el popup
// ---------------------------------------------------------------------------

/// Shimmer animado específico para la imagen de portada del nivel.
/// Barre un destello de izquierda a derecha mientras la imagen carga de Firestore.
class _TimelineImageSkeleton extends StatefulWidget {
  final double? height;
  final double? width;

  const _TimelineImageSkeleton({this.height, this.width});

  @override
  State<_TimelineImageSkeleton> createState() => _TimelineImageSkeletonState();
}

class _TimelineImageSkeletonState extends State<_TimelineImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Ciclo de 1.4 segundos que se repite indefinidamente
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // El destello viaja de izquierda (-2) a derecha (+2)
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFF1E4D6B),
                Color(0xFF2E7DAA),
                Color(0xFF3A9AD9),
                Color(0xFF2E7DAA),
                Color(0xFF1E4D6B),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      // Contenedor exterior que mantiene el mismo espacio reservado que la imagen real.
      // El skeleton interior respeta la proporción 4:3 y queda centrado.
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Center(
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E4D6B),
                borderRadius: BorderRadius.circular(18),
                // Sombra que replica la profundidad de la imagen de portada real
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
