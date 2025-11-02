import 'package:flutter/material.dart';
import 'preview_cards.dart';
import 'fullscreen_view.dart';
import '../model/content_card_model.dart';

class LevelContentPreviewScreen extends StatefulWidget {
  final String levelName;
  final String? bgLevelImg;
  final List<ContentCardData> contents;

  const LevelContentPreviewScreen({
    super.key,
    required this.levelName,
    this.bgLevelImg,
    required this.contents,
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
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 0,
    );

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
            colors: [
              Color(0xF20D3B52),
              Color(0xFF091F2C),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (widget.bgLevelImg != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    widget.bgLevelImg!,
                    fit: BoxFit.cover,
                  ),
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
          colors: [
            Color(0xFF2C5F7A),
            Color(0xFF1A3D52),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0x66FFFFFF),
          width: 1.5,
        ),
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
}
