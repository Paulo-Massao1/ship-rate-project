import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/core/module_access.dart';

void main() {
  group('ModuleAccess.isRestrictedUser', () {
    test('restricts the external app reviewer by normalized email', () {
      expect(
        ModuleAccess.isRestrictedUser(email: '  TESTERAPPTORES@GMAIL.COM  '),
        isTrue,
      );
    });

    test('restricts the external app reviewer by uid', () {
      expect(
        ModuleAccess.isRestrictedUser(uid: '3tXrdYuTfgQsQgzvqbluyh0u7Xz2'),
        isTrue,
      );
    });

    test('keeps the existing ADJ and CSPAM restrictions', () {
      expect(
        ModuleAccess.isRestrictedUser(email: 'jean@adjservicos.com.br'),
        isTrue,
      );
      expect(
        ModuleAccess.isRestrictedUser(email: 'qualquer@cspam.com.br'),
        isTrue,
      );
    });

    test('does not restrict an unrelated account', () {
      expect(
        ModuleAccess.isRestrictedUser(email: 'pilot@example.com'),
        isFalse,
      );
    });
  });
}
