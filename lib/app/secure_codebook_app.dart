import 'package:flutter/material.dart';

import '../repositories/vault_repository.dart';
import '../screens/auth_screens.dart';
import 'theme.dart';

class SecureCodebookApp extends StatefulWidget {
  const SecureCodebookApp({super.key});

  @override
  State<SecureCodebookApp> createState() => _SecureCodebookAppState();
}

class _SecureCodebookAppState extends State<SecureCodebookApp> {
  late final VaultRepository _repository = VaultRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '密码本',
      debugShowCheckedModeBanner: false,
      theme: buildCodebookTheme(),
      home: BootstrapScreen(repository: _repository),
    );
  }
}
