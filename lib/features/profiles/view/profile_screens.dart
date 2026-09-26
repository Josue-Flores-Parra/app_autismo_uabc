import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../settings/view/settings_page.dart';
import 'child_settings_screen.dart';
import '../model/learner_profile.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfileSelectorScreen extends StatelessWidget {
  const ProfileSelectorScreen({super.key});

  static Future<void> confirmMigratedName(
    BuildContext context,
    LearnerProfile learner,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showProfileDetailsDialog(
      context: context,
      title: l10n.profileLegacyTitle,
      confirmLabel: l10n.profileConfirmName,
      initialName: learner.name,
      barrierDismissible: false,
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    try {
      final profiles = context.read<ProfileViewModel>();
      await profiles.renameLearner(learner, result.name);
      if (!context.mounted) return;
      profiles.confirmLegacyName();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
      }
    }
  }

  static Future<void> addLearner(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showProfileDetailsDialog(
      context: context,
      title: l10n.profileAddTitle,
      confirmLabel: l10n.confirm,
      submitOnKeyboard: true,
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    try {
      await context.read<ProfileViewModel>().addLearner(result.name);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
      }
    }
  }

  /// Opens the per-child settings for [learner] from the parent hub.
  static void openChildSettings(BuildContext context, LearnerProfile learner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChildSettingsScreen(learnerId: learner.id),
      ),
    );
  }

  /// Runs [action] immediately when the parent session is unlocked, or asks
  /// for the PIN first and then continues automatically on success. Selecting
  /// a child never asks: it stays one tap.
  static Future<void> _withParentUnlock(
    BuildContext context,
    ProfileViewModel profiles,
    Future<void> Function() action,
  ) async {
    if (!await profiles.ensureParentUnlocked(context)) return;
    if (!context.mounted) return;
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final profiles = context.watch<ProfileViewModel>();
    // Single family hub: the same heading and layout for locked and unlocked
    // sessions. Only the management actions gate on the PIN; entering a
    // profile stays one tap.
    final title = profiles.needsInitialLearner
        ? l10n.profileWelcomeTitle
        : l10n.profileHubTitle;
    final body = profiles.needsInitialLearner
        ? l10n.profileWelcomeBody
        : l10n.profileHubBody;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/presets/appy_happy_preset.png',
                    height: 130,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 28,
                      color: colors.ink,
                    ),
                  ),
                  if (profiles.didMigrateLegacy) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                            child: Text(l10n.profileLegacyMigrated),
                          ),
                          TextButton.icon(
                            onPressed: profiles.learners.isEmpty
                                ? null
                                : () => confirmMigratedName(
                                    context,
                                    profiles.learners.first,
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.profileConfirmName),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (profiles.error != null)
                    _Notice(
                      text: l10n.profileLoadFailed,
                      isError: true,
                      onRetry: profiles.retryLoad,
                    ),
                  for (final learner in profiles.learners)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProfileCard(
                        learner: learner,
                        pending: learner.needsNameConfirmation,
                        onTap: profiles.didMigrateLegacy
                            ? null
                            : () => profiles.selectLearner(learner),
                        onEdit: profiles.didMigrateLegacy
                            ? null
                            : () => _withParentUnlock(
                                context,
                                profiles,
                                () async {
                                  if (!context.mounted) return;
                                  openChildSettings(context, learner);
                                },
                              ),
                      ),
                    ),
                  if (!profiles.needsInitialLearner &&
                      !profiles.didMigrateLegacy)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: colors.accent,
                        ),
                        title: Text(l10n.profileOpenSettings),
                        subtitle: Text(l10n.profileOpenSettingsBody),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _withParentUnlock(context, profiles, () async {
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            }),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed:
                        profiles.didMigrateLegacy || profiles.error != null
                        ? null
                        : () => _withParentUnlock(
                            context,
                            profiles,
                            () => addLearner(context),
                          ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      profiles.needsInitialLearner
                          ? l10n.profileAddFirst
                          : l10n.profileAddTitle,
                    ),
                  ),
                  if (profiles.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
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

typedef ProfileDetailsResult = ({String name, int? allowedModules});

Future<ProfileDetailsResult?> showProfileDetailsDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String initialName = '',
  int? allowedModules,
  bool barrierDismissible = true,
  bool submitOnKeyboard = false,
}) async {
  final route = DialogRoute<ProfileDetailsResult>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => _ProfileDetailsDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
      allowedModules: allowedModules,
      canCancel: barrierDismissible,
      submitOnKeyboard: submitOnKeyboard,
    ),
  );
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  // Navigator.pop completes before the dialog's reverse animation finishes.
  // Wait for its overlay to leave the tree before changing profile mode.
  await route.completed;
  return result;
}

class _ProfileDetailsDialog extends StatefulWidget {
  const _ProfileDetailsDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.allowedModules,
    required this.canCancel,
    required this.submitOnKeyboard,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final int? allowedModules;
  final bool canCancel;
  final bool submitOnKeyboard;

  @override
  State<_ProfileDetailsDialog> createState() => _ProfileDetailsDialogState();
}

class _ProfileDetailsDialogState extends State<_ProfileDetailsDialog> {
  late final TextEditingController _controller;
  late int? _selectedLimit;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _selectedLimit = widget.allowedModules;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop<ProfileDetailsResult>((
      name: _controller.text.trim(),
      allowedModules: _selectedLimit,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.profileNameLabel),
            onSubmitted: widget.submitOnKeyboard ? (_) => _submit() : null,
          ),
          if (widget.allowedModules != null) ...[
            const SizedBox(height: 16),
            Text(l10n.profileAllowedModules),
            DropdownButtonFormField<int>(
              initialValue: widget.allowedModules,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.parentalNoLimit)),
                for (var count = 1; count <= 10; count++)
                  DropdownMenuItem(
                    value: count,
                    child: Text('$count ${l10n.parentalModulesUnit}'),
                  ),
              ],
              onChanged: (value) => _selectedLimit = value,
            ),
          ],
        ],
      ),
      actions: [
        if (widget.canCancel)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.learner,
    required this.onTap,
    this.onEdit,
    this.pending = false,
  });

  final LearnerProfile learner;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  /// Visual-only cue for profiles awaiting name confirmation. Taps are
  /// already disabled by the caller; this only dims the card and labels it.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: pending ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: colors.accentSoft,
                  child: Icon(
                    Icons.face_rounded,
                    color: colors.accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        learner.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      if (pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.profilePendingConfirmation,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.inkSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: AppLocalizations.of(context).profileEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: colors.accent,
                    onPressed: onEdit,
                  ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: colors.inkSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.isError, this.onRetry});

  final String text;
  final bool isError;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : colors.ink,
              ),
            ),
            if (onRetry != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).profileRetry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
