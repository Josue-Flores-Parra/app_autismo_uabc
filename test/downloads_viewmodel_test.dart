import 'dart:io';

import 'package:appy/data/services/offline_assets_service.dart';
import 'package:appy/features/offline/viewmodel/downloads_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('downloads_vm_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  OfflineAssetsService service() => OfflineAssetsService(
    client: MockClient.streaming(
      (request, _) async =>
          http.StreamedResponse(Stream.value([1, 2, 3]), 200, contentLength: 3),
    ),
    root: root,
    retryDelays: const [Duration.zero],
  );

  const picture = 'https://storage.test/a.png';

  test('lists the modules of the catalog without a learner profile', () async {
    final viewModel = DownloadsViewModel(
      service(),
      loadModules: () async => [
        {'id': 'higiene', 'titulo': 'Higiene'},
        {'id': 'alimentacion', 'titulo': 'Alimentación'},
      ],
      loadLevels: (moduleId) async => [
        {
          'id': 'n1',
          'titulo': 'Nivel',
          'orden': 1,
          'pictogramaUrl': moduleId == 'higiene' ? picture : null,
        },
      ],
    );

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.modules.map((module) => module.moduleId), [
      'higiene',
      'alimentacion',
    ]);
    expect(viewModel.modules.first.title, 'Higiene');
    expect(viewModel.modules.first.status, OfflineModuleStatus.notDownloaded);
  });

  test('downloads a module read from the catalog', () async {
    final viewModel = DownloadsViewModel(
      service(),
      loadModules: () async => [
        {'id': 'higiene', 'titulo': 'Higiene'},
      ],
      loadLevels: (_) async => [
        {'id': 'n1', 'titulo': 'Nivel', 'orden': 1, 'pictogramaUrl': picture},
      ],
    );
    await viewModel.load();

    await viewModel.download('higiene');

    expect(viewModel.modules.single.status, OfflineModuleStatus.downloaded);
  });

  test('an empty catalog or a failing read leaves the list empty', () async {
    final failing = DownloadsViewModel(
      service(),
      loadModules: () async => throw StateError('sin red'),
      loadLevels: (_) async => [],
    );
    await failing.load();

    expect(failing.modules, isEmpty);
    expect(failing.isLoading, isFalse);
  });
}
