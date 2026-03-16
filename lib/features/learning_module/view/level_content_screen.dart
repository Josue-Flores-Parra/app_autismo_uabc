import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'preview_cards.dart';
import 'fullscreen_view.dart';
import 'level_play_screen.dart';
import '../model/content_card_model.dart';
import '../../../data/services/firestore_services.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../../avatar/viewmodel/avatar_viewmodel.dart';

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
  late PageController _pageController;
  int _selectedCarouselIndex = 0;
  
  // Rastrear condiciones para habilitar el botón "COMPLETAR"
  bool _videoCompleted = false;
  bool _pictogramViewed = false;
  bool _audioCompleted = false;
  
  // Verificar qué tipos de contenido hay
  bool get _hasVideo => widget.contents.any((c) => c.type == ContentType.video);
  bool get _hasPictogram => widget.contents.any((c) => c.type == ContentType.pictogram);
  bool get _hasAudio => widget.contents.any((c) => c.type == ContentType.audio);
  
  // El botón está habilitado si se cumplen todas las condiciones necesarias
  bool get _canComplete {
    bool videoOk = !_hasVideo || _videoCompleted;
    bool pictogramOk = !_hasPictogram || _pictogramViewed;
    bool audioOk = !_hasAudio || _audioCompleted;
    return videoOk && pictogramOk && audioOk;
  }
  
  // Verificar si NO hay actividadType (null, vacío, o cadena "null")
  bool get _hasNoActividadType {
    return widget.actividadType == null || 
        widget.actividadType!.trim().isEmpty || 
        widget.actividadType!.toLowerCase().trim() == 'null';
  }
  
  bool get _isSimpleSelectionEnabled {
    return _asBool(widget.minigameData?['isSimpleSelectionEnabled']);
  }

  ContentCardData? get _selectedContent {
    if (widget.contents.isEmpty) return null;
    final safeIndex = _selectedCarouselIndex.clamp(0, widget.contents.length - 1);
    return widget.contents[safeIndex];
  }

  // Decisión de producto:
  // El botón principal "JUGAR" resuelve en runtime qué actividad abrir según
  // la tarjeta actualmente seleccionada en el carrusel. No dependemos del
  // `actividadType` original del documento para esta navegación.
  bool get _canPlaySelectedContent {
    final selected = _selectedContent;
    if (selected == null) return false;

    switch (selected.type) {
      case ContentType.video:
        final hasVideo = (selected.videoPath?.isNotEmpty == true) ||
            (widget.videoUrl?.isNotEmpty == true) ||
            ((widget.minigameData?['videoUrl'] as String?)?.isNotEmpty == true) ||
            ((widget.minigameData?['url'] as String?)?.isNotEmpty == true);
        return hasVideo;
      case ContentType.pictogram:
      case ContentType.audio:
        return widget.minigameData != null;
      case ContentType.miniGame:
        if (selected.miniGameType == 'simple_selection') {
          return _isSimpleSelectionEnabled && widget.minigameData != null;
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
    _pageController = PageController(viewportFraction: 0.75, initialPage: 0);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
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
                  child: _buildImageFromUrl(widget.bgLevelImg!, fit: BoxFit.cover),
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),

                  const SizedBox(height: 20),

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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final activityType = _selectedActivityType;
                          if (activityType == null) return;

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelPlayScreen(
                                levelTitle: widget.levelTitle ?? widget.levelName,
                                minigameData: widget.minigameData,
                                actividadType: activityType,
                                levelId: widget.levelId ?? '',
                                moduleId: widget.moduleId ?? '',
                                videoUrl: widget.videoUrl,
                                launchSimpleSelectionFromCard:
                                    activityType == 'simple_selection',
                              ),
                            ),
                          );
                          // Recargar datos después de regresar
                          if (context.mounted && widget.moduleId != null) {
                            final learningViewModel = context.read<LearningViewModel>();
                            await learningViewModel.getModuleLevels(widget.moduleId!, forceReload: true);
                          }
                        },
                        icon: Icon(
                          _selectedActivityType == 'video'
                              ? Icons.play_circle_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        label: Text(
                          _selectedActivityType == 'video'
                              ? 'VER VIDEO'
                              : 'JUGAR',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedActivityType == 'video'
                              ? const Color(0xFF5A97B8)
                              : const Color(0xFF00E5FF),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 10,
                          shadowColor: const Color.fromARGB(204, 0, 229, 255),
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
                  padding: const EdgeInsets.only(top: 30), // Mueve el botón un poco más abajo
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
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
              
              // Título (centrado)
              Expanded(
                child: Center(
                  child: Text(
                    widget.levelName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                      height: 1.2, // Ajustar altura de línea para mejor alineación
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

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.contents.length,
      onPageChanged: (index) {
        setState(() {
          _selectedCarouselIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return _buildCarouselItem(index);
      },
    );
  }

  Widget _buildCarouselItem(int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.85, 1.0);
        }

        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 500,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToFullscreen(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: _buildCardContent(widget.contents[index], isPreview: true),
        ),
      ),
    );
  }

  Widget _buildCardContent(ContentCardData data, {required bool isPreview}) {
    switch (data.type) {
      case ContentType.pictogram:
        return PictogramPreviewCard(
          imgPreview: data.imagePath,
          pictogramTitle: data.title,
          pictogramDesc: data.description ?? '',
          isPreview: isPreview,
          onPictogramViewed: () {
            if (mounted) {
              setState(() {
                _pictogramViewed = true;
              });
            }
          },
        );
      case ContentType.video:
        return VideoPreviewCard(
          videoPath: data.videoPath!,
          videoTitle: data.title,
          videoDesc: data.description,
          isPreview: isPreview,
          onVideoCompleted: () {
            if (mounted) {
              setState(() {
                _videoCompleted = true;
              });
            }
          },
        );
      case ContentType.audio:
        return AudioPreviewCard(
          audioPath: data.audioPath!,
          audioTitle: data.title,
          audioDesc: data.description,
          isPreview: isPreview,
          imagePath: data.imagePath.isNotEmpty ? data.imagePath : null,
          onAudioCompleted: () {
            if (mounted) {
              setState(() {
                _audioCompleted = true;
              });
            }
          },
        );
      case ContentType.miniGame:
        return MiniGamePreviewCard(
          gameTitle: data.title,
          imgPreview: data.imagePath,
          gameDesc: data.description,
          isPreview: isPreview,
        );
    }
  }

  void _navigateToFullscreen(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenContentView(
          contents: widget.contents,
          initialIndex: initialIndex,
          levelName: widget.levelName,
          bgLevelImg: widget.bgLevelImg,
          onVideoCompleted: () {
            if (mounted) {
              setState(() {
                _videoCompleted = true;
              });
            }
          },
          onPictogramViewed: () {
            if (mounted) {
              setState(() {
                _pictogramViewed = true;
              });
            }
          },
          onAudioCompleted: () {
            if (mounted) {
              setState(() {
                _audioCompleted = true;
              });
            }
          },
        ),
      ),
    );
  }

  /// Guarda el progreso para niveles de solo observación (sin minijuego)
  /// Otorga 2 estrellas y 20 monedas por completar el nivel
  Future<void> _handleCompleteObservationLevel(BuildContext context) async {
    if (widget.levelId == null || widget.moduleId == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final firestoreService = FirestoreService();
      
      // Para niveles de solo observación, otorgamos 2 estrellas
      final stars = 2;
      final coins = 20; // 20 monedas por 2 estrellas
      
      final progressData = {
        'status': 'completed',
        'estrellas': stars,
        'attempts': 0, // No hay intentos en niveles de observación
        'completedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'type': 'observation', // Marcar como nivel de observación
      };

      await firestoreService.updateUserLevelProgress(
        user.uid,
        widget.moduleId!,
        widget.levelId!,
        progressData,
      );

      // Otorgar monedas
      if (context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          await avatarViewModel.agregarMonedas(coins);
        } catch (e) {
          // Error al agregar monedas, pero no bloqueamos la UI
        }
      }

      // Limpiar caché del módulo para forzar recarga
      if (context.mounted) {
        final learningViewModel = context.read<LearningViewModel>();
        await learningViewModel.getModuleLevels(widget.moduleId!, forceReload: true);
      }

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Nivel completado! +$stars +$coins',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF05E995),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Cerrar la pantalla después de un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // Error al guardar, mostrar mensaje
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el progreso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          return const Center(
            child: CircularProgressIndicator(),
          );
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
