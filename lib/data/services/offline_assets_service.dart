import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/offline_manifest.dart';

/// Cuánto del contenido de un módulo está disponible sin conexión.
enum OfflineModuleStatus { notDownloaded, partial, downloaded }

/// Motivo por el que falló una descarga.
enum OfflineDownloadError { network, noSpace, server, incomplete }

class OfflineDownloadException implements Exception {
  const OfflineDownloadException(this.error, this.url, [this.detail]);

  final OfflineDownloadError error;
  final String url;
  final String? detail;

  /// Los errores de red y los del servidor temporales merecen otro intento;
  /// sin espacio o un archivo rechazado no mejoran al repetir.
  bool get isRetryable =>
      error == OfflineDownloadError.network ||
      error == OfflineDownloadError.incomplete ||
      (error == OfflineDownloadError.server && _temporaryServerError);

  bool get _temporaryServerError {
    final code = int.tryParse(detail ?? '');
    return code == null || code >= 500 || code == 408 || code == 429;
  }

  @override
  String toString() => 'OfflineDownloadException($error, $url, $detail)';
}

/// Cancelación voluntaria; no representa un fallo de red.
class OfflineDownloadCancelled implements Exception {}

class _DownloadCancellation {
  final signal = Completer<void>();
  final finished = Completer<void>();
  bool get cancelled => signal.isCompleted;
  void cancel() {
    if (!cancelled) signal.complete();
  }

  void check() {
    if (cancelled) throw OfflineDownloadCancelled();
  }

  Future<void> delay(Duration duration) async {
    final done = Completer<void>();
    final timer = Timer(duration, done.complete);
    try {
      await wait(done.future);
    } finally {
      timer.cancel();
    }
  }

  Future<T> wait<T>(Future<T> work) {
    check();
    return Future.any([
      work,
      signal.future.then<T>((_) => throw OfflineDownloadCancelled()),
    ]);
  }
}

/// Descarga el contenido de los módulos al almacenamiento de la app y lo
/// sirve desde ahí cuando existe.
///
/// Es el único punto que toca disco y red para este contenido. Cada módulo
/// guarda sus archivos junto a un `manifest.json` con la URL original de cada
/// uno. Los archivos llegan a un `.part` y solo se renombran al completarse,
/// así que un corte nunca deja un archivo a medias que parezca válido.
///
/// No se recomprime nada en reposo: los videos, las imágenes y el audio ya
/// son formatos comprimidos, recomprimirlos casi no ahorra espacio y
/// impediría que los reproductores lean el archivo directo. La transferencia
/// sí viaja comprimida cuando el servidor lo permite (gzip lo negocia y
/// descomprime el cliente HTTP).
class OfflineAssetsService {
  OfflineAssetsService({
    http.Client? client,
    Directory? root,
    List<Duration>? retryDelays,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _root = root,
       retryDelays =
           retryDelays ?? const [Duration(seconds: 1), Duration(seconds: 3)];

  /// Instancia de la app. Las pruebas crean la suya con un cliente falso.
  static final OfflineAssetsService instance = OfflineAssetsService();

  final http.Client _client;
  final List<Duration> retryDelays;
  final Duration timeout;

  Directory? _root;
  final Map<String, OfflineManifest> _manifests = {};
  final Map<String, _DownloadCancellation> _activeDownloads = {};
  final Map<String, String> _index = {};

  static const String _manifestName = 'manifest.json';

  /// Prepara la carpeta y lee lo descargado. Seguro de llamar varias veces.
  Future<void> init() async {
    _root ??= Directory(
      p.join((await getApplicationSupportDirectory()).path, 'offline_assets'),
    );
    await _root!.create(recursive: true);
    _manifests.clear();
    await for (final entity in _root!.list()) {
      if (entity is! Directory) continue;
      final manifestFile = File(p.join(entity.path, _manifestName));
      if (!await manifestFile.exists()) continue;
      try {
        final data = jsonDecode(await manifestFile.readAsString());
        if (data is! Map) continue;
        final manifest = OfflineManifest.fromMap(
          Map<String, dynamic>.from(data),
        );
        if (manifest.moduleId.isEmpty) continue;
        _manifests[manifest.moduleId] = await _verified(manifest, entity);
      } catch (e) {
        debugPrint(
          'OfflineAssetsService: manifiesto ilegible en ${entity.path}',
        );
      }
    }
    _rebuildIndex();
  }

  /// Ruta local de [url] si ya se descargó, o `null`.
  String? localPath(String url) => _index[url] ?? _index[url.trim()];

  /// Imagen desde disco si se descargó; si no, desde la red.
  ImageProvider imageProvider(String url) {
    final local = localPath(url);
    return local == null ? NetworkImage(url) : FileImage(File(local));
  }

  /// Estado del módulo respecto a las URLs que hoy tienen sus niveles.
  OfflineModuleStatus statusOf(String moduleId, Iterable<String> urls) {
    final needed = urls.toSet();
    final manifest = _manifests[moduleId];
    if (needed.isEmpty || manifest == null) {
      return OfflineModuleStatus.notDownloaded;
    }
    final have = needed.where(manifest.files.containsKey).length;
    if (have == 0) return OfflineModuleStatus.notDownloaded;
    return have == needed.length
        ? OfflineModuleStatus.downloaded
        : OfflineModuleStatus.partial;
  }

  /// Bytes que ocupa el módulo en disco.
  int bytesOf(String moduleId) => _manifests[moduleId]?.totalBytes ?? 0;

  /// Descarga [urls] del módulo. Omite lo que ya está completo. Si un archivo
  /// falla tras los reintentos, lanza [OfflineDownloadException]; lo que ya se
  /// guardó queda disponible y no se vuelve a bajar en el siguiente intento.
  Future<void> downloadModule(
    String moduleId,
    Iterable<String> urls, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (_root == null) {
      throw StateError('OfflineAssetsService.init() no se ha llamado.');
    }
    if (_activeDownloads.containsKey(moduleId)) {
      throw StateError('Descarga ya activa.');
    }
    final cancellation = _DownloadCancellation();
    _activeDownloads[moduleId] = cancellation;
    final dir = _moduleDir(moduleId);
    final original =
        _manifests[moduleId] ?? OfflineManifest(moduleId: moduleId);
    var manifest = original;
    final addedFiles = <String>{};
    final pending = urls.toSet().toList();
    var done = 0;
    var rolledBack = false;
    Future<void> rollback() async {
      for (final name in addedFiles) {
        final added = File(p.join(dir.path, name));
        if (await added.exists()) await added.delete();
      }
      manifest = original;
      _manifests[moduleId] = original;
      _rebuildIndex();
      rolledBack = true;
    }

    try {
      await dir.create(recursive: true);
      cancellation.check();
      onProgress?.call(done, pending.length);
      for (final url in pending) {
        cancellation.check();
        final known = original.files[url];
        if (known != null && await _isComplete(dir, known)) {
          done++;
          onProgress?.call(done, pending.length);
          continue;
        }
        final entry = await _downloadWithRetries(dir, url, cancellation);
        addedFiles.add(entry.file);
        manifest = manifest.copyWith(files: {...manifest.files, url: entry});
        _manifests[moduleId] = manifest;
        _rebuildIndex();
        cancellation.check();
        done++;
        onProgress?.call(done, pending.length);
      }
      cancellation.check();
    } finally {
      try {
        if (cancellation.cancelled) {
          // Solo revierte archivos obtenidos por este intento; conserva los anteriores.
          await rollback();
        }
        if (await dir.exists()) await _writeManifest(dir, manifest);
        if (cancellation.cancelled && !rolledBack) {
          await rollback();
          if (await dir.exists()) await _writeManifest(dir, manifest);
        }
      } finally {
        _activeDownloads.remove(moduleId);
        cancellation.finished.complete();
      }
    }
    // También cubre cancelación durante la escritura final del manifiesto.
    cancellation.check();
  }

  /// Detiene un módulo y espera hasta terminar la limpieza de sus archivos.
  Future<void> cancelDownload(String moduleId) async {
    final active = _activeDownloads[moduleId];
    if (active == null) return;
    active.cancel();
    await active.finished.future;
  }

  /// Borra el módulo del disco.
  Future<void> deleteModule(String moduleId) async {
    if (_activeDownloads.containsKey(moduleId)) {
      throw StateError('Espera a que termine la descarga o su cancelación.');
    }
    _manifests.remove(moduleId);
    _rebuildIndex();
    final dir = _moduleDir(moduleId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Directory _moduleDir(String moduleId) =>
      Directory(p.join(_root!.path, Uri.encodeComponent(moduleId)));

  void _rebuildIndex() {
    _index.clear();
    for (final manifest in _manifests.values) {
      final dir = _moduleDir(manifest.moduleId);
      manifest.files.forEach((url, entry) {
        _index[url] = p.join(dir.path, entry.file);
      });
    }
  }

  Future<bool> _isComplete(Directory dir, OfflineFileEntry entry) async {
    final file = File(p.join(dir.path, entry.file));
    return await file.exists() && await file.length() == entry.bytes;
  }

  /// Quita del manifiesto lo que ya no existe o cambió de tamaño en disco.
  Future<OfflineManifest> _verified(
    OfflineManifest manifest,
    Directory dir,
  ) async {
    final valid = <String, OfflineFileEntry>{};
    for (final e in manifest.files.entries) {
      if (await _isComplete(dir, e.value)) valid[e.key] = e.value;
    }
    return manifest.copyWith(files: valid);
  }

  Future<void> _writeManifest(Directory dir, OfflineManifest manifest) async {
    final file = File(p.join(dir.path, _manifestName));
    await file.writeAsString(jsonEncode(manifest.toMap()));
  }

  Future<OfflineFileEntry> _downloadWithRetries(
    Directory dir,
    String url,
    _DownloadCancellation cancellation,
  ) async {
    var attempt = 0;
    while (true) {
      try {
        cancellation.check();
        return await _downloadFile(dir, url, cancellation);
      } on OfflineDownloadException catch (e) {
        if (!e.isRetryable || attempt >= retryDelays.length) rethrow;
        await cancellation.delay(retryDelays[attempt]);
        attempt++;
      }
    }
  }

  Future<OfflineFileEntry> _downloadFile(
    Directory dir,
    String url,
    _DownloadCancellation cancellation,
  ) async {
    final name = fileNameFor(url);
    final target = File(p.join(dir.path, name));
    final part = File('${target.path}.part');
    try {
      final response = await cancellation.wait(
        _client
            .send(
              http.AbortableRequest(
                'GET',
                Uri.parse(url),
                abortTrigger: cancellation.signal.future,
              ),
            )
            .timeout(timeout),
      );
      if (response.statusCode != 200) {
        throw OfflineDownloadException(
          OfflineDownloadError.server,
          url,
          '${response.statusCode}',
        );
      }

      var bytes = 0;
      final sink = part.openWrite();
      final iterator = StreamIterator(response.stream.timeout(timeout));
      try {
        while (await cancellation.wait(iterator.moveNext())) {
          final chunk = iterator.current;
          sink.add(chunk);
          bytes += chunk.length;
        }
        await sink.flush();
      } finally {
        await iterator.cancel();
        await sink.close();
      }

      final expected = response.contentLength;
      if (bytes == 0 || (expected != null && bytes != expected)) {
        throw OfflineDownloadException(
          OfflineDownloadError.incomplete,
          url,
          '$bytes de ${expected ?? '?'}',
        );
      }
      cancellation.check();
      await part.rename(target.path);
      return OfflineFileEntry(file: name, bytes: bytes);
    } on OfflineDownloadCancelled {
      await _discard(part);
      rethrow;
    } on http.RequestAbortedException {
      await _discard(part);
      throw OfflineDownloadCancelled();
    } on OfflineDownloadException {
      await _discard(part);
      rethrow;
    } catch (e) {
      await _discard(part);
      throw OfflineDownloadException(
        isNoSpaceError(e)
            ? OfflineDownloadError.noSpace
            : OfflineDownloadError.network,
        url,
        '$e',
      );
    }
  }

  Future<void> _discard(File part) async {
    try {
      if (await part.exists()) await part.delete();
    } catch (_) {}
  }

  /// `true` si [error] es "no queda espacio en el dispositivo".
  @visibleForTesting
  static bool isNoSpaceError(Object error) {
    if (error is! FileSystemException) return false;
    final code = error.osError?.errorCode;
    return code == 28 || code == 112;
  }

  /// Nombre estable en disco para [url]: hash de 64 bits más la extensión.
  @visibleForTesting
  static String fileNameFor(String url) {
    const prime = 0x100000001b3;
    var hash = 0xcbf29ce484222325;
    for (final unit in utf8.encode(url)) {
      hash = (hash ^ unit) * prime;
    }
    final extension = p.extension(Uri.tryParse(url)?.path ?? '');
    final safe = RegExp(r'^\.[A-Za-z0-9]{1,5}$').hasMatch(extension)
        ? extension.toLowerCase()
        : '';
    final digits = BigInt.from(hash).toUnsigned(64).toRadixString(16);
    return '${digits.padLeft(16, '0')}$safe';
  }
}
