import 'package:finbalance/data/update/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isNewerVersion compares tags against the installed version', () {
    expect(isNewerVersion('v0.20.0', '0.19.0'), isTrue);
    expect(isNewerVersion('v1.0.0', '0.19.9+19'), isTrue);
    expect(isNewerVersion('v0.19.0', '0.19.0'), isFalse);
    expect(isNewerVersion('v0.9.0', '0.19.0'), isFalse);
  });
}
