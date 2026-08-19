import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class EncryptedPayload {
  const EncryptedPayload({
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  Map<String, dynamic> toJson() => {
        'nonce': base64Encode(nonce),
        'cipherText': base64Encode(cipherText),
        'mac': base64Encode(mac),
      };

  String toJsonString() => jsonEncode(toJson());

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      nonce: base64Decode(json['nonce'] as String),
      cipherText: base64Decode(json['cipherText'] as String),
      mac: base64Decode(json['mac'] as String),
    );
  }

  factory EncryptedPayload.fromJsonString(String value) {
    return EncryptedPayload.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  SecretBox toSecretBox() => SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      );
}

class VaultCrypto {
  VaultCrypto()
      : _cipher = AesGcm.with256bits(),
        _kdf = Argon2id(
          memory: 19 * 1024,
          parallelism: 1,
          iterations: 2,
          hashLength: 32,
        );

  static const int saltLength = 16;
  static const String verifierText = 'codebook-vault-verifier-v1';
  static const List<int> itemAad = <int>[
    99,
    111,
    100,
    101,
    98,
    111,
    111,
    107,
    58,
    105,
    116,
    101,
    109,
    58,
    118,
    49,
  ];
  static const List<int> verifierAad = <int>[
    99,
    111,
    100,
    101,
    98,
    111,
    111,
    107,
    58,
    118,
    101,
    114,
    105,
    102,
    105,
    101,
    114,
    58,
    118,
    49,
  ];

  final AesGcm _cipher;
  final Argon2id _kdf;
  final Random _random = Random.secure();

  List<int> newSalt() => List<int>.generate(saltLength, (_) => _random.nextInt(256));

  Future<SecretKey> deriveMasterKey({
    required String password,
    required List<int> salt,
  }) {
    return _kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<EncryptedPayload> encryptJson(
    Map<String, dynamic> json,
    SecretKey key,
  ) async {
    final clearText = utf8.encode(jsonEncode(json));
    final box = await _cipher.encrypt(
      clearText,
      secretKey: key,
      aad: itemAad,
    );
    return EncryptedPayload(
      nonce: box.nonce,
      cipherText: box.cipherText,
      mac: box.mac.bytes,
    );
  }

  Future<Map<String, dynamic>> decryptJson(
    EncryptedPayload payload,
    SecretKey key,
  ) async {
    final clearText = await _cipher.decrypt(
      payload.toSecretBox(),
      secretKey: key,
      aad: itemAad,
    );
    return jsonDecode(utf8.decode(clearText)) as Map<String, dynamic>;
  }

  Future<EncryptedPayload> createVerifier(SecretKey key) async {
    final box = await _cipher.encrypt(
      utf8.encode(verifierText),
      secretKey: key,
      aad: verifierAad,
    );
    return EncryptedPayload(
      nonce: box.nonce,
      cipherText: box.cipherText,
      mac: box.mac.bytes,
    );
  }

  Future<bool> verifyKey(EncryptedPayload verifier, SecretKey key) async {
    try {
      final clearText = await _cipher.decrypt(
        verifier.toSecretBox(),
        secretKey: key,
        aad: verifierAad,
      );
      return utf8.decode(clearText) == verifierText;
    } catch (_) {
      return false;
    }
  }
}
