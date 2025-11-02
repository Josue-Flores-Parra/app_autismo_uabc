enum ContentType { pictogram, video, miniGame }

class ContentCardData {
  final ContentType type;
  final String title;
  final String? description;
  final String imagePath;
  final String? videoPath;

  ContentCardData({
    required this.type,
    required this.title,
    this.description,
    required this.imagePath,
    this.videoPath,
  });
}
