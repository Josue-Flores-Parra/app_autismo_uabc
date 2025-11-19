import 'dart:async';
import 'package:flutter/material.dart';
import '../../minigame_core.dart';
import '../../../learning_module/viewmodel/audio_viewmodel.dart';
import 'simple_selection_minigame.dart'; // Para _buildImageFromPath

/// Minijuego de Audio
/// Reproduce un audio/música completo como actividad del nivel
/// El usuario debe escuchar el audio y luego presionar "Completar" para finalizar
class AudioMinigame extends MinigameBase {
  const AudioMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<AudioMinigame> createState() => _AudioMinigameState();
}

class _AudioMinigameState extends State<AudioMinigame> {
  AudioViewModel? _viewModel;
  bool _isCompleted = false;
  bool _isDisposed = false;
  bool _audioFinished = false; // Rastrear si el audio se reprodujo completamente
  bool _hasError = false; // Rastrear si hay un error al cargar el audio
  String? _errorMessage; // Mensaje de error
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  void _initializeAudio() {
    // Debug: imprimir todos los datos recibidos
    debugPrint('AudioMinigame - minigameData recibido: ${widget.minigameData}');
    
    // Obtener la URL del audio desde minigameData
    final audioUrl = widget.minigameData['audioUrl'] as String?;
    
    debugPrint('AudioMinigame - audioUrl extraído: $audioUrl');
    
    // Crear el ViewModel siempre, incluso si hay error
    _viewModel = AudioViewModel();
    
    // Agregar listener para actualizar la UI cuando cambie el estado del audio
    _viewModel!.addListener(() {
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    });
    
    if (audioUrl == null || audioUrl.isEmpty) {
      // Si no hay audio, mostrar error pero NO completar automáticamente
      debugPrint('AudioMinigame - ERROR: audioUrl es null o vacío');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No se encontró el archivo de audio en actividadData';
        });
      }
      return;
    }

    _viewModel!.initialize(audioUrl).then((_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = false;
          _errorMessage = null;
        });
        
        // Iniciar el timer solo si el audio se cargó correctamente
        _startPositionTimer();
      }
    }).catchError((error) {
      debugPrint('Error al inicializar audio: $error');
      debugPrint('Ruta intentada: $audioUrl');
      // Mostrar error pero NO completar automáticamente
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar el audio. Verifica la ruta: $audioUrl';
        });
      }
    });
  }
  
  void _startPositionTimer() {
    // Verificar periódicamente si el audio se completó (100%)
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _isDisposed || _viewModel == null) {
        timer.cancel();
        return;
      }
      
      // Verificar si el audio se completó completamente (100%)
      final position = _viewModel!.position;
      final duration = _viewModel!.duration;
      
      if (duration != null && duration.inMilliseconds > 0) {
        final isAtEnd = position >= duration;
        
        // Solo habilitar el botón cuando el audio llegue al final (100%)
        if (isAtEnd && !_audioFinished) {
          setState(() {
            _audioFinished = true; // Marcar que el audio se reprodujo completamente
          });
        }
        
        // Si el usuario reinicia el audio, resetear el flag
        if (!isAtEnd && _audioFinished && position < duration * 0.1) {
          setState(() {
            _audioFinished = false;
          });
        }
      }
      
      setState(() {});
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionTimer?.cancel();
    _viewModel?.dispose();
    _viewModel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioUrl = widget.minigameData['audioUrl'] as String?;
    final pictogramaUrl = widget.minigameData['pictogramaUrl'] as String?;
    final videoUrl = widget.minigameData['videoUrl'] as String?;
    final title = widget.minigameData['title'] as String? ?? 
                  widget.minigameData['titulo'] as String? ?? 
                  'Audio';
    final description = widget.minigameData['description'] as String? ?? 
                       widget.minigameData['descripcion'] as String?;

    // Si no hay ViewModel, mostrar loading o error
    if (_viewModel == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF091F2C),
        body: Center(
          child: _hasError
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 80, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage ?? 'Error al cargar el audio',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(
                  color: Color(0xFF05E995),
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF091F2C),
      body: SafeArea(
        child: Column(
          children: [
            // Header con título y descripción
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (description != null && description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Mostrar mensaje de error si hay uno
                  if (_hasError && _errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Imagen de fondo o pictograma (si está disponible)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: pictogramaUrl != null && pictogramaUrl.isNotEmpty
                      ? _buildImageFromPath(pictogramaUrl)
                      : const Icon(
                          Icons.music_note,
                          size: 120,
                          color: Color(0xFF05E995),
                        ),
                ),
              ),
            ),

            // Controles de audio
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Barra de progreso
                  if (_viewModel!.duration != null)
                    Column(
                      children: [
                        Slider(
                          value: _viewModel!.position.inMilliseconds.toDouble().clamp(
                            0.0,
                            _viewModel!.duration!.inMilliseconds.toDouble(),
                          ),
                          min: 0.0,
                          max: _viewModel!.duration!.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            if (_viewModel != null && !_isDisposed && mounted) {
                              _viewModel!.seek(Duration(milliseconds: value.toInt()));
                            }
                          },
                          activeColor: const Color(0xFF05E995),
                          inactiveColor: Colors.white24,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _viewModel!.formatDuration(_viewModel!.position),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _viewModel!.formatDuration(_viewModel!.duration!),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Controles de reproducción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón de reiniciar
                      IconButton(
                        icon: const Icon(Icons.replay, color: Colors.white, size: 32),
                        onPressed: _isCompleted
                            ? null
                            : () {
                                if (_viewModel != null && !_isDisposed && mounted) {
                                  _viewModel!.replay();
                                }
                              },
                      ),

                      const SizedBox(width: 20),

                      // Botón de play/pause
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF05E995),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF05E995).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _viewModel!.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _isCompleted
                              ? null
                              : () {
                                  debugPrint('Botón play/pause presionado');
                                  debugPrint('Estado actual: isPlaying=${_viewModel!.isPlaying}, volume=${_viewModel!.volume}');
                                  if (_viewModel != null && !_isDisposed && mounted) {
                                    _viewModel!.togglePlayPause();
                                  }
                                },
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Control de volumen
                      Column(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white, size: 24),
                          SizedBox(
                            width: 100,
                            child: Slider(
                              value: _viewModel!.volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                if (_viewModel != null && !_isDisposed && mounted) {
                                  _viewModel!.setVolume(value);
                                }
                              },
                              activeColor: const Color(0xFF05E995),
                              inactiveColor: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botón Completar (solo habilitado cuando el audio se reprodujo completamente)
                  ElevatedButton.icon(
                    onPressed: (_isCompleted || !_audioFinished)
                        ? null
                        : () {
                            setState(() {
                              _isCompleted = true;
                            });
                            widget.onComplete(true, 1);
                          },
                    icon: Icon(
                      _isCompleted ? Icons.check_circle_outline : Icons.lock_outline,
                      color: _isCompleted || !_audioFinished ? Colors.white70 : Colors.white,
                      size: 32,
                    ),
                    label: Text(
                      _isCompleted 
                          ? 'COMPLETADO' 
                          : (!_audioFinished ? 'ESCUCHA TODO EL AUDIO' : 'COMPLETAR'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isCompleted || !_audioFinished ? Colors.white70 : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted 
                          ? Colors.grey 
                          : (!_audioFinished ? Colors.grey.shade600 : const Color(0xFF05E995)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: (_isCompleted || !_audioFinished) ? 0 : 10,
                      shadowColor: (_isCompleted || !_audioFinished) 
                          ? Colors.transparent 
                          : const Color.fromARGB(204, 5, 233, 149),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function para construir imágenes desde paths
  /// Detecta automáticamente si es un asset local o URL externa
  Widget _buildImageFromPath(String path) {
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
}

/// Registrar este minijuego con el factory
void registerAudioMinigame() {
  MinigameFactory.register(
    MinigameType.audio,
    ({required onComplete, required minigameData}) => AudioMinigame(
      onComplete: onComplete,
      minigameData: minigameData,
    ),
  );
}

