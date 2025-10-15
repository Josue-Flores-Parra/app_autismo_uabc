import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_autismo_uabc/features/learning_module/view/level_timeline_screen.dart';
import 'package:app_autismo_uabc/features/learning_module/viewmodel/level_timeline_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String moduleId =
        'Higiene_01';

    return MaterialApp(
      title: 'Level Timeline Test',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      home: ChangeNotifierProvider(
        create: (context) =>
            LevelTimelineViewModel(
              moduleId,
            ),
        child: const LevelTimelineScreen(
          moduleId: moduleId,
          backgroundImagePath:
              'assets/images/LevelBGs/Higiene/HigieneModuloBG.png',
        ),
      ),
    );
  }
}
