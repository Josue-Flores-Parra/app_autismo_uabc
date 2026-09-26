import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../model/learner_profile.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'profile_screens.dart';

/// Per-child settings, opened from the parent hub with the Edit action.
///
/// Only learning and accessibility preferences live here: name, allowed
/// modules, text size, contrast, animations, feedback, reminders and progress
/// reset. Account-wide choices (theme, language, legal, telemetry) stay in
/// the global settings screen.
class ChildSettingsScreen extends StatelessWidget {
  const ChildSettingsScreen({super.key, required this.learnerId});

  final String learnerId;

  LearnerProfile? _learnerOf(ProfileViewModel profiles) {
    for (final learner in profiles.learners) {
      if (learner.id == learnerId) return learner;
    }
    return null;
  }

  Future<void> _save(
    BuildContext context,
    LearnerProfile learner,
    LearnerSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<ProfileViewModel>().updateLearnerSettings(
        learner,
        settings,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
      }
    }
  }

  Future<void> _editName(BuildContext context, LearnerProfile learner) async {
    final l10n = AppLocalizations.of(context);
    final result = await showProfileDetailsDialog(
      context: context,
      title: l10n.childEditName,
      confirmLabel: l10n.confirm,
      initialName: learner.name,
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    try {
      await context.read<ProfileViewModel>().renameLearner(
        learner,
        result.name,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
      }
    }
  }

  Future<void> _resetProgress(
    BuildContext context,
    ProfileViewModel profiles,
    LearnerProfile learner,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileResetTitle),
        content: Text(l10n.profileResetPrompt(learner.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.profileReset),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await profiles.clearLearnerProgress(learner);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileResetDone(learner.name))),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
      }
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    LearnerProfile learner,
  ) async {
    final parts = learner.settings.reminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null || !context.mounted) return;
    final formatted =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    await _save(
      context,
      learner,
      learner.settings.copyWith(reminderTime: formatted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final profiles = context.watch<ProfileViewModel>();
    final learner = _learnerOf(profiles);
    if (learner == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.childSettingsTitle(''))),
        body: Center(child: Text(l10n.profileLoadFailed)),
      );
    }
    final settings = learner.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.childSettingsTitle(learner.name))),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _ChildSection(
                    title: l10n.childSectionProfile,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.accentSoft,
                          child: Icon(Icons.face_rounded, color: colors.accent),
                        ),
                        title: Text(learner.name),
                        trailing: IconButton(
                          tooltip: l10n.childEditName,
                          icon: const Icon(Icons.edit_outlined),
                          color: colors.accent,
                          onPressed: () => _editName(context, learner),
                        ),
                      ),
                    ],
                  ),
                  _ChildSection(
                    title: l10n.childSectionLearning,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(l10n.profileAllowedModules),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: DropdownButtonFormField<int>(
                          initialValue: learner.allowedModules,
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(l10n.parentalNoLimit),
                            ),
                            for (var count = 1; count <= 10; count++)
                              DropdownMenuItem(
                                value: count,
                                child: Text(
                                  '$count ${l10n.parentalModulesUnit}',
                                ),
                              ),
                          ],
                          onChanged: (value) async {
                            if (value == null || !context.mounted) return;
                            try {
                              await profiles.setLearnerAllowedModules(
                                learner,
                                value,
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.profileSaveFailed),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.refresh_rounded,
                          color: colors.warning,
                        ),
                        title: Text(l10n.profileReset),
                        subtitle: Text(l10n.profileResetHint),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _resetProgress(context, profiles, learner),
                      ),
                    ],
                  ),
                  _ChildSection(
                    title: l10n.childSectionDisplay,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(l10n.fontSizeLabel),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final option in ['small', 'medium', 'large'])
                              ChoiceChip(
                                label: Text(
                                  option == 'small'
                                      ? l10n.fontSmall
                                      : option == 'large'
                                      ? l10n.fontLarge
                                      : l10n.fontMedium,
                                ),
                                selected: settings.fontScale == option,
                                onSelected: (_) => _save(
                                  context,
                                  learner,
                                  settings.copyWith(fontScale: option),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: Text(l10n.highContrast),
                        value: settings.highContrast,
                        onChanged: (value) => _save(
                          context,
                          learner,
                          settings.copyWith(highContrast: value),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(l10n.reduceAnimations),
                        value: settings.reduceAnimations,
                        onChanged: (value) => _save(
                          context,
                          learner,
                          settings.copyWith(reduceAnimations: value),
                        ),
                      ),
                    ],
                  ),
                  _ChildSection(
                    title: l10n.childSectionFeedback,
                    children: [
                      SwitchListTile(
                        title: Text(l10n.audioFeedback),
                        value: settings.audioFeedback,
                        onChanged: (value) => _save(
                          context,
                          learner,
                          settings.copyWith(audioFeedback: value),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(l10n.hapticFeedback),
                        value: settings.hapticFeedback,
                        onChanged: (value) => _save(
                          context,
                          learner,
                          settings.copyWith(hapticFeedback: value),
                        ),
                      ),
                    ],
                  ),
                  _ChildSection(
                    title: l10n.childSectionReminders,
                    children: [
                      SwitchListTile(
                        title: Text(l10n.enableReminders),
                        value: settings.remindersEnabled,
                        onChanged: (value) => _save(
                          context,
                          learner,
                          settings.copyWith(remindersEnabled: value),
                        ),
                      ),
                      ListTile(
                        title: Text(l10n.scheduleReminder),
                        subtitle: Text(
                          settings.remindersEnabled
                              ? '${settings.reminderTime} · ${l10n.reminderNotImplemented}'
                              : l10n.reminderPlaceholder,
                        ),
                        trailing: const Icon(Icons.schedule),
                        enabled: settings.remindersEnabled,
                        onTap: settings.remindersEnabled
                            ? () => _pickReminderTime(context, learner)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildSection extends StatelessWidget {
  const _ChildSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colors.inkSoft,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
