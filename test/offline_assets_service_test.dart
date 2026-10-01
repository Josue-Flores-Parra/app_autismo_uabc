import 'dart:async';
import 'dart:io';

import 'package:appy/data/services/offline_assets_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('offline_assets_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Cliente falso: `responses` decide qué devuelve cada URL en cada intento.
  MockClient fakeClient(
    Map<String, List<http.StreamedResponse Function()>> responses,
    List<String> requested,
  ) {
    return MockClient.streaming((request, _) async {
      final url = request.url.toString();
      requested.add(url);
      final queue = responses[url]!;
      final build = queue.length > 1 ? queue.removeAt(0) : queue.first;
      return build();
    });
  }

  http.StreamedResponse ok(List<int> bytes, {int? declared}) =>
      http.StreamedResponse(
        Stream.value(bytes),
        200,
        contentLength: declared ?? bytes.length,
      );

  OfflineAssetsService serviceWith(MockClient client) => OfflineAssetsService(
    client: client,
    root: root,
    retryDelays: const [Duration.zero, Duration.zero],
  );

  const a = 'https://storage.test/a.png';
  const b = 'https://storage.test/b.mp4?alt=media&token=x';

  group('fileNameFor', () {
    test('is stable and keeps a safe extension', () {
      expect(
        OfflineAssetsService.fileNameFor(a),
        OfflineAssetsService.fileNameFor(a),
      );
      expect(OfflineAssetsService.fileNameFor(a), endsWith('.png'));
      expect(OfflineAssetsService.fileNameFor(b), endsWith('.mp4'));
      expect(
        OfflineAssetsService.fileNameFor(a),
        isNot(OfflineAssetsService.fileNameFor(b)),
      );
    });

    test('drops an extension that is not plain', () {
      final name = OfflineAssetsService.fileNameFor('https://x.test/f.@@@');
      expect(name, isNot(contains('.')));
      expect(name.length, 16);
    });
  });

  test('downloads a module and serves its files locally', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [
          () => ok([1, 2, 3]),
        ],
        b: [
          () => ok([4, 5]),
        ],
      }, requested),
    );
    await service.init();
    final progress = <String>[];

    await service.downloadModule('higiene', [
      a,
      b,
    ], onProgress: (done, total) => progress.add('$done/$total'));

    expect(progress, ['0/2', '1/2', '2/2']);
    expect(service.statusOf('higiene', [a, b]), OfflineModuleStatus.downloaded);
    expect(service.bytesOf('higiene'), 5);
    expect(File(service.localPath(a)!).readAsBytesSync(), [1, 2, 3]);
    expect(File(service.localPath(b)!).readAsBytesSync(), [4, 5]);
    expect(service.localPath('https://storage.test/otro.png'), isNull);
  });

  test('does not download again what is already complete', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [
          () => ok([1, 2, 3]),
        ],
      }, requested),
    );
    await service.init();

    await service.downloadModule('higiene', [a]);
    await service.downloadModule('higiene', [a]);

    expect(requested, [a]);
  });

  test('a truncated file is rejected and leaves nothing on disk', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [
          () => ok([1, 2], declared: 10),
        ],
      }, requested),
    );
    await service.init();

    await expectLater(
      service.downloadModule('higiene', [a]),
      throwsA(
        isA<OfflineDownloadException>().having(
          (e) => e.error,
          'error',
          OfflineDownloadError.incomplete,
        ),
      ),
    );

    expect(requested.length, 3, reason: 'intento inicial y dos reintentos');
    expect(service.localPath(a), isNull);
    expect(service.statusOf('higiene', [a]), OfflineModuleStatus.notDownloaded);
    final leftovers = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.part'));
    expect(leftovers, isEmpty);
  });

  test('keeps what was saved when a later file fails', () async {
    final requested = <String>[];
    final responses = <String, List<http.StreamedResponse Function()>>{
      a: [
        () => ok([1, 2, 3]),
      ],
      b: [() => http.StreamedResponse(const Stream.empty(), 404)],
    };
    final service = serviceWith(fakeClient(responses, requested));
    await service.init();

    await expectLater(
      service.downloadModule('higiene', [a, b]),
      throwsA(isA<OfflineDownloadException>()),
    );

    expect(service.statusOf('higiene', [a, b]), OfflineModuleStatus.partial);

    // Al reintentar solo se pide el archivo que faltaba.
    requested.clear();
    responses[b] = [
      () => ok([4, 5]),
    ];
    await service.downloadModule('higiene', [a, b]);
    expect(requested, [b]);
    expect(service.statusOf('higiene', [a, b]), OfflineModuleStatus.downloaded);
  });

  test('retries a network error and then succeeds', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [
          () => throw const SocketException('sin red'),
          () => ok([1, 2, 3]),
        ],
      }, requested),
    );
    await service.init();

    await service.downloadModule('higiene', [a]);

    expect(requested.length, 2);
    expect(service.statusOf('higiene', [a]), OfflineModuleStatus.downloaded);
  });

  test('does not retry a missing file', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [() => http.StreamedResponse(const Stream.empty(), 404)],
      }, requested),
    );
    await service.init();

    await expectLater(
      service.downloadModule('higiene', [a]),
      throwsA(
        isA<OfflineDownloadException>().having(
          (e) => e.error,
          'error',
          OfflineDownloadError.server,
        ),
      ),
    );

    expect(requested.length, 1);
  });

  test('recognizes a full disk', () {
    expect(
      OfflineAssetsService.isNoSpaceError(
        const FileSystemException('x', '', OSError('No space left', 28)),
      ),
      isTrue,
    );
    expect(
      OfflineAssetsService.isNoSpaceError(
        const FileSystemException('x', '', OSError('Other', 2)),
      ),
      isFalse,
    );
    expect(OfflineAssetsService.isNoSpaceError(Exception('x')), isFalse);
  });

  test('init restores what was downloaded and drops damaged files', () async {
    final requested = <String>[];
    final first = serviceWith(
      fakeClient({
        a: [
          () => ok([1, 2, 3]),
        ],
        b: [
          () => ok([4, 5]),
        ],
      }, requested),
    );
    await first.init();
    await first.downloadModule('higiene', [a, b]);
    File(first.localPath(b)!).writeAsBytesSync([9]);

    final second = serviceWith(fakeClient({}, requested));
    await second.init();

    expect(second.localPath(a), isNotNull);
    expect(second.localPath(b), isNull);
    expect(second.statusOf('higiene', [a, b]), OfflineModuleStatus.partial);
  });

  test(
    'serves images from disk once downloaded and from network before',
    () async {
      final requested = <String>[];
      final service = serviceWith(
        fakeClient({
          a: [
            () => ok([1, 2, 3]),
          ],
        }, requested),
      );
      await service.init();

      expect(service.imageProvider(a), isA<NetworkImage>());
      await service.downloadModule('higiene', [a]);

      expect(service.imageProvider(a), isA<FileImage>());
      expect(service.localPath(' $a '), service.localPath(a));
    },
  );

  test('deleting a module removes its files and its entries', () async {
    final requested = <String>[];
    final service = serviceWith(
      fakeClient({
        a: [
          () => ok([1, 2, 3]),
        ],
      }, requested),
    );
    await service.init();
    await service.downloadModule('higiene', [a]);
    final path = service.localPath(a)!;

    await service.deleteModule('higiene');

    expect(service.localPath(a), isNull);
    expect(File(path).existsSync(), isFalse);
    expect(service.statusOf('higiene', [a]), OfflineModuleStatus.notDownloaded);
  });

  test('a timeout while downloading counts as a network error', () async {
    final service = OfflineAssetsService(
      client: MockClient.streaming(
        (request, _) => Completer<http.StreamedResponse>().future,
      ),
      root: root,
      retryDelays: const [],
      timeout: const Duration(milliseconds: 20),
    );
    await service.init();

    await expectLater(
      service.downloadModule('higiene', [a]),
      throwsA(
        isA<OfflineDownloadException>().having(
          (e) => e.error,
          'error',
          OfflineDownloadError.network,
        ),
      ),
    );
  });
}
