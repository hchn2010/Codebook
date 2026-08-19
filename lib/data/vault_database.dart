import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class VaultDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    final path = p.join(root, 'codebook_vault.db');
    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vault_meta (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE vault_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            encrypted_payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_vault_items_updated_at ON vault_items(updated_at DESC)',
        );
      },
    );
    return _database!;
  }

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query(
      'vault_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> initializeMeta(Map<String, String> values) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert(
          'vault_meta',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> getItemRows() async {
    final db = await database;
    return db.query('vault_items', orderBy: 'updated_at DESC');
  }

  Future<int> insertItem({
    required String encryptedPayload,
    required int createdAt,
    required int updatedAt,
  }) async {
    final db = await database;
    return db.insert('vault_items', {
      'encrypted_payload': encryptedPayload,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  Future<void> updateItem({
    required int id,
    required String encryptedPayload,
    required int updatedAt,
  }) async {
    final db = await database;
    await db.update(
      'vault_items',
      {
        'encrypted_payload': encryptedPayload,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('vault_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
