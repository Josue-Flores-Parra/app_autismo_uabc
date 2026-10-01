import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../data/services/offline_assets_service.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../learning_module/viewmodel/learning_viewmodel.dart';
import '../viewmodel/downloads_viewmodel.dart';

/// Pantalla para descargar módulos y usarlos sin conexión. Se abre desde los
/// ajustes de la cuenta, detrás del PIN.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DownloadsViewModel(
        context.read<LearningViewModel>(),
        OfflineAssetsService.instance,
      )..load(),
      child: const _DownloadsView(),
    );
  }
}

class _DownloadsView extends StatelessWidget {
  const _DownloadsView();

  String _sizeLabel(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return megabytes < 0.1 ? '< 0.1 MB' : '${megabytes.toStringAsFixed(1)} MB';
  }

  String _statusLabel(AppLocalizations l10n, ModuleDownloadInfo info) {
    if (info.isDownloading) {
      return l10n.downloadsInProgress(info.done, info.total);
    }
    switch (info.status) {
      case OfflineModuleStatus.downloaded:
        return l10n.downloadsDownloaded(_sizeLabel(info.bytes));
      case OfflineModuleStatus.partial:
        return l10n.downloadsPartial;
      case OfflineModuleStatus.notDownloaded:
        return l10n.downloadsNotDownloaded;
    }
  }

  String? _errorLabel(AppLocalizations l10n, ModuleDownloadInfo info) {
    if (info.phase != ModuleDownloadPhase.failed) return null;
    switch (info.error) {
      case OfflineDownloadError.network:
        return l10n.downloadsErrorNetwork;
      case OfflineDownloadError.noSpace:
        return l10n.downloadsErrorNoSpace;
      case OfflineDownloadError.server:
      case OfflineDownloadError.incomplete:
      case null:
        return l10n.downloadsErrorOther;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadsViewModel viewModel,
    ModuleDownloadInfo info,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadsDeleteTitle),
        content: Text(l10n.downloadsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.downloadsDeleteTooltip),
          ),
        ],
      ),
    );
    if (confirmed == true) await viewModel.delete(info.moduleId);
  }

  Widget _trailing(
    BuildContext context,
    DownloadsViewModel viewModel,
    ModuleDownloadInfo info,
  ) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    if (info.isDownloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: info.total == 0 ? null : info.done / info.total,
        ),
      );
    }
    if (info.status == OfflineModuleStatus.downloaded) {
      return IconButton(
        tooltip: l10n.downloadsDeleteTooltip,
        icon: Icon(Icons.delete_outline_rounded, color: colors.warning),
        onPressed: () => _confirmDelete(context, viewModel, info),
      );
    }
    final failed = info.phase == ModuleDownloadPhase.failed;
    return FilledButton.tonal(
      onPressed: () => viewModel.download(info.moduleId),
      child: Text(failed ? l10n.downloadsRetry : l10n.downloadsAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final viewModel = context.watch<DownloadsViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: SafeArea(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n.downloadsIntro,
                        style: TextStyle(fontSize: 14, color: colors.inkSoft),
                      ),
                    ),
                    if (viewModel.modules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          l10n.downloadsEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.inkSoft),
                        ),
                      ),
                    for (final info in viewModel.modules)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    info.status ==
                                            OfflineModuleStatus.downloaded
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_download_outlined,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          info.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: colors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _statusLabel(l10n, info),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colors.inkSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _trailing(context, viewModel, info),
                                ],
                              ),
                              if (info.isDownloading) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    minHeight: 6,
                                    value: info.total == 0
                                        ? null
                                        : info.done / info.total,
                                  ),
                                ),
                              ],
                              if (_errorLabel(l10n, info) != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _errorLabel(l10n, info)!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.warning,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
