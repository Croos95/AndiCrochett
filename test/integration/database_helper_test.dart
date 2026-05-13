// test/integration/database_helper_test.dart
//
// Pruebas de integración del DatabaseHelper contra SQLite real (FFI).
// Usan sqflite_common_ffi para correr el motor SQLite en el runner de tests
// (escritorio/CI), sin emulador. Cada test arranca con BD limpia.

import 'dart:io';

import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Activa el motor FFI para escritorio/CI.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // BD limpia por cada test: cerrar singleton + borrar archivo.
    await DatabaseHelper.instance.closeDatabase();
    final dbPath = p.join(await getDatabasesPath(), 'andicrochett.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.closeDatabase();
    final dbPath = p.join(await getDatabasesPath(), 'andicrochett.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  });

  group('Productos (CRUD)', () {
    test('addProduct + getAllProducts devuelve lo insertado', () async {
      final id = await DatabaseHelper.instance.addProduct(
        const ProductModel(
          name: 'Estambre azul',
          price: 99.0,
          currentStock: 10,
        ).toMap(),
      );

      expect(id, isPositive);

      final all = await DatabaseHelper.instance.getAllProducts();
      expect(all, hasLength(1));
      expect(all.first['nombre'], 'Estambre azul');
      expect(all.first['cantidad'], 10);
    });

    test('updateProductQuantity persiste el nuevo valor', () async {
      final id = await DatabaseHelper.instance.addProduct(
        const ProductModel(name: 'X', price: 1.0, currentStock: 5).toMap(),
      );
      await DatabaseHelper.instance.updateProductQuantity(id, 2);
      final qty = await DatabaseHelper.instance.getProductQuantity(id);
      expect(qty, 2);
    });

    test('deleteProduct lo elimina', () async {
      final id = await DatabaseHelper.instance.addProduct(
        const ProductModel(name: 'Borrar', price: 10, currentStock: 1).toMap(),
      );
      final deleted = await DatabaseHelper.instance.deleteProduct(id);
      expect(deleted, 1);

      final all = await DatabaseHelper.instance.getAllProducts();
      expect(all, isEmpty);
    });

    test('searchProducts filtra por LIKE', () async {
      await DatabaseHelper.instance.addProduct(
        const ProductModel(
          name: 'Estambre rojo',
          price: 1,
          currentStock: 1,
        ).toMap(),
      );
      await DatabaseHelper.instance.addProduct(
        const ProductModel(
          name: 'Aguja 3mm',
          price: 1,
          currentStock: 1,
        ).toMap(),
      );

      final matches = await DatabaseHelper.instance.searchProducts('Estambre');
      expect(matches, hasLength(1));
      expect(matches.first['nombre'], 'Estambre rojo');
    });
  });

  group('Clientes (CRUD)', () {
    test('addClient + getAllClients', () async {
      final id = await DatabaseHelper.instance.addClient(
        'Andrea',
        'a@b.com',
        '555',
        'CDMX',
      );
      expect(id, isPositive);

      final clients = await DatabaseHelper.instance.getAllClients();
      expect(clients, hasLength(1));
      expect(clients.first['nombre'], 'Andrea');
      expect(clients.first['email'], 'a@b.com');
    });

    test('updateClient parcial respeta campos no pasados', () async {
      final id = await DatabaseHelper.instance.addClient(
        'A',
        'x@y.z',
        '1',
        'sin dir',
      );
      await DatabaseHelper.instance.updateClient(id, telefono: '999');

      final all = await DatabaseHelper.instance.getAllClients();
      expect(all.first['telefono'], '999');
      expect(all.first['nombre'], 'A'); // intacto
    });
  });

  group('Schema', () {
    test('versión de la BD es la esperada', () async {
      // Fuerza la inicialización
      final db = await DatabaseHelper.instance.database;
      expect(await db.getVersion(), 9);
    });
  });
}
