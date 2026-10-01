import 'package:flutter/foundation.dart';

import '../../../data/services/offline_assets_service.dart';
import '../../learning_module/model/levels_models.dart';
import '../../learning_module/viewmodel/learning_viewmodel.dart';

/// Qué hace ahora mismo la descarga de un módulo.
enum ModuleDownloadPhase { idle, downloading, failed }

/// Estado de un módulo en la pantalla de descargas.
class ModuleDownloadInfo {
  const ModuleDownloadInfo({
    required this.moduleId,
    required this.title,
    required this.status,
    this.phase = ModuleDownloadPhase.idle,
    this.done = 0,
    this.total = 0,
    this.bytes = 0,
    this.error,
  });

  final String moduleId;
  final String title;
  final OfflineModuleStatus status;
  final ModuleDownloadPhase phase;
  final int done;
  final int total;
  final int bytes;
  final OfflineDownloadError? error;

  bool get isDownloading => phase == ModuleDownloadPhase.downloading;

  ModuleDownloadInfo copyWith({
    OfflineModuleStatus? status,
    ModuleDownloadPhase? phase,
    int? done,
    int? total,
    int? bytes,
    OfflineDownloadError? error,
    bool clearError = false,
  }) {
    return ModuleDownloadInfo(
      moduleId: moduleId,
      title: title,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      done: done ?? this.done,
      total: total ?? this.total,
      bytes: bytes ?? this.bytes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Lógica de la pantalla de descargas: qué módulos hay, cuáles están
/// disponibles sin conexión y las acciones de descargar y borrar.
class DownloadsViewModel extends ChangeNotifier {
  DownloadsViewModel(this._learning, this._service);

  final LearningViewModel _learning;
  final OfflineAssetsService _service;

  final Map<String, Set<String>> _urls = {};
  List<ModuleDownloadInfo> _modules = [];
  bool _isLoading = false;
  bool _disposed = false;

  List<ModuleDownloadInfo> get modules => _modules;
  bool get isLoading => _isLoading;

  /// Lee los módulos y las URLs de sus niveles, y calcula el estado de cada
  /// uno. Si los niveles de un módulo no se pueden leer (sin conexión y sin
  /// caché), se usa lo que ya hay guardado en disco.
  Future<void> load() async {
    _isLoading = true;
    _notify();

    final infos = <ModuleDownloadInfo>[];
    for (final module in _learning.modulos) {
      Set<String>? urls;
      try {
        final levels = await _learning.getModuleLevels(module.id);
        urls = collectLevelAssetUrls(levels);
        _urls[module.id] = urls;
      } catch (e) {
        debugPrint('DownloadsViewModel: niveles de ${module.id} no leídos: $e');
      }
      final bytes = _service.bytesOf(module.id);
      infos.add(
        ModuleDownloadInfo(
          moduleId: module.id,
          title: module.titulo,
          status: urls == null
              ? (bytes > 0
                    ? OfflineModuleStatus.downloaded
                    : OfflineModuleStatus.notDownloaded)
              : _service.statusOf(module.id, urls),
          bytes: bytes,
        ),
      );
    }
    _modules = infos;
    _isLoading = false;
    _notify();
  }

  /// Descarga el módulo. El error, si lo hay, queda en su estado para que la
  /// pantalla lo explique; no se lanza.
  Future<void> download(String moduleId) async {
    final urls = _urls[moduleId];
    final current = _infoOf(moduleId);
    if (urls == null ||
        urls.isEmpty ||
        current == null ||
        current.isDownloading) {
      return;
    }

    _update(
      moduleId,
      (info) => info.copyWith(
        phase: ModuleDownloadPhase.downloading,
        done: 0,
        total: urls.length,
        clearError: true,
      ),
    );

    try {
      await _service.downloadModule(
        moduleId,
        urls,
        onProgress: (done, total) => _update(
          moduleId,
          (info) => info.copyWith(done: done, total: total),
        ),
      );
      _update(
        moduleId,
        (info) => info.copyWith(phase: ModuleDownloadPhase.idle),
      );
    } on OfflineDownloadException catch (e) {
      _update(
        moduleId,
        (info) =>
            info.copyWith(phase: ModuleDownloadPhase.failed, error: e.error),
      );
    } catch (e) {
      debugPrint('DownloadsViewModel: descarga de $moduleId falló: $e');
      _update(
        moduleId,
        (info) => info.copyWith(
          phase: ModuleDownloadPhase.failed,
          error: OfflineDownloadError.network,
        ),
      );
    }
    _refreshStatus(moduleId);
  }

  /// Borra la descarga del módulo.
  Future<void> delete(String moduleId) async {
    final current = _infoOf(moduleId);
    if (current == null || current.isDownloading) return;
    await _service.deleteModule(moduleId);
    _update(
      moduleId,
      (info) =>
          info.copyWith(phase: ModuleDownloadPhase.idle, clearError: true),
    );
    _refreshStatus(moduleId);
  }

  ModuleDownloadInfo? _infoOf(String moduleId) {
    for (final info in _modules) {
      if (info.moduleId == moduleId) return info;
    }
    return null;
  }

  void _refreshStatus(String moduleId) {
    final urls = _urls[moduleId];
    _update(
      moduleId,
      (info) => info.copyWith(
        status: urls == null ? info.status : _service.statusOf(moduleId, urls),
        bytes: _service.bytesOf(moduleId),
      ),
    );
  }

  void _update(
    String moduleId,
    ModuleDownloadInfo Function(ModuleDownloadInfo info) change,
  ) {
    _modules = [
      for (final info in _modules)
        if (info.moduleId == moduleId) change(info) else info,
    ];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
