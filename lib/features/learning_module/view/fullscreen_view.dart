import 'package:flutter/material.dart';
import 'preview_cards.dart';
import '../model/content_card_model.dart';

class FullScreenContentView extends StatefulWidget {
  final List<ContentCardData> contents;
  final int initialIndex;
  final String levelName;
  final String? bgLevelImg;

  const FullScreenContentView({
    super.key,
    required this.contents,
    required this.initialIndex,
    required this.levelName,
    this.bgLevelImg,
  });

  @override
  State<FullScreenContentView> createState() => _FullScreenContentViewState();
}

class _FullScreenContentViewState extends State<FullScreenContentView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 1.0, // Fullscreen
    );

    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
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
            colors: [
              Color(0xF20D3B52), // Color de referencia
              Color(0xFF091F2C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondo opcional
            if (widget.bgLevelImg != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(widget.bgLevelImg!, fit: BoxFit.cover),
                ),
              ),

            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  // Header con botón atrás
                  _buildHeader(),

                  const SizedBox(height: 10),

                  // PageView con las cards en fullscreen
                  Expanded(child: _buildPageView()),

                  const SizedBox(height: 10),

                  // Indicadores de página actual
                  _buildPageIndicators(),

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            blurRadius: 15,
            offset: Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón atrás
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              iconSize: 22,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Título
          Expanded(
            child: Text(
              widget.levelName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Espaciador para centrar
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.contents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildFullscreenCard(widget.contents[index]),
        );
      },
    );
  }

  Widget _buildFullscreenCard(ContentCardData data) {
    switch (data.type) {
      case ContentType.pictogram:
        return PictogramPreviewCard(
          imgPreview: data.imagePath,
          pictogramTitle: data.title,
          pictogramDesc: data.description ?? '',
          isPreview: false, // Modo fullscreen
        );
      case ContentType.video:
        return VideoPreviewCard(
          videoPath: data.videoPath!,
          videoTitle: data.title,
          videoDesc: data.description,
          isPreview: false, // Modo fullscreen
        );
      case ContentType.audio:
        return AudioPreviewCard(
          audioPath: data.audioPath!,
          audioTitle: data.title,
          audioDesc: data.description,
          isPreview: false, // Modo fullscreen
          imagePath: data.imagePath.isNotEmpty ? data.imagePath : null,
        );
      case ContentType.miniGame:
        return MiniGamePreviewCard(
          gameTitle: data.title,
          imgPreview: data.imagePath,
          gameDesc: data.description,
          isPreview: false, // Modo fullscreen
        );
    }
  }

  Widget _buildPageIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.contents.length,
          (index) => _buildIndicator(index),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isActive ? const Color(0xFF5A97B8) : const Color(0x66FFFFFF),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x665A97B8),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}
