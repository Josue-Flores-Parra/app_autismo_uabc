import 'dart:math';
import 'package:flutter/material.dart';
import '../../minigame_core.dart';

/// Minijuego de Selección Simple
/// Presenta al usuario varias imágenes y debe seleccionar la correcta
/// basándose en una instrucción o pregunta
class SimpleSelectionMinigame extends MinigameBase {
  const SimpleSelectionMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<SimpleSelectionMinigame> createState() =>
      _SimpleSelectionMinigameState();
}

class _SimpleSelectionMinigameState extends State<SimpleSelectionMinigame> {
  int _attempts = 0;
  int? _selectedIndex;
  bool _isCompleted = false;

  /// Evita toques adicionales mientras se muestra feedback o cambia la pregunta
  bool _isInteractionLocked = false;

  // Sistema de múltiples preguntas
  late final List<QuestionData> _questions;
  int _currentQuestionIndex = 0;
  int _totalAttempts = 0; // Intentos totales a través de todas las preguntas

  // Datos de la pregunta actual
  late String _question;
  late List<SelectionOption> _options;
  late int _correctIndex;
  late int _maxAttempts;
  late SelectionOption _correctOption;

  @override
  void initState() {
    super.initState();
    _initializeGameData();
    _loadCurrentQuestion();
  }

  /// Inicializa los datos del juego desde minigameData
  void _initializeGameData() {
    final data = widget.minigameData;

    // Verificar si hay múltiples preguntas (formato nuevo) o una sola (formato antiguo)
    if (data.containsKey('questions')) {
      // Formato nuevo: múltiples preguntas
      // Manejar questions de manera robusta: puede venir como List o como Map (LinkedMap de Firestore)
      List<dynamic> questionsData = [];
      try {
        final rawQuestions = data['questions'];
        if (rawQuestions == null) {
          questionsData = [];
        } else if (rawQuestions is List) {
          questionsData = rawQuestions;
        } else if (rawQuestions is Map) {
          // Si viene como Map (LinkedMap), convertir a List
          questionsData = rawQuestions.values.toList();
        } else {
          questionsData = [];
        }
      } catch (e) {
        debugPrint('Error al parsear questions: $e');
        questionsData = [];
      }

      _questions = questionsData
          .map((q) {
            if (q is Map<String, dynamic>) {
              return QuestionData.fromMap(q);
            }
            // Si no es un Map, intentar crear una pregunta por defecto
            return QuestionData(
              question: '¿Cuál es la imagen correcta?',
              correctIndex: 0,
              maxAttempts: 3,
              options: [],
            );
          })
          .toList();

      // Limitar a máximo 3 preguntas
      if (_questions.length > 3) {
        _questions.removeRange(3, _questions.length);
      }
    } else {
      // Formato antiguo: una sola pregunta (backward compatibility)
      _questions = [QuestionData.fromMap(data)];
    }
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

    if (safeCorrectIndex != questionData.correctIndex) {
      debugPrint(
        'SimpleSelectionMinigame: correctIndex fuera de rango, se ajustó a $safeCorrectIndex (pregunta $_currentQuestionIndex)',
      );
    }

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

    setState(() {
      _selectedIndex = index;
      _attempts++;
      _totalAttempts++;
      _isInteractionLocked = true;
    });

    // Verificar si la selección es correcta
    final isCorrect = index == _correctIndex;

    if (isCorrect) {
      // Selección correcta
      _showFeedback(isCorrect: true);

      // Verificar si hay más preguntas
      if (_currentQuestionIndex < _questions.length - 1) {
        // Avanzar a la siguiente pregunta
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _currentQuestionIndex++;
              _loadCurrentQuestion();
            });
          }
        });
      } else {
        // Última pregunta completada - finalizar el juego
        Future.delayed(const Duration(milliseconds: 1500), () {
          _completeGame(success: true);
        });
      }
    } else {
      // Selección incorrecta
      _showFeedback(isCorrect: false);

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
            });
          }
        });
      }
    }
  }

  /// Muestra feedback visual al usuario
  void _showFeedback({required bool isCorrect}) {
    final message = isCorrect ? '¡Correcto!' : '¡Intenta de nuevo!';

    final color = isCorrect ? const Color(0xFF05E995) : const Color(0xFFFF9800);
    final icon = isCorrect ? Icons.check_circle : Icons.refresh;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 300, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  /// Completa el juego y llama al callback
  void _completeGame({required bool success}) {
    setState(() {
      _isCompleted = true;
      _isInteractionLocked = true;
    });

    // Solo mostrar feedback si falló (porque si tuvo éxito ya se mostró en _handleSelection)
    if (!success) {
      _showFeedback(isCorrect: false);
    }

    // Llamar al callback después de un breve delay para que el usuario vea el feedback
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onComplete(success, _totalAttempts);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Fila con indicador de progreso e intentos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Indicador de progreso si hay múltiples preguntas
                    if (_questions.length > 1) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(150, 9, 31, 44),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.quiz,
                                    color: Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Indicadores visuales de progreso
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_questions.length, (
                                  index,
                                ) {
                                  final isCompleted =
                                      index < _currentQuestionIndex;
                                  final isCurrent =
                                      index == _currentQuestionIndex;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 30,
                                    height: 8,
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
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Información de intentos (siempre visible)
                    Flexible(child: _buildAttemptsInfo()),
                  ],
                ),
                const SizedBox(height: 16),

                // Área de pregunta/instrucción
                _buildQuestionArea(),
                const SizedBox(height: 24),

                // Grid de opciones
                Expanded(child: _buildOptionsGrid()),
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
        ],
      ),
    );
  }

  /// Construye la información de intentos
  Widget _buildAttemptsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(216, 9, 31, 44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag, color: Color(0xFFFFD700), size: 24),
          const SizedBox(width: 8),
          Text(
            'Intentos: $_attempts / $_maxAttempts',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el grid de opciones
  Widget _buildOptionsGrid() {
    // Determinar número de columnas basado en cantidad de opciones
    int crossAxisCount;
    if (_options.length <= 2) {
      crossAxisCount = 2;
    } else if (_options.length <= 4) {
      crossAxisCount = 2;
    } else if (_options.length <= 6) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 3;
    }

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

            // Label (si existe)
            if (option.label.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(100, 0, 0, 0),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
}

/// Clase para representar los datos de una pregunta
class QuestionData {
  final String question;
  final int correctIndex;
  final int maxAttempts;
  final List<SelectionOption> options;

  QuestionData({
    required this.question,
    required this.correctIndex,
    required this.maxAttempts,
    required this.options,
  });

  factory QuestionData.fromMap(Map<String, dynamic> map) {
    // Manejar options de manera robusta: puede venir como List o como Map (LinkedMap de Firestore)
    List<dynamic> optionsData = [];
    try {
      final rawOptions = map['options'];
      if (rawOptions == null) {
        optionsData = [];
      } else if (rawOptions is List) {
        optionsData = rawOptions;
      } else if (rawOptions is Map) {
        // Si viene como Map (LinkedMap), convertir a List
        // Esto puede pasar cuando Firestore devuelve los datos de manera diferente
        optionsData = rawOptions.values.toList();
      } else {
        optionsData = [];
      }
    } catch (e) {
      debugPrint('Error al parsear options: $e');
      optionsData = [];
    }

    final options = optionsData.map((opt) {
      if (opt is Map<String, dynamic>) {
        return SelectionOption.fromMap(opt);
      }
      return SelectionOption(imagePath: opt.toString(), label: '');
    }).toList();

    return QuestionData(
      question: map['question'] as String? ?? '¿Cuál es la imagen correcta?',
      correctIndex: map['correctIndex'] as int? ?? 0,
      maxAttempts: map['maxAttempts'] as int? ?? 3,
      options: options,
    );
  }
}

/// Clase para representar una opción de selección
class SelectionOption {
  final String imagePath;
  final String label;

  SelectionOption({required this.imagePath, required this.label});

  factory SelectionOption.fromMap(Map<String, dynamic> map) {
    return SelectionOption(
      imagePath: map['imagePath'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'imagePath': imagePath, 'label': label};
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
        return const Center(
          child: CircularProgressIndicator(),
        );
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

/// Registrar este minijuego con el factory
/// Debe ser llamado durante la inicialización de la app (main.dart)
void registerSimpleSelectionMinigame() {
  MinigameFactory.register(
    MinigameType.simpleSelection,
    ({required onComplete, required minigameData}) => SimpleSelectionMinigame(
      onComplete: onComplete,
      minigameData: minigameData,
    ),
  );
}
