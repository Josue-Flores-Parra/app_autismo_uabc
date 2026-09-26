import 'package:flutter/material.dart';
import '../../../shared/services/settings_access_guard.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_theme.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../legal/data/legal_documents.dart';
import '../../legal/view/legal_document_screen.dart';
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
    final colors = context.appColors;
    final errorColor = Theme.of(context).colorScheme.error;
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        final auth = _getAuth(context);
        final user = auth?.currentUser;
        final displayName = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'Usuario';
        final email = user?.email ?? '—';

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Ajustes')),
          body: Container(
            decoration: BoxDecoration(gradient: colors.backgroundGradient),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Section(
                    title: l10n?.profileSectionTitle ?? 'Perfil de usuario',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colors.accentSoft,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.surfaceBorder),
                              ),
                              child: Image.asset(
                                'assets/images/presets/appy_head_happy_preset.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: colors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: colors.accent,
                              tooltip: l10n?.editDisplayName ?? 'Editar nombre',
                              onPressed: () => _editDisplayName(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n?.accountSecuritySection ?? 'Cuenta y seguridad',
                    children: [
                      _SettingsRow(
                        icon: Icons.lock_reset,
                        title: l10n?.changePassword ?? 'Cambiar contraseña',
                        onTap: () => _changePassword(context),
                      ),
                      _SettingsRow(
                        icon: Icons.pin_outlined,
                        title: 'Cambiar PIN',
                        onTap: () => _changePin(context),
                      ),
                      _SettingsRow(
                        icon: Icons.logout_rounded,
                        title: l10n?.logout ?? 'Cerrar sesión',
                        onTap: () => _logout(context),
                      ),
                      _SettingsRow(
                        icon: Icons.delete_outline_rounded,
                        color: errorColor,
                        title: l10n?.deleteAccount ?? 'Eliminar cuenta',
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n?.languageSection ?? 'Idioma',
                    children: [
                      _ChoiceRow(
                        icon: Icons.language,
                        chips: [
                          _Chip(
                            label: l10n?.languageSpanish ?? 'Español',
                            selected: settings.locale == const Locale('es'),
                            onTap: () => settings.setLocale(const Locale('es')),
                          ),
                          _Chip(
                            label: l10n?.languageEnglish ?? 'Inglés',
                            selected: settings.locale == const Locale('en'),
                            onTap: () => settings.setLocale(const Locale('en')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n?.appearanceSection ?? 'Apariencia',
                    children: [
                      _ChoiceRow(
                        icon: Icons.brightness_6_outlined,
                        chips: [
                          _Chip(
                            label: l10n?.themeSystem ?? 'Sistema',
                            selected: settings.themeMode == ThemeMode.system,
                            onTap: () =>
                                settings.setThemeMode(ThemeMode.system),
                          ),
                          _Chip(
                            label: l10n?.themeLight ?? 'Claro',
                            selected: settings.themeMode == ThemeMode.light,
                            onTap: () => settings.setThemeMode(ThemeMode.light),
                          ),
                          _Chip(
                            label: l10n?.themeDark ?? 'Oscuro',
                            selected: settings.themeMode == ThemeMode.dark,
                            onTap: () => settings.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Learning and accessibility preferences (text size,
                  // contrast, animations, feedback, reminders) are per-child
                  // and live in ChildSettingsScreen, not here.
                  _Section(
                    title: l10n?.privacySection ?? 'Privacidad y datos',
                    children: [
                      _SettingsRow(
                        icon: Icons.cleaning_services_outlined,
                        title: l10n?.clearCache ?? 'Limpiar caché de recursos',
                        onTap: () async {
                          await settings.clearCache();
                          _showSnack(
                            l10n?.cacheClearedSnackbar ?? 'Caché limpiada',
                          );
                        },
                      ),
                      _SwitchRow(
                        icon: Icons.analytics_outlined,
                        title: l10n?.sendMetrics ?? 'Enviar métricas anónimas',
                        value: settings.sendMetrics,
                        onChanged: settings.toggleSendMetrics,
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n?.infoSection ?? 'Información y soporte',
                    children: [
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '—';
                          return _SettingsRow(
                            icon: Icons.info_outline,
                            title: l10n?.appVersion ?? 'Versión de la app',
                            subtitle: version,
                          );
                        },
                      ),
                      _SettingsRow(
                        icon: Icons.article_outlined,
                        title: l10n?.termsPrivacy ?? 'Términos y Condiciones',
                        onTap: () => _openLegal(
                          context,
                          termsOfUse(settings.locale.languageCode),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n?.privacyPolicy ?? 'Aviso de Privacidad',
                        onTap: () => _openLegal(
                          context,
                          privacyNotice(settings.locale.languageCode),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.support_agent,
                        title:
                            l10n?.feedbackSupport ??
                            'Enviar feedback / soporte',
                        onTap: () => _launchUrl(
                          'mailto:rosalesq.software@gmail.com?subject=Appy%20Feedback',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n?.confirm ?? 'Confirmar'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && auth != null) {
      final success = await auth.updateDisplayName(result);
      _showSnack(
        success
            ? l10n?.displayNameUpdated ?? 'Nombre actualizado'
            : l10n?.errorSnackbar ?? 'Ocurrió un problema',
      );
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final success = await SettingsAccessGuard.changePinFlow(context);
    if (!mounted) return;
    if (success) {
      _showSnack('PIN actualizado correctamente');
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final auth = _getAuth(context);

    if (auth == null) return;

    final result = await showDialog<List<String>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.changePassword ?? 'Cambiar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.currentPasswordLabel ?? 'Contraseña actual',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.newPasswordLabel ?? 'Contraseña nueva',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n?.cancel ?? 'Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop([currentController.text.trim(), newController.text.trim()]),
              child: Text(l10n?.confirm ?? 'Confirmar'),
            ),
          ],
        );
      },
    );

    if (result != null &&
        result.length == 2 &&
        result[0].isNotEmpty &&
        result[1].length >= 6) {
      final success = await auth.changePassword(result[0], result[1]);
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
    // El swap a LoginScreen lo maneja AuthGate via Consumer<AuthViewModel>.
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = _getAuth(context);
    final l10n = AppLocalizations.of(context);
    if (auth == null) return;
    final controller = TextEditingController();
    // Firebase pide sesión reciente para borrar, así que la contraseña se
    // recoge aquí mismo junto con la palabra de confirmación.
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n?.deleteAccountConfirmTitle ?? '¿Eliminar cuenta?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.deleteAccountConfirmBody ??
                    'Se borrará tu cuenta y datos almacenados. Escribe BORRAR para continuar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n?.deleteAccountConfirmAction ?? 'BORRAR',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText:
                      l10n?.currentPasswordLabel ?? 'Contraseña de la cuenta',
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
                        (l10n?.deleteAccountConfirmAction ?? 'BORRAR') &&
                    passwordController.text.isNotEmpty,
              ),
              child: Text(
                l10n?.confirm ?? 'Confirmar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await auth.deleteAccount(passwordController.text);
      if (!mounted) return;
      if (!success) {
        _showSnack(
          l10n?.deleteAccountFailed ?? 'No se pudo eliminar la cuenta',
        );
      }
    }
  }

  /// Abre un documento legal propio de Appy.
  ///
  /// Es el mismo texto que la cuenta aceptó al entrar, para que el padre o
  /// tutor pueda consultarlo cuando quiera.
  Future<void> _openLegal(BuildContext context, LegalDocument document) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
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
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Etiqueta de seccion sobre una tarjeta con sus filas separadas.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

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
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 66),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila estandar: icono en cuadro, titulo, subtitulo opcional y, al final,
/// chevron (si es tocable) o el `trailing` dado. `below` va bajo el texto.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
    this.color,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  /// Color de icono y titulo para acciones destructivas.
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleColor = color ?? (enabled ? colors.ink : colors.inkSoft);
    final showChevron = trailing == null && below == null && onTap != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: below == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            _RowIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: colors.inkSoft),
                      ),
                    ),
                  if (below != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: below,
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right, color: colors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: icon,
      title: title,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// Fila de opciones excluyentes; sin `title` los chips van junto al icono.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.icon, required this.chips, this.title});

  final IconData icon;
  final String? title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final wrap = Wrap(spacing: 8, runSpacing: 8, children: chips);
    if (title != null) {
      return _SettingsRow(icon: icon, title: title!, below: wrap);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _RowIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(child: wrap),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12) ?? colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Icon(icon, size: 20, color: color ?? colors.accent),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: colors.accentSoft,
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? colors.accent : colors.surfaceBorder),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: colors.ink,
      ),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}
