import 'package:appy/shared/services/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and reads PINs isolated per account', () async {
    await PinService.setPin('uid-a', '2468');
    await PinService.setPin('uid-b', '1357');

    expect(await PinService.getPin('uid-a'), '2468');
    expect(await PinService.getPin('uid-b'), '1357');
  });

  test('clearing one account does not touch the other', () async {
    await PinService.setPin('uid-a', '2468');
    await PinService.setPin('uid-b', '1357');

    await PinService.clearPin('uid-a');

    expect(await PinService.getPin('uid-a'), isNull);
    expect(await PinService.getPin('uid-b'), '1357');
  });

  test('discards the legacy global PIN instead of assigning it', () async {
    SharedPreferences.setMockInitialValues({'settingsPin': '9999'});

    // Neither the old nor a fresh account inherits the device-wide PIN.
    expect(await PinService.getPin('uid-old'), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('settingsPin'), isFalse);

    // Each account then sets its own PIN exactly once.
    await PinService.setPin('uid-old', '2468');
    expect(await PinService.getPin('uid-old'), '2468');
    expect(await PinService.getPin('uid-fresh'), isNull);
  });
}
