import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../data/vault_database.dart';
import '../models/vault_item.dart';
import '../security/vault_crypto.dart';

class VaultLockedException implements Exception {
  const VaultLockedException();

  @override
  String toString() => 'Vault is locked';
}

class VaultRepository {
  VaultRepository({VaultDatabase? database, VaultCrypto? crypto})
      : _database = database ?? VaultDatabase(),
        _crypto = crypto ?? VaultCrypto();

  static const _saltKey = 'kdf_salt_v1';
  static const _verifierKey = 'verifier_v1';
  static const _schemaKey = 'vault_schema';

  final VaultDatabase _database;
  final VaultCrypto _crypto;
  SecretKey? _masterKey;

  bool get isUnlocked => _masterKey != null;

  Future<bool> isInitialized() async {
    return await _database.getMeta(_saltKey) != null &&
        await _database.getMeta(_verifierKey) != null;
  }

  Future<void> createVault(String password) async {
    if (await isInitialized()) {
      throw StateError('Vault already exists');
    }
    final salt = _crypto.newSalt();
    final key = await _crypto.deriveMasterKey(password: password, salt: salt);
    final verifier = await _crypto.createVerifier(key);
    await _database.initializeMeta({
      _saltKey: base64Encode(salt),
      _verifierKey: verifier.toJsonString(),
      _schemaKey: '1',
    });
    _masterKey = key;
  }

  Future<bool> unlock(String password) async {
    final saltValue = await _database.getMeta(_saltKey);
    final verifierValue = await _database.getMeta(_verifierKey);
    if (saltValue == null || verifierValue == null) return false;

    final key = await _crypto.deriveMasterKey(
      password: password,
      salt: base64Decode(saltValue),
    );
    final verifier = EncryptedPayload.fromJsonString(verifierValue);
    final valid = await _crypto.verifyKey(verifier, key);
    if (!valid) return false;
    _masterKey = key;
    return true;
  }

  void lock() {
    _masterKey = null;
  }

  Future<List<VaultItem>> listItems() async {
    final key = _requireKey();
    final rows = await _database.getItemRows();
    final items = <VaultItem>[];
    for (final row in rows) {
      final payload = EncryptedPayload.fromJsonString(
        row['encrypted_payload'] as String,
      );
      final data = await _crypto.decryptJson(payload, key);
      items.add(
        VaultItem.fromEncryptedJson(
          data,
          id: row['id'] as int,
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
        ),
      );
    }
    return items;
  }

  Future<VaultItem> addItem(VaultItem item) async {
    final key = _requireKey();
    final now = DateTime.now();
    final normalized = item.copyWith(createdAt: now, updatedAt: now);
    final payload = await _crypto.encryptJson(normalized.toEncryptedJson(), key);
    final id = await _database.insertItem(
      encryptedPayload: payload.toJsonString(),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
    return normalized.copyWith(id: id);
  }

  Future<VaultItem> updateItem(VaultItem item) async {
    final id = item.id;
    if (id == null) throw ArgumentError('Item id is required for update');
    final key = _requireKey();
    final now = DateTime.now();
    final normalized = item.copyWith(updatedAt: now);
    final payload = await _crypto.encryptJson(normalized.toEncryptedJson(), key);
    await _database.updateItem(
      id: id,
      encryptedPayload: payload.toJsonString(),
      updatedAt: now.millisecondsSinceEpoch,
    );
    return normalized;
  }

  Future<void> deleteItem(int id) async {
    _requireKey();
    await _database.deleteItem(id);
  }

  SecretKey _requireKey() {
    final key = _masterKey;
    if (key == null) throw const VaultLockedException();
    return key;
  }
}
