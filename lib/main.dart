import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/learning_module/view/module_list_screen.dart';
import 'features/learning_module/viewmodel/module_list_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para el módulo de learning
        ChangeNotifierProvider(
          create: (_) =>
              ModuleListViewModel(),
        ),
        // Provider para el módulo de avatar (si lo necesitas después)
        // ChangeNotifierProvider(
        //   create: (_) => AvatarViewModel(estadoInicial),
        // ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner:
            false,
        home: const ModuleListScreen(),
      ),
    );
  }
}
