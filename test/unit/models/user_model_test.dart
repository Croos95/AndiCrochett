// test/unit/models/user_model_test.dart
//
// Pruebas unitarias del UserModel y UserSettings. El interés está en el
// round-trip a SQLite (settings se serializa a JSON dentro de una columna).

import 'package:andicrochett/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSettings', () {
    test('toMap/fromMap es round-trip', () {
      const s = UserSettings(theme: 'dark', language: 'en', notifications: false);
      final r = UserSettings.fromMap(s.toMap());
      expect(r.theme, 'dark');
      expect(r.language, 'en');
      expect(r.notifications, false);
    });

    test('fromMap acepta notifications=1 (SQLite int → bool)', () {
      final r = UserSettings.fromMap({'theme': 'light', 'language': 'es', 'notifications': 1});
      expect(r.notifications, true);
    });
  });

  group('UserModel', () {
    test('toMap codifica settings como JSON string', () {
      final user = UserModel(
        uid: 'abc',
        email: 'a@b.com',
        displayName: 'Andi',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final map = user.toMap();
      expect(map['uid'], 'abc');
      expect(map['email'], 'a@b.com');
      expect(map['settings'], isA<String>());
      expect(map['settings'], contains('"theme":"light"'));
    });

    test('fromMap decodifica settings desde JSON string', () {
      final restored = UserModel.fromMap({
        'uid': 'abc',
        'email': 'a@b.com',
        'display_name': 'Andi',
        'photo_url': '',
        'auth_provider': 'email',
        'fecha_creacion': DateTime.utc(2026, 1, 1).toIso8601String(),
        'fecha_actualizacion': DateTime.utc(2026, 1, 1).toIso8601String(),
        'settings': '{"theme":"dark","language":"es","notifications":true}',
      });

      expect(restored.settings.theme, 'dark');
      expect(restored.settings.notifications, true);
    });

    test('igualdad basada en uid + email', () {
      final a = UserModel(uid: 'x', email: 'e', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final b = UserModel(uid: 'x', email: 'e', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final c = UserModel(uid: 'y', email: 'e', createdAt: DateTime.now(), updatedAt: DateTime.now());
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
