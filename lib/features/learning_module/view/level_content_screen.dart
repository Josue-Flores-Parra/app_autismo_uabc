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
  });

  @override
  State<LevelContentPreviewScreen> createState() =>
      _LevelContentPreviewScreenState();
}

class _LevelContentPreviewScreenState extends State<LevelContentPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late PageController _pageController;

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
                  
                  // Botón "JUGAR" si hay datos del minijuego
                  if (widget.minigameData != null && widget.actividadType != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelPlayScreen(
                                levelTitle: widget.levelTitle ?? widget.levelName,
                                minigameData: widget.minigameData!,
                                actividadType: widget.actividadType!,
                                levelId: widget.levelId ?? '',
                                moduleId: widget.moduleId ?? '',
                              ),
                            ),
                          );
                          // Recargar datos después de regresar
                          if (context.mounted && widget.moduleId != null) {
                            final learningViewModel = context.read<LearningViewModel>();
                            await learningViewModel.getModuleLevels(widget.moduleId!, forceReload: true);
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
                          backgroundColor: const Color(0xFF00E5FF),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 10,
                          shadowColor: const Color.fromARGB(204, 0, 229, 255),
                        ),
                      ),
                    ),
                  
                  // Botón "COMPLETAR" si NO hay minijuego (solo contenido de observación)
                  if ((widget.minigameData == null || widget.actividadType == null) && 
                      widget.levelId != null && widget.moduleId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCompleteObservationLevel(context),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                        label: const Text(
                          'COMPLETAR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF05E995),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 10,
                          shadowColor: const Color.fromARGB(204, 5, 233, 149),
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
          Text(
            widget.levelName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
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
        );
      case ContentType.video:
        return VideoPreviewCard(
          videoPath: data.videoPath!,
          videoTitle: data.title,
          videoDesc: data.description,
          isPreview: isPreview,
        );
      case ContentType.audio:
        return AudioPreviewCard(
          audioPath: data.audioPath!,
          audioTitle: data.title,
          audioDesc: data.description,
          isPreview: isPreview,
          imagePath: data.imagePath.isNotEmpty ? data.imagePath : null,
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
                    '¡Nivel completado! +$stars ⭐ +$coins 🪙',
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
