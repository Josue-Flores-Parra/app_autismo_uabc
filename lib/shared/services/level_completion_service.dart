import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/firestore_services.dart';
import '../../features/avatar/viewmodel/avatar_viewmodel.dart';
import '../../features/learning_module/viewmodel/learning_viewmodel.dart';

class LevelCompletionResult {
  final bool success;
  final int attempts;
  final int stars;
  final int coins;

  const LevelCompletionResult({
    required this.success,
    required this.attempts,
    required this.stars,
    required this.coins,
  });
}

/// Centralizes progress persistence and rewards for level completion flows.
class LevelCompletionService {
  /// Estrellas otorgadas por tipo de actividad al completar un nivel.
  ///
  /// - pictogram / video (observación): 1 estrella.
  /// - simple_selection: 3 estrellas.
  /// - puzzle: 2 estrellas.
  /// - audio / desconocido: 0 (reservado para futuras tareas de media).
  static int starsForActivityType(String? actividadType) {
    switch (actividadType?.toLowerCase().trim()) {
      case 'pictogram':
      case 'video':
        return 1;
      case 'simple_selection':
        return 3;
      case 'puzzle':
        return 2;
      default:
        return 0;
    }
  }

  static int calculateCoins(int stars) {
    switch (stars) {
      case 3:
        return 30;
      case 2:
        return 20;
      case 1:
        return 10;
      default:
        return 0;
    }
  }

  static Future<LevelCompletionResult?> completeInteractiveLevel({
    required BuildContext context,
    required String? moduleId,
    required String? levelId,
    required String? actividadType,
    required bool success,
    required int attempts,
    FirestoreService? firestoreService,
  }) async {
    if (moduleId == null || levelId == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final service = firestoreService ?? FirestoreService();

    try {
      final nowIso = DateTime.now().toIso8601String();
      final stars = success ? starsForActivityType(actividadType) : 0;
      final coins = success ? calculateCoins(stars) : 0;

      final progressData = {
        'status': success ? 'completed' : 'in_progress',
        'estrellas': stars,
        'attempts': attempts,
        'completedAt': success ? nowIso : null,
        'updatedAt': nowIso,
      };

      await service.updateUserLevelProgress(
        user.uid,
        moduleId,
        levelId,
        progressData,
      );

      if (success && coins > 0 && context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          await avatarViewModel.agregarMonedas(coins);
        } catch (_) {}
      }

      if (context.mounted) {
        final learningViewModel = context.read<LearningViewModel>();
        await learningViewModel.getModuleLevels(moduleId, forceReload: true);
        await learningViewModel.refreshModulesProgress();
      }

      return LevelCompletionResult(
        success: success,
        attempts: attempts,
        stars: stars,
        coins: coins,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<LevelCompletionResult?> completeObservationLevel({
    required BuildContext context,
    required String? moduleId,
    required String? levelId,
    required String? actividadType,
    FirestoreService? firestoreService,
  }) async {
    if (moduleId == null || levelId == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final service = firestoreService ?? FirestoreService();

    try {
      final stars = starsForActivityType(actividadType);
      final coins = calculateCoins(stars);
      final nowIso = DateTime.now().toIso8601String();

      final progressData = {
        'status': 'completed',
        'estrellas': stars,
        'attempts': 0,
        'completedAt': nowIso,
        'updatedAt': nowIso,
        'type': 'observation',
      };

      await service.updateUserLevelProgress(
        user.uid,
        moduleId,
        levelId,
        progressData,
      );

      if (context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          await avatarViewModel.agregarMonedas(coins);
        } catch (_) {}
      }

      if (context.mounted) {
        final learningViewModel = context.read<LearningViewModel>();
        await learningViewModel.getModuleLevels(moduleId, forceReload: true);
        await learningViewModel.refreshModulesProgress();
      }

      return LevelCompletionResult(
        success: true,
        attempts: 0,
        stars: stars,
        coins: coins,
      );
    } catch (_) {
      return null;
    }
  }
}
