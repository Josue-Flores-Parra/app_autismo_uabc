import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:confetti/confetti.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
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
  bool _imagesPrecached = false;
  int _imagesLoadedCount = 0;
  int _totalImagesCount = 0;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _autoSpeakTriggered = false;
  late ConfettiController _confettiController;
  final AudioPlayer _celebrationPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _steps = _parseSteps(widget.minigameData);
    _initTts();
    _initConfetti();
    // Precargar imágenes después del primer frame para asegurar que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAllImages();
    });
  }

  void _initConfetti() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    _confettiController.dispose();
    _celebrationPlayer.dispose();
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

  /// Precarga todas las imágenes del carrusel al inicializar el widget
  /// Esto evita que las imágenes tarden en cargar cuando el usuario hace scroll
  Future<void> _precacheAllImages() async {
    if (!mounted) return;
    
    // Obtener todas las URLs que se van a mostrar
    final pictogramaUrl = widget.minigameData['pictogramaUrl'] as String?;
    final List<String> urlsToPrecache = [];
    
    // Si hay steps, usar esos
    if (_steps.isNotEmpty) {
      urlsToPrecache.addAll(_steps.map((item) => item.url));
    } 
    // Si no hay steps pero hay un pictogramaUrl único, usar ese
    else if (pictogramaUrl != null && pictogramaUrl.isNotEmpty) {
      urlsToPrecache.add(pictogramaUrl);
    }
    
    // Si no hay imágenes que precargar, marcar como listo
    if (urlsToPrecache.isEmpty) {
      if (mounted) {
        setState(() => _imagesPrecached = true);
      }
      return;
    }

    // Establecer el total de imágenes a cargar
    _totalImagesCount = urlsToPrecache.length;
    if (mounted) {
      setState(() {
        _imagesLoadedCount = 0;
      });
    }

    try {
      // Precargar todas las imágenes en paralelo esperando a que se completen completamente
      final futures = urlsToPrecache.map((url) => _precacheImageCompletely(url));
      
      // Esperar a que todas las imágenes se carguen completamente
      // Usar Future.wait con eagerError: false para que continúe aunque algunas fallen
      await Future.wait(futures, eagerError: false);
    } catch (e) {
      // Si hay un error al precargar, continuar de todas formas
    } finally {
      // Solo marcar como precargado cuando realmente todas estén listas
      if (mounted) {
        setState(() {
          _imagesPrecached = true;
        });
      }
    }
  }

  /// Descarga y guarda una imagen de red localmente, o precarga un asset local
  Future<void> _precacheImageCompletely(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Para imágenes de red: descargar y guardar localmente
      await _downloadAndCacheImage(url);
    } else {
      // Para assets locales: solo precargar en memoria
      await _precacheLocalAsset(url);
    }
    
    // Actualizar el contador
    if (mounted) {
      setState(() {
        _imagesLoadedCount++;
      });
    }
  }

  /// Descarga una imagen de red y la guarda en el caché local del dispositivo
  Future<void> _downloadAndCacheImage(String url) async {
    try {
      // Obtener el directorio de caché
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory(path.join(cacheDir.path, 'pictogram_images'));
      
      // Crear el directorio si no existe
      if (!await imageCacheDir.exists()) {
        await imageCacheDir.create(recursive: true);
      }
      
      // Generar un nombre de archivo único basado en la URL
      final uri = Uri.parse(url);
      final fileName = path.basename(uri.path);
      final fileExtension = path.extension(fileName).isEmpty ? '.jpg' : path.extension(fileName);
      final cacheFileName = '${_urlToHash(url)}$fileExtension';
      final cachedImagePath = path.join(imageCacheDir.path, cacheFileName);
      final cachedImageFile = File(cachedImagePath);
      
      // Si ya existe en caché, verificar que esté completo
      if (await cachedImageFile.exists()) {
        final fileSize = await cachedImageFile.length();
        if (fileSize > 0) {
          // La imagen ya está en caché, precargarla en memoria
          await _precacheCachedFile(cachedImagePath);
          return;
        }
      }
      
      // Descargar la imagen
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Timeout al descargar imagen');
        },
      );
      
      if (response.statusCode == 200) {
        // Guardar la imagen en el archivo
        await cachedImageFile.writeAsBytes(response.bodyBytes);
        
        // Precargar la imagen desde el archivo local
        await _precacheCachedFile(cachedImagePath);
      } else {
        throw Exception('Error HTTP ${response.statusCode} al descargar $url');
      }
    } catch (e) {
      // Si falla la descarga, intentar usar NetworkImage como respaldo
      if (!mounted) return;
      try {
        final imageProvider = NetworkImage(url);
        await precacheImage(imageProvider, context);
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        final completer = Completer<void>();
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo image, bool synchronousCall) {
            if (!completer.isCompleted) {
              completer.complete();
            }
            stream.removeListener(listener);
          },
          onError: (exception, stackTrace) {
            if (!completer.isCompleted) {
              completer.complete();
            }
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        await completer.future.timeout(const Duration(seconds: 10));
        stream.removeListener(listener);
      } catch (_) {
        // Si también falla, continuar sin bloquear
      }
    }
  }

  /// Precarga un archivo de imagen desde el caché local
  Future<void> _precacheCachedFile(String filePath) async {
    if (!mounted) return;
    try {
      final imageProvider = FileImage(File(filePath));
      await precacheImage(imageProvider, context);
      
      // Esperar a que el ImageStream se complete
      final stream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(const Duration(seconds: 10));
      stream.removeListener(listener);
    } catch (e) {
    }
  }

  /// Precarga un asset local
  Future<void> _precacheLocalAsset(String url) async {
    if (!mounted) return;
    try {
      final imageProvider = AssetImage(url);
      await precacheImage(imageProvider, context);
      
      // Esperar a que el ImageStream se complete
      final stream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(const Duration(seconds: 10));
      stream.removeListener(listener);
    } catch (e) {
    }
  }

  /// Convierte una URL a un hash para usarlo como nombre de archivo
  String _urlToHash(String url) {
    return url.hashCode.toString().replaceAll('-', '');
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // Mostrar indicador de carga mientras se precargan las imágenes
    if (!_imagesPrecached) {
      final progress = _totalImagesCount > 0 
          ? _imagesLoadedCount / _totalImagesCount 
          : 0.0;
      
      return Scaffold(
        backgroundColor: const Color(0xFF091F2C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF5B8DB3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cargando imágenes...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              if (_totalImagesCount > 0) ...[
                const SizedBox(height: 16),
                Text(
                  '$_imagesLoadedCount / $_totalImagesCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B8DB3)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Activar TTS automáticamente cuando se muestre la vista principal por primera vez
    if (_imagesPrecached && !_autoSpeakTriggered && _ttsReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_autoSpeakTriggered) {
          _autoSpeakTriggered = true;
          _speakCaption(0);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF091F2C),
      body: Stack(
        children: [
          SafeArea(
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
                            padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0, bottom: 8.0),
                            child: Text(
                              item.caption!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
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

            // Botón Escuchar abajo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: _ttsReady ? () => _speakCaption(_currentIndex) : null,
                icon: const Icon(Icons.volume_up, size: 28),
                label: const Text(
                  'Escuchar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),

            // Botón Completar - Solo se muestra en la última imagen
            if (_currentIndex == images.length - 1)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _isCompleted
                      ? null
                      : () async {
                          setState(() {
                            _isCompleted = true;
                          });
                          // Reproducir sonido de felicitación y mostrar confettis
                          _celebrateCompletion(); // No esperar para que no bloquee la UI
                          // Esperar un momento antes de completar para que se vea la celebración
                          await Future.delayed(const Duration(milliseconds: 1500));
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
          // Confettis overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Hacia abajo
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reproduce el sonido de felicitación y muestra los confettis
  void _celebrateCompletion() {
    // Iniciar confettis inmediatamente
    _confettiController.play();
    
    // Reproducir sonido de felicitación de forma asíncrona
    _playCelebrationSound();
  }

  /// Reproduce el sonido de celebración de forma asíncrona
  Future<void> _playCelebrationSound() async {
    try {
      await _configureAudioSession();
      try {
        await _celebrationPlayer.setAudioSource(
          AudioSource.asset('assets/audio/celebration.mp3'),
        );
        await _celebrationPlayer.setVolume(1.0);
        if (_celebrationPlayer.processingState == ProcessingState.loading) {
          await _celebrationPlayer.playerStateStream
              .timeout(const Duration(seconds: 3))
              .firstWhere(
            (state) => state.processingState != ProcessingState.loading,
          );
        }
        await _celebrationPlayer.play();
      } catch (e, stackTrace) {
        if (_ttsReady) {
          try {
            await _tts.speak('¡Felicitaciones! ¡Nivel completado!');
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Obtiene la ruta del archivo en caché para una URL de red
  Future<String?> _getCachedImagePath(String url) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory(path.join(cacheDir.path, 'pictogram_images'));
      
      if (!await imageCacheDir.exists()) {
        return null;
      }
      
      final uri = Uri.parse(url);
      final fileName = path.basename(uri.path);
      final fileExtension = path.extension(fileName).isEmpty ? '.jpg' : path.extension(fileName);
      final cacheFileName = '${_urlToHash(url)}$fileExtension';
      final cachedImagePath = path.join(imageCacheDir.path, cacheFileName);
      final cachedImageFile = File(cachedImagePath);
      
      if (await cachedImageFile.exists()) {
        final fileSize = await cachedImageFile.length();
        if (fileSize > 0) {
          return cachedImagePath;
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// Helper function para construir imágenes desde URLs
  /// Detecta automáticamente si es un asset local o URL externa
  /// Para URLs de red, intenta usar la versión en caché primero
  Widget _buildImageFromUrl(
    String url, {
    BoxFit fit = BoxFit.contain,
  }) {
    // Si la URL es una URL externa (http/https), intentar usar la versión en caché
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return FutureBuilder<String?>(
        future: _getCachedImagePath(url),
        builder: (context, snapshot) {
          // Si hay una versión en caché, usarla
          if (snapshot.hasData && snapshot.data != null) {
            final cachedPath = snapshot.data!;
            final cachedFile = File(cachedPath);
            if (cachedFile.existsSync()) {
              return Image.file(
                cachedFile,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  // Si falla el archivo en caché, intentar con NetworkImage
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
                  );
                },
              );
            }
          }
          
          // Si no hay caché o está cargando, usar NetworkImage
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
                  strokeWidth: 2,
                ),
              );
            },
          );
        },
      );
    }

    // Si es un asset local, usar Image.asset directamente con la URL tal cual está
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
