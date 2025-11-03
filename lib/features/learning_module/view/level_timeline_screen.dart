/*
  Solo delimitamos la vista del level screen
  Obtiene su estado del ViewModel.
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/learning_module/viewmodel/level_timeline_viewmodel.dart';
import 'level_play_screen.dart.example';

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
    return ChangeNotifierProvider(
      create: (_) => LevelTimelineViewModel(moduleId),
      child: LevelTimelineContent(
        moduleId: moduleId,
        backgroundImagePath: backgroundImagePath,
      ),
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
  final double _itemHeight = 155.0;

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
    _generateKeys(viewModel.steps.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.calculateNodePositions(
        MediaQuery.of(context).size,
        _itemHeight,
      );
    });
  }

  void _generateKeys(int stepsCount) {
    _keys.clear();
    for (int i = 0; i < stepsCount; i++) {
      _keys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context, LevelStepInfo step, int index) {
    _removeOverlay();
    final RenderBox renderBox =
        _keys[index].currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final popupWidth = 250.0;
    final popupLeft = (MediaQuery.of(context).size.width - popupWidth) / 2;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () =>
                context.read<LevelTimelineViewModel>().clearSelection(),
            child: Container(color: const Color.fromARGB(178, 0, 0, 0)),
          ),
          Positioned(
            left: popupLeft,
            top: offset.dy > 300 ? offset.dy - 220 : offset.dy + 80,
            child: _buildPopupContent(step),
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
            _showOverlay(context, step, viewModel.selectedIndex!);
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
              if (widget.backgroundImagePath != null)
                Positioned.fill(
                  child: Image.asset(
                    widget.backgroundImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A3D52), Color(0xFF091F2C)],
                        ),
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
                    child: _buildPlayButton(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayButton() {
    const activeColor = Color(0xFF00E5FF);
    return ElevatedButton.icon(
      onPressed: () {},
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(216, 9, 31, 44),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color.fromARGB(51, 255, 255, 255)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPopupContent(LevelStepInfo step) {
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
            Text(
              step.previewTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (step.posibleImagePreview != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Image.asset(
                  step.posibleImagePreview!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.error),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (step.stars != null) _buildStarsPopup(step.stars!),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
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
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (index) => Icon(
            index < starCount ? Icons.star : Icons.star_border,
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
}
