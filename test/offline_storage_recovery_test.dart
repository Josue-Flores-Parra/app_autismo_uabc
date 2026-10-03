import 'dart:async';
import 'dart:io';

import 'package:appy/core/app_theme.dart';
import 'package:appy/data/services/offline_assets_service.dart';
import 'package:appy/features/offline/view/downloads_screen.dart';
import 'package:appy/features/offline/viewmodel/downloads_viewmodel.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

const _a = 'https://storage.test/a.png';
const _b = 'https://storage.test/b.png';
const _c = 'https://storage.test/c.png';
const _noSpace = FileSystemException(
  'Disco lleno',
  '',
  OSError('No space left', 28),
);

/// Escribe bytes reales antes de simular ENOSPC y registra el cierre del archivo.
class _FailingFile extends Fake implements RandomAccessFile {
  _FailingFile(this.file, {this.onFailure});
  final RandomAccessFile file;
  final Future<void> Function()? onFailure;
  bool closed = false;
  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await file.writeFrom(buffer, start, end);
    await onFailure?.call();
    throw _noSpace;
  }

  @override
  Future<void> close() async {
    closed = true;
    await file.close();
  }
}

http.Client _client() => MockClient.streaming(
  (_, _) async =>
      http.StreamedResponse(Stream.value([1, 2, 3]), 200, contentLength: 3),
);
DownloadsViewModel _vm(OfflineAssetsService service, {String? videoUrl}) =>
    DownloadsViewModel(
      service,
      loadModules: () async => [
        {'id': 'module', 'titulo': 'Módulo'},
      ],
      loadLevels: (_) async => [
        {
          'id': 'level',
          'pictogramaUrl': _a,
          'audioUrl': _b,
          'videoUrl': videoUrl,
        },
      ],
    );

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('storage_recovery'),
  );
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'ENOSPC while writing closes the file and leaves partial download deletable',
    () async {
      late _FailingFile failedFile;
      var requests = 0;
      final service = OfflineAssetsService(
        root: root,
        client: MockClient.streaming((_, _) async {
          requests++;
          return http.StreamedResponse(
            Stream.value([1, 2, 3]),
            200,
            contentLength: 3,
          );
        }),
        openDownloadFile: (file) async {
          final output = await file.open(mode: FileMode.write);
          if (p.basename(file.path) ==
              '${OfflineAssetsService.fileNameFor(_b)}.part') {
            return failedFile = _FailingFile(output);
          }
          return output;
        },
      );
      await service.init();
      final vm = _vm(service);
      await vm.load();
      await vm.download('module').timeout(const Duration(seconds: 2));
      expect(failedFile.closed, isTrue);
      expect(requests, 2, reason: 'Sin reintentos cuando el disco está lleno.');
      expect(vm.modules.single.error, OfflineDownloadError.noSpace);
      expect(vm.modules.single.status, OfflineModuleStatus.partial);
      expect(vm.modules.single.canDelete, isTrue);
      expect(vm.modules.single.bytes, 3);
      await vm.delete('module');
      expect(root.listSync(), isEmpty);
      expect(vm.modules.single.bytes, 0);
      vm.dispose();
    },
  );

  test(
    'ENOSPC opening the file cancels the response stream without waiting for more data',
    () async {
      var streamCancelled = false;
      final stream = StreamController<List<int>>(
        onCancel: () => streamCancelled = true,
      );
      final service = OfflineAssetsService(
        root: root,
        client: MockClient.streaming(
          (_, _) async => http.StreamedResponse(stream.stream, 200),
        ),
        openDownloadFile: (_) async => throw _noSpace,
      );
      await service.init();
      await expectLater(
        service
            .downloadModule('module', [_a])
            .timeout(const Duration(seconds: 2)),
        throwsA(
          isA<OfflineDownloadException>().having(
            (error) => error.error,
            'error',
            OfflineDownloadError.noSpace,
          ),
        ),
      );
      expect(streamCancelled, isTrue);
      await stream.close();
    },
  );

  test(
    'cancel during ENOSPC finishes even when restoring manifest also fails',
    () async {
      final failureReady = Completer<void>();
      final releaseFailure = Completer<void>();
      var denyManifest = false;
      final service = OfflineAssetsService(
        root: root,
        client: _client(),
        openDownloadFile: (file) async {
          final output = await file.open(mode: FileMode.write);
          if (p.basename(file.path) ==
              '${OfflineAssetsService.fileNameFor(_c)}.part') {
            return _FailingFile(
              output,
              onFailure: () {
                failureReady.complete();
                return releaseFailure.future;
              },
            );
          }
          return output;
        },
        writeManifest: (file, contents) async {
          if (denyManifest) throw _noSpace;
          await file.writeAsString(contents);
        },
      );
      await service.init();
      await service.downloadModule('module', [_a]);
      final previousPath = service.localPath(_a)!;
      denyManifest = true;
      final vm = _vm(service, videoUrl: _c);
      await vm.load();
      final downloading = vm.download('module');
      await failureReady.future;
      final cancel = vm.cancel('module');
      expect(vm.modules.single.phase, ModuleDownloadPhase.cancelling);
      releaseFailure.complete();
      await cancel.timeout(const Duration(seconds: 2));
      await downloading;
      expect(vm.modules.single.phase, ModuleDownloadPhase.idle);
      expect(vm.modules.single.error, isNull);
      expect(File(previousPath).existsSync(), isTrue);
      expect(service.localPath(_b), isNull);
      expect(service.bytesOf('module'), 3);
      await service.init();
      expect(service.localPath(_a), previousPath);
      await service.deleteModule('module');
      expect(root.listSync(), isEmpty);
      vm.dispose();
    },
  );

  test(
    'manifest ENOSPC retains measurable files and permits deleting them after restart',
    () async {
      final first = OfflineAssetsService(
        root: root,
        client: _client(),
        writeManifest: (_, _) async => throw _noSpace,
      );
      await first.init();
      await expectLater(
        first.downloadModule('module', [_a]),
        throwsA(
          isA<OfflineDownloadException>().having(
            (e) => e.error,
            'error',
            OfflineDownloadError.noSpace,
          ),
        ),
      );
      final restarted = OfflineAssetsService(root: root, client: _client());
      await restarted.init();
      expect(restarted.bytesOf('module'), 3);
      expect(restarted.statusOf('module', [_a]), OfflineModuleStatus.partial);
      await restarted.deleteModule('module');
      expect(root.listSync(), isEmpty);
    },
  );

  testWidgets(
    'failed manifest update preserves earlier metadata and leaves both files deletable',
    (tester) async {
      await tester.runAsync(() async {
        var denyManifest = false;
        final service = OfflineAssetsService(
          root: root,
          client: _client(),
          writeManifest: (file, contents) async {
            if (denyManifest) {
              await file.writeAsString(contents.substring(0, 10));
              throw _noSpace;
            }
            await file.writeAsString(contents);
          },
        );
        await service.init();
        await service.downloadModule('module', [_a]);
        final manifest = File(p.join(root.path, 'module', 'manifest.json'));
        final original = await manifest.readAsString();
        denyManifest = true;
        await expectLater(
          service.downloadModule('module', [_a, _b]),
          throwsA(
            isA<OfflineDownloadException>().having(
              (error) => error.error,
              'error',
              OfflineDownloadError.noSpace,
            ),
          ),
        );
        expect(await manifest.readAsString(), original);
        await service.init();
        expect(service.localPath(_a), isNotNull);
        expect(service.localPath(_b), isNull);
        expect(service.bytesOf('module'), 6);
        expect(
          service.statusOf('module', [_a, _b]),
          OfflineModuleStatus.partial,
        );
        await service.deleteModule('module');
        expect(root.listSync(), isEmpty);
      });
    },
  );

  testWidgets(
    'orphan files with broken manifest expose working Delete in downloads',
    (tester) async {
      final service = OfflineAssetsService(root: root, client: _client());
      final vm = _vm(service);
      await tester.runAsync(() async {
        final dir = Directory(p.join(root.path, 'module'));
        await dir.create();
        await File(p.join(dir.path, 'orphan.mp4')).writeAsBytes([1, 2, 3]);
        await File(
          p.join(dir.path, 'unfinished.png.part'),
        ).writeAsBytes([4, 5]);
        await File(p.join(dir.path, 'manifest.json')).writeAsString('{broken');
        await service.init();
        await vm.load();
      });
      expect(vm.modules.single.status, OfflineModuleStatus.partial);
      expect(vm.modules.single.bytes, 5);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light(
              fontScale: 1,
              highContrast: false,
              reduceMotion: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2.3)),
              child: child!,
            ),
            home: const DownloadsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_outline_rounded),
        200,
      );
      await tester.pumpAndSettle();
      // La acción que inicia E/S debe ejecutarse fuera del reloj simulado del widget.
      await tester.runAsync(
        () => tester.tap(find.byIcon(Icons.delete_outline_rounded)),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            AppLocalizations.of(
              tester.element(find.byType(AlertDialog)),
            ).downloadsDeleteTooltip,
          ),
        );
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return vm.modules.single.bytes != 0;
        }).timeout(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
      expect(vm.modules.single.bytes, 0);
      expect(root.listSync(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
