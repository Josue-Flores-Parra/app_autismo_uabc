import 'dart:async';
import 'dart:io';

import 'package:appy/data/services/offline_assets_service.dart';
import 'package:appy/features/offline/viewmodel/downloads_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cancel_download');
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  const a = 'https://storage.test/a.png';
  const b = 'https://storage.test/b.png';
  const c = 'https://storage.test/c.png';
  http.StreamedResponse ok() =>
      http.StreamedResponse(Stream.value([1, 2, 3]), 200, contentLength: 3);

  test(
    'cancel while requesting rolls back only this attempt and persists old manifest',
    () async {
      final requested = Completer<void>();
      final response = Completer<http.StreamedResponse>();
      final service = OfflineAssetsService(
        root: root,
        client: MockClient.streaming((request, _) {
          if (request.url.toString() == c) {
            requested.complete();
            return response.future;
          }
          return Future.value(ok());
        }),
      );
      await service.init();
      await service.downloadModule('module', [a]);
      final oldPath = service.localPath(a)!;
      final downloading = service.downloadModule('module', [a, b, c]);
      final assertion = expectLater(
        downloading,
        throwsA(isA<OfflineDownloadCancelled>()),
      );
      await requested.future;
      await service.cancelDownload('module');
      response.complete(ok());
      await assertion;
      expect(File(oldPath).existsSync(), isTrue);
      expect(service.localPath(b), isNull);
      expect(service.bytesOf('module'), 3);
      await service.init();
      expect(
        service.statusOf('module', [a, b, c]),
        OfflineModuleStatus.partial,
      );
      expect(
        root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.part')),
        isEmpty,
      );
    },
  );

  test('cancel streaming deletes partial file and permits retry', () async {
    final listening = Completer<void>();
    final stream = StreamController<List<int>>(
      onListen: () => listening.complete(),
    );
    var first = true;
    final service = OfflineAssetsService(
      root: root,
      client: MockClient.streaming((request, _) async {
        if (first) {
          first = false;
          return http.StreamedResponse(stream.stream, 200, contentLength: 100);
        }
        return ok();
      }),
    );
    await service.init();
    final downloading = service.downloadModule('module', [a]);
    final assertion = expectLater(
      downloading,
      throwsA(isA<OfflineDownloadCancelled>()),
    );
    await listening.future;
    stream.add([1, 2]);
    await service.cancelDownload('module');
    await assertion;
    await stream.close();
    expect(service.localPath(a), isNull);
    expect(
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.part')),
      isEmpty,
    );
    await service.downloadModule('module', [a]);
    expect(service.statusOf('module', [a]), OfflineModuleStatus.downloaded);
  });

  test('cancel interrupts retry wait without another request', () async {
    var requests = 0;
    final reachedRetry = Completer<void>();
    final service = OfflineAssetsService(
      root: root,
      retryDelays: const [Duration(minutes: 1)],
      client: MockClient.streaming((_, _) async {
        requests++;
        reachedRetry.complete();
        return http.StreamedResponse(Stream.value([]), 503);
      }),
    );
    await service.init();
    final downloading = service.downloadModule('module', [a]);
    final assertion = expectLater(
      downloading,
      throwsA(isA<OfflineDownloadCancelled>()),
    );
    await reachedRetry.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.cancelDownload('module').timeout(const Duration(seconds: 1));
    await assertion;
    expect(requests, 1);
  });

  test(
    'cancel from final progress callback rolls back completed new files',
    () async {
      final service = OfflineAssetsService(
        root: root,
        client: MockClient.streaming((_, _) async => ok()),
      );
      await service.init();
      await expectLater(
        service.downloadModule(
          'module',
          [a, b],
          onProgress: (done, total) {
            if (done == total) unawaited(service.cancelDownload('module'));
          },
        ),
        throwsA(isA<OfflineDownloadCancelled>()),
      );
      expect(service.bytesOf('module'), 0);
      expect(service.localPath(a), isNull);
      expect(service.localPath(b), isNull);
    },
  );

  test('viewmodel exposes cancelling and resets without a failure', () async {
    final requested = Completer<void>();
    final response = Completer<http.StreamedResponse>();
    final service = OfflineAssetsService(
      root: root,
      client: MockClient.streaming((_, _) {
        requested.complete();
        return response.future;
      }),
    );
    await service.init();
    final vm = DownloadsViewModel(
      service,
      loadModules: () async => [
        {'id': 'module', 'titulo': 'Module'},
      ],
      loadLevels: (_) async => [
        {'id': 'level', 'pictogramaUrl': a},
      ],
    );
    await vm.load();
    final download = vm.download('module');
    await requested.future;
    final cancel = vm.cancel('module');
    expect(vm.modules.single.phase, ModuleDownloadPhase.cancelling);
    await cancel;
    await download;
    response.complete(ok());
    expect(vm.modules.single.phase, ModuleDownloadPhase.idle);
    expect(vm.modules.single.error, isNull);
    vm.dispose();
  });
}
