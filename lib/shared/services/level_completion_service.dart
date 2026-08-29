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
  static int calculateStars(int attempts) {
    if (attempts <= 1) return 3;
    if (attempts == 2) return 2;
    return 1;
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
      final stars = success ? calculateStars(attempts) : 0;
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
    FirestoreService? firestoreService,
  }) async {
    if (moduleId == null || levelId == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final service = firestoreService ?? FirestoreService();

    try {
      const stars = 2;
      const coins = 20;
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
      }

      return const LevelCompletionResult(
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
