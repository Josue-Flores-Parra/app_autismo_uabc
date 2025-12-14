import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../minigame_core.dart';

/// Minijuego de Pictograma
/// Muestra un pictograma a pantalla completa como actividad
/// El usuario debe presionar "Completar" para finalizar la actividad
class PictogramMinigame extends MinigameBase {
  const PictogramMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<PictogramMinigame> createState() => _PictogramMinigameState();
}

class _PictogramMinigameState extends State<PictogramMinigame> {
  bool _isCompleted = false;
  late final PageController _pageController;
  int _currentIndex = 0;
  late final List<_StepItem> _steps;
  bool _precached = false;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _steps = _parseSteps(widget.minigameData);
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-MX');
      await _tts.setSpeechRate(0.6);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      setState(() => _ttsReady = true);
    } catch (_) {
      setState(() => _ttsReady = false);
    }
  }

  Future<void> _speakCaption(int index) async {
    if (!_ttsReady) return;
    if (index < 0 || index >= _steps.length) return;
    final caption = _steps[index].caption;
    if (caption == null || caption.isEmpty) return;
    await _tts.stop();
    await _tts.speak(caption);
  }

  @override
  Widget build(BuildContext context) {
    // Precargar imágenes una sola vez para evitar parpadeos al pasar rápido
    if (!_precached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final item in _steps) {
          if (item.url.startsWith('http')) {
            precacheImage(NetworkImage(item.url), context);
          } else {
            precacheImage(AssetImage(item.url), context);
          }
        }
      });
      _precached = true;
    }

    // Obtener pictogramaUrl desde actividadData o desde el nivel
    // Puede venir en actividadData['pictogramaUrl'] o directamente en minigameData['pictogramaUrl']
    final pictogramaUrl = widget.minigameData['pictogramaUrl'] as String?;

    // Título/descripcion
    final title = widget.minigameData['title'] as String? ??
        widget.minigameData['titulo'] as String? ??
        'Pictograma';
    final description =
        widget.minigameData['description'] as String? ??
            widget.minigameData['descripcion'] as String?;

    final hasSequence = _steps.isNotEmpty;
    final images = hasSequence
        ? _steps
        : (pictogramaUrl != null && pictogramaUrl.isNotEmpty
            ? [ _StepItem(url: pictogramaUrl) ]
            : <_StepItem>[]);

    if (images.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF091F2C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se encontró el pictograma',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => widget.onComplete(false, 1),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF091F2C),
      body: SafeArea(
        child: Column(
          children: [
            // Header con título
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0x66FFFFFF),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pictograma a pantalla completa (único o secuencia)
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        _speakCaption(index);
                      },
                      itemBuilder: (context, index) {
                        final item = images[index];
                        return Semantics(
                          label: item.caption ??
                              'Paso ${index + 1}${title.isNotEmpty ? " - $title" : ""}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildImageFromUrl(
                                  item.url,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (item.caption != null && item.caption!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    item.caption!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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

            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final active = index == _currentIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 12 : 8,
                      height: active ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? const Color(0xFF5B8DB3)
                            : Colors.white54,
                      ),
                    );
                  }),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _ttsReady ? () => _speakCaption(_currentIndex) : null,
                icon: const Icon(Icons.volume_up),
                label: const Text('Escuchar'),
              ),
            ),

            // Botón Completar
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _isCompleted
                    ? null
                    : () {
                        setState(() {
                          _isCompleted = true;
                        });
                        widget.onComplete(true, 1);
                      },
                icon: const Icon(Icons.check_circle_rounded, size: 32),
                label: const Text(
                  'COMPLETAR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted
                      ? Colors.grey
                      : const Color(0xFF05E995),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                  shadowColor: const Color.fromARGB(204, 5, 233, 149),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function para construir imágenes desde URLs
  /// Detecta automáticamente si es un asset local o URL externa
  /// Permite usar URLs tal cual están en la base de datos sin agregar prefijos automáticos
  Widget _buildImageFromUrl(
    String url, {
    BoxFit fit = BoxFit.contain,
  }) {
    // Si la URL es una URL externa (http/https), usar Image.network
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 80,
              color: Color(0xFFCCCCCC),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5B8DB3),
            ),
          );
        },
      );
    }

    // Si es un asset local, usar Image.asset directamente con la URL tal cual está
    // No agregamos "assets/" porque la URL ya viene completa desde la BD
    return Image.asset(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: Color(0xFFCCCCCC),
          ),
        );
      },
    );
  }

  List<_StepItem> _parseSteps(Map<String, dynamic> data) {
    // Admite keys steps o pictogramSteps
    final raw = data['steps'] ?? data['pictogramSteps'];
    if (raw == null) return [];
    if (raw is List) {
      final items = <_StepItem>[];
      for (final e in raw) {
        if (e is String && e.trim().isNotEmpty) {
          items.add(_StepItem(url: e.trim()));
        } else if (e is Map) {
          final url = (e['url'] ?? e['src'] ?? '').toString().trim();
          if (url.isEmpty) continue;
          final caption = (e['caption'] ?? e['label'] ?? e['text'])?.toString();
          items.add(_StepItem(url: url, caption: caption));
        }
      }
      return items;
    }
    return [];
  }
}

class _StepItem {
  final String url;
  final String? caption;

  _StepItem({required this.url, this.caption});
}

/// Registrar este minijuego con el factory
/// Debe ser llamado durante la inicialización de la app (main.dart)
void registerPictogramMinigame() {
  MinigameFactory.register(
    MinigameType.pictogram,
    ({required onComplete, required minigameData}) => PictogramMinigame(
      onComplete: onComplete,
      minigameData: minigameData,
    ),
  );
}

