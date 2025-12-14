import 'package:flutter/material.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../authentication/view/login_screen.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../avatar/view/avatar_screen.dart';
import '../../avatar/viewmodel/avatar_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AuthViewModel? _getAuth(BuildContext context) {
    try {
      return Provider.of<AuthViewModel>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        final auth = _getAuth(context);
        final user = auth?.currentUser;
        final displayName =
            user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : 'Usuario';
        final email = user?.email ?? '—';

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.settingsTitle ?? 'Ajustes'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                title: l10n?.profileSectionTitle ?? 'Perfil de usuario',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(l10n?.displayNameLabel ?? 'Nombre para mostrar'),
                    subtitle: Text(displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editDisplayName(context),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: Text(l10n?.changeAvatar ?? 'Cambiar avatar'),
                    subtitle: const Text('Personaliza tu apariencia'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AvatarScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(l10n?.emailLabel ?? 'Correo'),
                    subtitle: Text(email),
                    enabled: false,
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.accountSecuritySection ?? 'Cuenta y seguridad',
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: Text(l10n?.changePassword ?? 'Cambiar contraseña'),
                    onTap: () => _changePassword(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: Text(l10n?.logout ?? 'Cerrar sesión'),
                    onTap: () => _logout(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(
                      l10n?.deleteAccount ?? 'Eliminar cuenta',
                      style: const TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(
                      l10n?.deleteAccountConfirmBody ??
                          'Se borrará tu cuenta y datos almacenados. Escribe BORRAR para continuar.',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.languageSection ?? 'Idioma',
                children: [
                  RadioListTile<Locale>(
                    title: Text(l10n?.languageSpanish ?? 'Español'),
                    value: const Locale('es'),
                    groupValue: settings.locale,
                    onChanged: (value) {
                      if (value != null) settings.setLocale(value);
                    },
                  ),
                  RadioListTile<Locale>(
                    title: Text(l10n?.languageEnglish ?? 'Inglés'),
                    value: const Locale('en'),
                    groupValue: settings.locale,
                    onChanged: (value) {
                      if (value != null) settings.setLocale(value);
                    },
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.appearanceSection ?? 'Apariencia',
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(l10n?.themeSystem ?? 'Sistema'),
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      if (value != null) settings.setThemeMode(value);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n?.themeLight ?? 'Claro'),
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      if (value != null) settings.setThemeMode(value);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n?.themeDark ?? 'Oscuro'),
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      if (value != null) settings.setThemeMode(value);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.fontSizeLabel ?? 'Tamaño de fuente',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: FontScaleOption.values.map((option) {
                            final label = switch (option) {
                              FontScaleOption.small => l10n?.fontSmall ?? 'Pequeño',
                              FontScaleOption.medium => l10n?.fontMedium ?? 'Medio',
                              FontScaleOption.large => l10n?.fontLarge ?? 'Grande',
                            };
                            return ChoiceChip(
                              label: Text(label),
                              selected: settings.fontScale == option,
                              onSelected: (_) => settings.setFontScale(option),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.accessibilitySection ?? 'Accesibilidad',
                children: [
                  SwitchListTile(
                    title: Text(l10n?.highContrast ?? 'Alto contraste'),
                    value: settings.highContrast,
                    onChanged: settings.toggleHighContrast,
                  ),
                  SwitchListTile(
                    title: Text(l10n?.reduceAnimations ?? 'Reducir animaciones'),
                    value: settings.reduceAnimations,
                    onChanged: settings.toggleReduceAnimations,
                  ),
                  SwitchListTile(
                    title: Text(l10n?.audioFeedback ?? 'Feedback auditivo'),
                    value: settings.audioFeedback,
                    onChanged: settings.toggleAudioFeedback,
                  ),
                  SwitchListTile(
                    title: Text(l10n?.hapticFeedback ?? 'Feedback háptico'),
                    value: settings.hapticFeedback,
                    onChanged: settings.toggleHapticFeedback,
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.notificationsSection ?? 'Notificaciones y recordatorios',
                children: [
                  SwitchListTile(
                    title: Text(l10n?.enableReminders ?? 'Activar recordatorios de práctica'),
                    value: settings.remindersEnabled,
                    onChanged: settings.toggleReminders,
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n?.scheduleReminder ?? 'Horario sugerido'),
                    subtitle: Text(
                      settings.remindersEnabled
                          ? settings.reminderTime.format(context)
                          : l10n?.reminderPlaceholder ??
                              'La programación llegará pronto',
                    ),
                    enabled: settings.remindersEnabled,
                    onTap: settings.remindersEnabled
                        ? () => _pickReminderTime(context)
                        : () => _showSnack(
                              l10n?.reminderNotImplemented ?? 'La programación llegará pronto',
                            ),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.privacySection ?? 'Privacidad y datos',
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(l10n?.clearCache ?? 'Limpiar caché de recursos'),
                    onTap: () async {
                      await settings.clearCache();
                      _showSnack(l10n?.cacheClearedSnackbar ?? 'Caché limpiada');
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n?.sendMetrics ?? 'Enviar métricas anónimas'),
                    value: settings.sendMetrics,
                    onChanged: settings.toggleSendMetrics,
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.parentalSection ?? 'Control parental',
                children: [
                  ListTile(
                    title: Text(l10n?.parentalMinLevel ?? 'Nivel mínimo requerido'),
                    subtitle: Text('${settings.parentalMinLevel}'),
                    trailing: SizedBox(
                      width: 180,
                      child: Slider(
                        value: settings.parentalMinLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: '${settings.parentalMinLevel}',
                        onChanged: (value) => settings.setParentalMinLevel(value.toInt()),
                      ),
                    ),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: l10n?.infoSection ?? 'Información y soporte',
                children: [
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '—';
                      return ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(l10n?.appVersion ?? 'Versión de la app'),
                        subtitle: Text(version),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(l10n?.termsPrivacy ?? 'Términos y Privacidad'),
                    onTap: () => _launchUrl('https://policies.google.com/terms'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy policy'),
                    onTap: () => _launchUrl('https://policies.google.com/privacy'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: Text(l10n?.feedbackSupport ?? 'Enviar feedback / soporte'),
                    onTap: () =>
                        _launchUrl('mailto:rosalesq.software@gmail.com?subject=Appy%20Feedback'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final auth = _getAuth(context);
    if (auth?.currentUser?.displayName != null) {
      controller.text = auth!.currentUser!.displayName!;
    }
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.editDisplayName ?? 'Editar nombre'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n?.displayNameLabel ?? 'Nombre para mostrar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n?.cancel ?? 'Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n?.confirm ?? 'Confirmar'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && auth != null) {
      final success = await auth.updateDisplayName(result);
      // Sincronizar el nombre del avatar para que refleje el displayName.
      if (success) {
        final avatar = context.read<AvatarViewModel?>();
        await avatar?.updateNombreDesdeDisplayName(result);
      }
      _showSnack(
        success
            ? l10n?.displayNameUpdated ?? 'Nombre actualizado'
            : l10n?.errorSnackbar ?? 'Ocurrió un problema',
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final auth = _getAuth(context);

    if (auth == null) return;

    final newPassword = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.changePassword ?? 'Cambiar contraseña'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n?.changePassword ?? 'Cambiar contraseña',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n?.cancel ?? 'Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n?.confirm ?? 'Confirmar'),
            ),
          ],
        );
      },
    );

    if (newPassword != null && newPassword.trim().length >= 6) {
      final success = await auth.changePassword(newPassword.trim());
      _showSnack(
        success
            ? l10n?.passwordUpdated ?? 'Contraseña actualizada'
            : l10n?.errorSnackbar ?? 'Ocurrió un problema',
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final auth = _getAuth(context);
    final l10n = AppLocalizations.of(context);
    await auth?.logout();
    if (!mounted) return;
    _showSnack(l10n?.logoutSuccess ?? 'Sesión cerrada');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = _getAuth(context);
    final l10n = AppLocalizations.of(context);
    if (auth == null) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.deleteAccountConfirmTitle ?? '¿Eliminar cuenta?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n?.deleteAccountConfirmBody ??
                  'Se borrará tu cuenta y datos almacenados. Escribe BORRAR para continuar.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n?.deleteAccountConfirmAction ?? 'BORRAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancel ?? 'Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                controller.text.trim().toUpperCase() ==
                    (l10n?.deleteAccountConfirmAction ?? 'BORRAR'),
              ),
              child: Text(
                l10n?.confirm ?? 'Confirmar',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await auth.deleteAccount();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _showSnack(l10n?.deleteAccountFailed ?? 'No se pudo eliminar la cuenta');
      }
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final settings = Provider.of<SettingsViewModel>(context, listen: false);
    final current = settings.reminderTime;
    final selected = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (selected != null) {
      settings.setReminderTime(selected);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('No se pudo abrir el enlace');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

