import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../repositories/vault_repository.dart';
import '../widgets/codebook_widgets.dart';
import 'vault_shell.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({required this.repository, super.key});

  final VaultRepository repository;

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late final Future<bool> _initialized = widget.repository.isInitialized();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialized,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: AppBackdrop(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return snapshot.data!
            ? UnlockScreen(repository: widget.repository)
            : SetupScreen(repository: widget.repository);
      },
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.repository, super.key});

  final VaultRepository repository;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _hint = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _hint.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = '主密码至少需要 8 位，建议使用 12 位以上的长密码');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = '两次输入的主密码不一致');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.createVault(password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VaultShell(repository: widget.repository),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '创建密码库失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            children: [
              Text('创建主密码', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                '主密码用于解锁你的密码库，请务必牢记',
                style: TextStyle(color: CodebookColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Icon(
                  Icons.lock_rounded,
                  size: 94,
                  color: CodebookColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _password,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: '输入主密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: '再次输入主密码',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _hint,
                decoration: const InputDecoration(
                  labelText: '密码提示（可选，仅作为你的记忆提示）',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: CodebookColors.danger)),
              ],
              const SizedBox(height: 18),
              const GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.security, color: CodebookColors.primary),
                      title: Text('Argon2id + AES-256-GCM'),
                      subtitle: Text('主密码不写入数据库，账号字段整体加密后保存'),
                    ),
                    Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.offline_bolt_outlined, color: CodebookColors.success),
                      title: Text('离线优先'),
                      subtitle: Text('V0.1 不上传服务器，不需要注册账号'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: CodebookColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '主密码无法找回。生物识别与截图保护将在下一安全阶段接入 Android 系统能力。',
                        style: TextStyle(color: CodebookColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: '创建密码库',
                onPressed: _createVault,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({required this.repository, super.key});

  final VaultRepository repository;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await widget.repository.unlock(_controller.text);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = '主密码错误');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VaultShell(repository: widget.repository),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '解锁失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text('密码本', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text(
                  '输入主密码以解锁密码库',
                  style: TextStyle(color: CodebookColors.muted),
                ),
                const SizedBox(height: 34),
                const Icon(
                  Icons.lock_rounded,
                  size: 110,
                  color: CodebookColors.primary,
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  onSubmitted: (_) => _unlock(),
                  decoration: const InputDecoration(
                    labelText: '主密码',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: CodebookColors.danger)),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: '解锁',
                  onPressed: _unlock,
                  loading: _loading,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('指纹解锁将在 V0.2 启用'),
                  ),
                ),
                const Spacer(),
                const Text(
                  '🛡  离线优先 · 本地加密',
                  style: TextStyle(color: CodebookColors.muted),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
