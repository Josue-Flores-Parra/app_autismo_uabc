import 'dart:async';

import 'package:appy/data/services/network_connection_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final type in [
    ConnectivityResult.wifi,
    ConnectivityResult.mobile,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
    ConnectivityResult.none,
  ]) {
    test(
      'initial network status distinguishes $type from disconnected',
      () async {
        final service = NetworkConnectionService(
          check: () async => [type],
          changes: const Stream.empty(),
        );
        expect(service.status, NetworkConnectionStatus.unknown);
        await service.start();
        expect(
          service.status,
          type == ConnectivityResult.none
              ? NetworkConnectionStatus.disconnected
              : NetworkConnectionStatus.connected,
        );
        service.dispose();
      },
    );
  }

  test(
    'failed or empty network checks remain unknown rather than falsely offline',
    () async {
      var fail = true;
      final service = NetworkConnectionService(
        check: () async {
          if (fail) throw StateError('plugin unavailable');
          return [];
        },
        changes: const Stream.empty(),
      );
      await service.start();
      expect(service.status, NetworkConnectionStatus.unknown);
      fail = false;
      await service.refresh();
      expect(service.status, NetworkConnectionStatus.unknown);
      service.dispose();
    },
  );

  test('late initial check cannot replace a newer connection change', () async {
    final checked = Completer<List<ConnectivityResult>>();
    final changes = StreamController<List<ConnectivityResult>>.broadcast(
      sync: true,
    );
    final service = NetworkConnectionService(
      check: () => checked.future,
      changes: changes.stream,
    );
    final starting = service.start();
    changes.add([ConnectivityResult.none]);
    checked.complete([ConnectivityResult.wifi]);
    await starting;
    expect(service.status, NetworkConnectionStatus.disconnected);
    service.dispose();
    await changes.close();
  });

  test(
    'resume hides stale offline status while checking the new connection',
    () async {
      final resumed = Completer<List<ConnectivityResult>>();
      var first = true;
      final service = NetworkConnectionService(
        check: () {
          if (first) {
            first = false;
            return Future.value([ConnectivityResult.none]);
          }
          return resumed.future;
        },
        changes: const Stream.empty(),
      );
      await service.start();
      expect(service.status, NetworkConnectionStatus.disconnected);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.status, NetworkConnectionStatus.unknown);
      resumed.complete([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(service.status, NetworkConnectionStatus.connected);
      service.dispose();
    },
  );
}
