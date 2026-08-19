import 'package:codebook/security/vault_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Argon2id derived key can verify and decrypt AES-GCM payload', () async {
    final crypto = VaultCrypto();
    final salt = List<int>.generate(16, (index) => index + 1);
    final key = await crypto.deriveMasterKey(
      password: 'correct horse battery staple',
      salt: salt,
    );

    final verifier = await crypto.createVerifier(key);
    expect(await crypto.verifyKey(verifier, key), isTrue);

    final encrypted = await crypto.encryptJson(
      {
        'title': 'Example',
        'username': 'demo@example.com',
        'password': 'not-a-real-password',
      },
      key,
    );
    final clear = await crypto.decryptJson(encrypted, key);
    expect(clear['title'], 'Example');
    expect(clear['username'], 'demo@example.com');
    expect(clear['password'], 'not-a-real-password');
  });

  test('wrong master password fails verifier authentication', () async {
    final crypto = VaultCrypto();
    final salt = List<int>.generate(16, (index) => 255 - index);
    final correctKey = await crypto.deriveMasterKey(
      password: 'correct-password-for-test',
      salt: salt,
    );
    final wrongKey = await crypto.deriveMasterKey(
      password: 'wrong-password-for-test',
      salt: salt,
    );
    final verifier = await crypto.createVerifier(correctKey);

    expect(await crypto.verifyKey(verifier, wrongKey), isFalse);
  });
}
