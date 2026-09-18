import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../shared/services/tts_service.dart';
import '../../../../shared/services/celebration_helper.dart';
import '../../../../shared/services/negative_feedback_helper.dart';
import '../../minigame_core.dart';
import '../../simple_selection_questions.dart';

/// Minijuego de Selección Simple
/// Presenta al usuario varias imágenes y debe seleccionar la correcta
/// basándose en una instrucción o pregunta
class SimpleSelectionMinigame extends MinigameBase {
  const SimpleSelectionMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
    super.onReady,
    super.onObjectiveMet,
  });

  @override
  State<SimpleSelectionMinigame> createState() =>
      _SimpleSelectionMinigameState();
}

enum _InlineFeedbackType { none, correct, incorrect }

class _SimpleSelectionMinigameState extends State<SimpleSelectionMinigame> {
  static const Duration _kInlineFeedbackFadeDuration = Duration(
    milliseconds: 240,
  );

  int _attempts = 0;
  int? _selectedIndex;
  bool _isCompleted = false;

  /// Evita toques adicionales mientras se muestra feedback o cambia la pregunta
  bool _isInteractionLocked = false;

  // Sistema de múltiples preguntas
  late final List<QuestionData> _questions;
  int _currentQuestionIndex = 0;
  int _totalAttempts = 0; // Intentos totales a través de todas las preguntas
  bool _isPreloadingImages = true;
  _InlineFeedbackType _inlineFeedback = _InlineFeedbackType.none;

  late final CelebrationHelper _celebrationHelper;
  // Servicio reutilizable que reproduce el sonido de fallo (negative beep).
  late final NegativeFeedbackHelper _negativeFeedbackHelper;
  final TtsService _ttsService = TtsService();
  bool _ttsReady = false;

  // Datos de la pregunta actual
  late String _question;
  late List<SelectionOption> _options;
  late int _correctIndex;
  late int _maxAttempts;
  late SelectionOption _correctOption;

  @override
  void initState() {
    super.initState();
    _celebrationHelper = CelebrationHelper();
    _negativeFeedbackHelper = NegativeFeedbackHelper();
    _initTts();
    _initializeGameData();
    _loadCurrentQuestion();
    // Precargar todas las imagenes de las 3 preguntas antes de habilitar el juego.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAllQuestionImages();
      // La primera pregunta ya es utilizable al construirse.
      widget.onReady?.call();
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _celebrationHelper.dispose();
    _negativeFeedbackHelper.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    final ready = await _ttsService.initializeDefaultEsMx();
    if (!mounted) return;
    setState(() {
      _ttsReady = ready;
    });
    if (_ttsReady && !_isPreloadingImages) {
      _speakCurrentQuestion();
    }
  }

  Future<void> _speakCurrentQuestion() async {
    if (!_ttsReady) return;
    await _ttsService.speak(_question);
  }

  Future<void> _precacheAllQuestionImages() async {
    final uniquePaths = <String>{
      for (final q in _questions)
        for (final o in q.options)
          if (o.imagePath.trim().isNotEmpty) o.imagePath.trim(),
    };

    final futures = uniquePaths.map((path) async {
      try {
        final provider =
            (path.startsWith('http://') || path.startsWith('https://'))
            ? NetworkImage(path)
            : AssetImage(path) as ImageProvider;
        await precacheImage(provider, context);
      } catch (_) {
        // Ignorar errores individuales para no bloquear el minijuego completo.
      }
    }).toList();

    await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _isPreloadingImages = false;
    });
    if (_ttsReady) {
      _speakCurrentQuestion();
    }
  }

  /// Inicializa los datos del juego desde minigameData
  void _initializeGameData() {
    final data = widget.minigameData;

    final questions = buildQuestionsFromData(data);
    if (questions.isNotEmpty) {
      _questions = questions;
      return;
    }

    // Sin datos de preguntas (ni steps ni campo `questions`): proveer una
    // pregunta por defecto para evitar un soft-lock. _loadCurrentQuestion()
    // sigue usando el fallback _getDefaultOptions() cuando options está vacío.
    _questions = [
      QuestionData(
        question: '¿Cuál es la imagen correcta?',
        correctIndex: 0,
        maxAttempts: 3,
        options: [],
      ),
    ];
  }

  /// Carga la pregunta actual
  void _loadCurrentQuestion() {
    if (_currentQuestionIndex >= _questions.length) return;

    final questionData = _questions[_currentQuestionIndex];

    _question = questionData.question;
    _maxAttempts = max(1, questionData.maxAttempts);

    // Resetear intentos para la nueva pregunta
    _attempts = 0;
    _selectedIndex = null;
    _isInteractionLocked = false;
    _inlineFeedback = _InlineFeedbackType.none;

    // Cargar y mezclar opciones
    List<SelectionOption> loadedOptions = List.from(questionData.options);

    if (loadedOptions.isEmpty) {
      loadedOptions = _getDefaultOptions();
    }

    if (loadedOptions.isEmpty) {
      loadedOptions = [
        SelectionOption(
          imagePath: 'assets/images/icon-questionmark.png',
          label: '',
        ),
      ];
    }

    // Guardar la opción correcta antes de mezclar
    final safeCorrectIndex = questionData.correctIndex.clamp(
      0,
      loadedOptions.length - 1,
    );

    _correctOption = loadedOptions[safeCorrectIndex];

    // mezclar las opciones
    loadedOptions.shuffle(Random());
    _options = loadedOptions;

    // Encontrar el nuevo índice de la opción correcta después del shuffle
    _correctIndex = _options.indexWhere(
      (option) =>
          option.imagePath == _correctOption.imagePath &&
          option.label == _correctOption.label,
    );
    if (_correctIndex < 0) {
      _correctIndex = 0;
    }

    if (_ttsReady && !_isPreloadingImages) {
      _speakCurrentQuestion();
    }
  }

  /// Opciones por defecto para propósitos de desarrollo/testing
  /// Usa placeholders simples y básicos
  List<SelectionOption> _getDefaultOptions() {
    return [
      SelectionOption(
        imagePath: 'assets/images/icon-questionmark.png',
        label: 'Opción 1',
      ),
      SelectionOption(
        imagePath: 'assets/images/icon-questionmark2x.png',
        label: 'Opción 2',
      ),
      SelectionOption(
        imagePath: 'assets/images/icon-salute-hidden.png',
        label: 'Opción 3',
      ),
    ];
  }

  /// Maneja la selección de una opción
  void _handleSelection(int index) {
    if (_isCompleted || _isInteractionLocked) return;

    final isCorrect = index == _correctIndex;

    setState(() {
      _selectedIndex = index;
      _attempts++;
      _totalAttempts++;
      _isInteractionLocked = true;
      _inlineFeedback = isCorrect
          ? _InlineFeedbackType.correct
          : _InlineFeedbackType.incorrect;
    });

    if (isCorrect) {
      // Selección correcta: el feedback principal se muestra inline
      // entre la pregunta y las opciones (no en SnackBar).

      // Verificar si hay más preguntas
      if (_currentQuestionIndex < _questions.length - 1) {
        // Avanzar a la siguiente pregunta
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;

          // Primero ocultar el feedback para evitar flicker al cambiar pregunta.
          setState(() {
            _inlineFeedback = _InlineFeedbackType.none;
          });

          Future.delayed(_kInlineFeedbackFadeDuration, () {
            if (!mounted) return;
            setState(() {
              _currentQuestionIndex++;
              _loadCurrentQuestion();
            });
          });
        });
      } else {
        // Última pregunta completada - finalizar el juego
        _completeGame(success: true);
      }
    } else {
      // Verificar si se agotaron los intentos
      if (_attempts >= _maxAttempts) {
        _completeGame(success: false);
      } else {
        // Resetear selección después de un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _selectedIndex = null;
              _isInteractionLocked = false;
              _inlineFeedback = _InlineFeedbackType.none;
            });
          }
        });
      }
    }
  }

  /// Completa el juego y llama al callback
  void _completeGame({required bool success}) {
    setState(() {
      _isCompleted = true;
      _isInteractionLocked = true;
    });
    _ttsService.stop();

    if (success) {
      // Señal de objetivo antes de celebración/TTS/delay para no inflar el reloj.
      widget.onObjectiveMet?.call();
      _celebrateCompletion();
    } else {
      _inlineFeedback = _InlineFeedbackType.incorrect;
      // Sonido de fallo, ahora delegado al helper reutilizable.
      _negativeFeedbackHelper.playNegativeBeep();
    }

    // Mantener un pequeño delay para que se vea el feedback/celebración.
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onComplete(success, _totalAttempts);
    });
  }

  void _celebrateCompletion() {
    _celebrationHelper.playCelebration();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreloadingImages) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3D52), Color(0xFF091F2C)],
            ),
          ),
          child: SafeArea(
            child: _SimpleSelectionLoadingSkeleton(
              showQuestionProgress: _questions.length > 1,
              crossAxisCount: _getOptionsCrossAxisCount(_options.length),
              optionCount: max(2, _options.length),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A3D52), Color(0xFF091F2C)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTopStatusLayout(),
                    const SizedBox(height: 16),

                    // Área de pregunta/instrucción
                    _buildQuestionArea(),
                    const SizedBox(height: 10),
                    _buildInlineFeedbackLabel(),
                    const SizedBox(height: 14),

                    // Grid de opciones
                    Expanded(child: _buildOptionsGrid()),
                  ],
                ),
              ),
            ),
          ),
          CelebrationHelper.buildTopConfettiOverlay(
            controller: _celebrationHelper.confettiController,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineFeedbackLabel() {
    if (_inlineFeedback == _InlineFeedbackType.none) {
      return const SizedBox(height: 48);
    }

    final isCorrect = _inlineFeedback == _InlineFeedbackType.correct;
    final backgroundColor = isCorrect
        ? const Color(0xFF05E995)
        : const Color(0xFFFF9800);
    final shadowColor = isCorrect
        ? const Color(0x6605E995)
        : const Color(0x66FF9800);
    final icon = isCorrect ? Icons.check_circle : Icons.refresh;
    final label = isCorrect ? 'Correcto' : 'Intenta de nuevo';

    return SizedBox(
      height: 48,
      child: Center(
        child: AnimatedSwitcher(
          duration: _kInlineFeedbackFadeDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Container(
            key: ValueKey<_InlineFeedbackType>(_inlineFeedback),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el área de pregunta
  Widget _buildQuestionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: Color(0xFF00E5FF), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _ttsReady ? _speakCurrentQuestion : null,
            icon: const Icon(Icons.volume_up_rounded),
            color: Colors.white,
            tooltip: 'Escuchar pregunta',
          ),
        ],
      ),
    );
  }

  /// Construye la información de intentos
  Widget _buildAttemptsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(216, 9, 31, 44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag, color: Color(0xFFFFD700), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Intentos: $_attempts / $_maxAttempts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionProgressInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(150, 9, 31, 44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_questions.length, (index) {
              final isCompleted = index < _currentQuestionIndex;
              final isCurrent = index == _currentQuestionIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 28,
                height: 7,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF05E995)
                      : isCurrent
                      ? const Color(0xFF00E5FF)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Construye el grid de opciones
  Widget _buildOptionsGrid() {
    final crossAxisCount = _getOptionsCrossAxisCount(_options.length);

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular el tamaño máximo que puede ocupar cada item
          final spacing = 16.0;
          final availableWidth = constraints.maxWidth;

          // Calcular el ancho de cada item
          final itemWidth =
              (availableWidth - (spacing * (crossAxisCount - 1))) /
              crossAxisCount;

          // Calcular cuántas filas necesitamos
          final rowCount = (_options.length / crossAxisCount).ceil();

          // Calcular la altura de cada item (mantener proporción cuadrada)
          final itemHeight = itemWidth;

          // Altura total del grid
          final totalHeight =
              (itemHeight * rowCount) + (spacing * (rowCount - 1));

          return SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxHeight: totalHeight),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1.0, // Proporción cuadrada
                ),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  return _buildOptionCard(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye una tarjeta de opción individual
  Widget _buildOptionCard(int index) {
    final option = _options[index];
    final isSelected = _selectedIndex == index;
    final isCorrect = index == _correctIndex;
    final showResult = _isCompleted && isSelected;

    return InkWell(
      onTap: _isCompleted ? null : () => _handleSelection(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _getCardGradient(isSelected, showResult, isCorrect),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBorderColor(isSelected, showResult, isCorrect),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _getBorderColor(
                  isSelected,
                  showResult,
                  isCorrect,
                ).withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              )
            else
              const BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildImageFromPath(option.imagePath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Determina el gradiente de la tarjeta
  LinearGradient _getCardGradient(
    bool isSelected,
    bool showResult,
    bool isCorrect,
  ) {
    if (showResult) {
      if (isCorrect) {
        // Verde neón para correcto
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05E995), Color(0xFF03B872)],
        );
      } else {
        // Rojo para incorrecto
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
        );
      }
    }
    if (isSelected) {
      // Azul neón para seleccionado
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00E5FF), Color(0xFF0096B3)],
      );
    }
    // Gradiente oscuro por defecto
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
    );
  }

  /// Determina el color del borde de la tarjeta
  Color _getBorderColor(bool isSelected, bool showResult, bool isCorrect) {
    if (showResult) {
      return isCorrect ? const Color(0xFF05E995) : const Color(0xFFE74C3C);
    }
    if (isSelected) {
      return const Color(0xFF00E5FF);
    }
    return const Color(0x66FFFFFF);
  }

  Widget _buildTopStatusLayout() {
    final showQuestionProgress = _questions.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            showQuestionProgress && constraints.maxWidth < 560;
        if (stackVertically) {
          return Column(
            children: [
              _buildQuestionProgressInfo(),
              const SizedBox(height: 10),
              _buildAttemptsInfo(),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showQuestionProgress)
              Expanded(child: _buildQuestionProgressInfo()),
            if (showQuestionProgress) const SizedBox(width: 12),
            Expanded(child: _buildAttemptsInfo()),
          ],
        );
      },
    );
  }

  int _getOptionsCrossAxisCount(int optionCount) {
    if (optionCount <= 4) return 2;
    return 3;
  }
}

/// Helper function para construir imágenes desde paths
/// Detecta automáticamente si es un asset local o URL externa
/// Permite usar URLs tal cual están en la base de datos sin agregar prefijos automáticos
Widget _buildImageFromPath(String path) {
  // Si la URL es una URL externa (http/https), usar Image.network
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.white54,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _SimpleSelectionImageShimmer();
      },
    );
  }

  // Si es un asset local, usar Image.asset directamente con la URL tal cual está
  // No agregamos "assets/" porque la URL ya viene completa desde la BD
  return Image.asset(
    path,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return const Icon(
        Icons.image_not_supported,
        size: 64,
        color: Colors.white54,
      );
    },
  );
}

class _SimpleSelectionLoadingSkeleton extends StatelessWidget {
  final bool showQuestionProgress;
  final int crossAxisCount;
  final int optionCount;

  const _SimpleSelectionLoadingSkeleton({
    required this.showQuestionProgress,
    required this.crossAxisCount,
    required this.optionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackVertically =
                  showQuestionProgress && constraints.maxWidth < 560;
              if (stackVertically) {
                return const Column(
                  children: [
                    _SimpleSelectionShimmer(
                      child: _SimpleSelectionSkeletonBox(
                        height: 44,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    SizedBox(height: 10),
                    _SimpleSelectionShimmer(
                      child: _SimpleSelectionSkeletonBox(
                        height: 44,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  if (showQuestionProgress)
                    const Expanded(
                      child: _SimpleSelectionShimmer(
                        child: _SimpleSelectionSkeletonBox(
                          height: 44,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ),
                  if (showQuestionProgress) const SizedBox(width: 12),
                  const Expanded(
                    child: _SimpleSelectionShimmer(
                      child: _SimpleSelectionSkeletonBox(
                        height: 44,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const _SimpleSelectionShimmer(
            child: _SimpleSelectionSkeletonBox(
              height: 92,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: List.generate(
                optionCount,
                (_) => const _SimpleSelectionShimmer(
                  child: _SimpleSelectionSkeletonBox(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleSelectionImageShimmer extends StatelessWidget {
  const _SimpleSelectionImageShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(4),
      child: _SimpleSelectionShimmer(
        child: _SimpleSelectionSkeletonBox(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}

class _SimpleSelectionShimmer extends StatefulWidget {
  final Widget child;
  const _SimpleSelectionShimmer({required this.child});

  @override
  State<_SimpleSelectionShimmer> createState() =>
      _SimpleSelectionShimmerState();
}

class _SimpleSelectionShimmerState extends State<_SimpleSelectionShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
              stops: [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SimpleSelectionSkeletonBox extends StatelessWidget {
  final double? height;
  final BorderRadius borderRadius;

  const _SimpleSelectionSkeletonBox({
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E4D6B),
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// Registrar este minijuego con el factory
/// Debe ser llamado durante la inicialización de la app (main.dart)
void registerSimpleSelectionMinigame() {
  MinigameFactory.register(
    MinigameType.simpleSelection,
    ({required onComplete, required minigameData, onReady, onObjectiveMet}) =>
        SimpleSelectionMinigame(
          onComplete: onComplete,
          minigameData: minigameData,
          onReady: onReady,
          onObjectiveMet: onObjectiveMet,
        ),
  );
}
