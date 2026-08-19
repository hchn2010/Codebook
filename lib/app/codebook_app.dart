import 'dart:math';

import 'package:flutter/material.dart';

import 'theme.dart';

class CodebookApp extends StatelessWidget {
  const CodebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '密码本',
      debugShowCheckedModeBanner: false,
      theme: buildCodebookTheme(),
      home: const SetupScreen(),
    );
  }
}

class VaultEntry {
  const VaultEntry({
    required this.title,
    required this.username,
    required this.password,
    required this.website,
    required this.category,
    this.notes = '',
    this.favorite = false,
  });

  final String title;
  final String username;
  final String password;
  final String website;
  final String category;
  final String notes;
  final bool favorite;
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF030711), Color(0xFF091121), Color(0xFF111546)],
          stops: [0, .62, 1],
        ),
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding = const EdgeInsets.all(18), super.key});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CodebookColors.surface.withOpacity(.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.label, required this.onPressed, this.icon, super.key});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.lock_outline_rounded),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: CodebookColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _hint = TextEditingController();
  bool biometrics = true;
  bool screenshots = true;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _hint.dispose();
    super.dispose();
  }

  void createVault() {
    if (_password.text.length < 8) {
      setState(() => error = '主密码至少需要 8 位');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => error = '两次输入的主密码不一致');
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UnlockScreen()));
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
              const Text('主密码用于解锁你的密码库，请务必牢记', style: TextStyle(color: CodebookColors.muted, fontSize: 15)),
              const SizedBox(height: 28),
              const Center(child: Icon(Icons.lock_rounded, size: 94, color: CodebookColors.primary)),
              const SizedBox(height: 30),
              TextField(controller: _password, obscureText: obscure, decoration: InputDecoration(labelText: '输入主密码', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
              const SizedBox(height: 14),
              TextField(controller: _confirm, obscureText: obscure, decoration: const InputDecoration(labelText: '再次输入主密码', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 14),
              TextField(controller: _hint, decoration: const InputDecoration(labelText: '密码提示（可选）', prefixIcon: Icon(Icons.chat_bubble_outline_rounded))),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: CodebookColors.danger)),
              ],
              const SizedBox(height: 18),
              GlassCard(child: Column(children: [
                SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.fingerprint, color: CodebookColors.primary), title: const Text('开启指纹解锁'), value: biometrics, onChanged: (v) => setState(() => biometrics = v)),
                Divider(color: Colors.white.withOpacity(.08)),
                SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.shield_outlined, color: CodebookColors.primary), title: const Text('禁止截图'), value: screenshots, onChanged: (v) => setState(() => screenshots = v)),
              ])),
              const SizedBox(height: 16),
              const GlassCard(child: Row(children: [Icon(Icons.info_outline, color: CodebookColors.primary), SizedBox(width: 12), Expanded(child: Text('主密码不会上传服务器，也无法找回', style: TextStyle(color: CodebookColors.muted)))])),
              const SizedBox(height: 20),
              PrimaryButton(label: '创建密码库', onPressed: createVault),
            ],
          ),
        ),
      ),
    );
  }
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
                const Text('输入主密码以解锁密码库', style: TextStyle(color: CodebookColors.muted)),
                const SizedBox(height: 34),
                const Icon(Icons.lock_rounded, size: 110, color: CodebookColors.primary),
                const SizedBox(height: 36),
                TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: '主密码', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 16),
                PrimaryButton(label: '解锁', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VaultShell()))),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, height: 56, child: OutlinedButton.icon(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VaultShell())), icon: const Icon(Icons.fingerprint), label: const Text('使用指纹解锁'))),
                const Spacer(),
                const Text('🛡  离线优先 · 本地加密', style: TextStyle(color: CodebookColors.muted)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VaultShell extends StatefulWidget {
  const VaultShell({super.key});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int index = 0;
  final entries = <VaultEntry>[
    const VaultEntry(title: 'Google', username: 'abc@gmail.com', password: 'A9#demoPassword!', website: 'https://google.com', category: '个人', notes: '这是我的主要 Google 账号'),
    const VaultEntry(title: 'ChatGPT', username: 'abc@gmail.com', password: 'demoOnly123!', website: 'https://chatgpt.com', category: '工作'),
    const VaultEntry(title: 'Binance', username: 'myname@gmail.com', password: 'demoOnly456!', website: 'https://binance.com', category: '金融'),
    const VaultEntry(title: '微信', username: '138****8888', password: 'demoOnly789!', website: '', category: '个人'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      VaultHome(entries: entries, onAdd: _addEntry),
      const CategoriesPage(),
      const GeneratorPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: AppBackdrop(child: SafeArea(child: pages[index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock_outline), selectedIcon: Icon(Icons.lock_rounded), label: '密码库'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: '分类'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: '生成器'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  Future<void> _addEntry() async {
    final result = await Navigator.of(context).push<VaultEntry>(MaterialPageRoute(builder: (_) => const EntryEditorPage()));
    if (result != null) setState(() => entries.insert(0, result));
  }
}

class VaultHome extends StatefulWidget {
  const VaultHome({required this.entries, required this.onAdd, super.key});
  final List<VaultEntry> entries;
  final VoidCallback onAdd;

  @override
  State<VaultHome> createState() => _VaultHomeState();
}

class _VaultHomeState extends State<VaultHome> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.entries.where((e) => '${e.title} ${e.username} ${e.website}'.toLowerCase().contains(query.toLowerCase())).toList();
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
        children: [
          Row(children: [Expanded(child: Text('密码本', style: Theme.of(context).textTheme.headlineLarge)), const Chip(avatar: Icon(Icons.lock, size: 16, color: CodebookColors.success), label: Text('已解锁'))]),
          const SizedBox(height: 22),
          TextField(onChanged: (value) => setState(() => query = value), decoration: const InputDecoration(hintText: '搜索账号、网站、名称', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 18),
          const Row(children: [FilterChip(label: Text('全部'), selected: true, onSelected: null), SizedBox(width: 10), FilterChip(label: Text('收藏'), selected: false, onSelected: null), SizedBox(width: 10), FilterChip(label: Text('最近'), selected: false, onSelected: null)]),
          const SizedBox(height: 24),
          Text('最近使用', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ...visible.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EntryDetailPage(entry: entry))),
              child: GlassCard(child: Row(children: [
                CircleAvatar(radius: 25, backgroundColor: CodebookColors.primary.withOpacity(.16), child: Text(entry.title.characters.first, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CodebookColors.primary))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(entry.username, style: const TextStyle(color: CodebookColors.muted))])),
                const Icon(Icons.chevron_right_rounded, color: CodebookColors.muted),
              ])),
            ),
          )),
        ],
      ),
      Positioned(right: 22, bottom: 22, child: FloatingActionButton(onPressed: widget.onAdd, backgroundColor: CodebookColors.primary, child: const Icon(Icons.add, size: 30))),
    ]);
  }
}

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({required this.entry, super.key});
  final VaultEntry entry;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  bool show = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(22), children: [
            Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new)), const Spacer(), Text('详情', style: Theme.of(context).textTheme.titleLarge), const Spacer(), IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined))]),
            const SizedBox(height: 24),
            CircleAvatar(radius: 44, backgroundColor: Colors.white, child: Text(e.title.characters.first, style: const TextStyle(fontSize: 34, color: CodebookColors.primary, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            Center(child: Text(e.title, style: Theme.of(context).textTheme.headlineMedium)),
            Center(child: Text(e.website.replaceAll('https://', ''), style: const TextStyle(color: CodebookColors.muted))),
            const SizedBox(height: 26),
            _DetailRow(label: '用户名', value: e.username, action: '复制'),
            _DetailRow(label: '密码', value: show ? e.password : '••••••••••••••', action: '复制', trailing: IconButton(onPressed: () => setState(() => show = !show), icon: Icon(show ? Icons.visibility_off : Icons.visibility))),
            _DetailRow(label: '网站', value: e.website, action: '复制'),
            _DetailRow(label: '分类', value: e.category),
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('备注', style: TextStyle(color: CodebookColors.muted)), const SizedBox(height: 12), Text(e.notes.isEmpty ? '无备注' : e.notes)])),
            const SizedBox(height: 20),
            const Center(child: Text('最后修改 2026-08-19', style: TextStyle(color: CodebookColors.muted))),
            const SizedBox(height: 24),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.star_border), label: const Text('收藏'))), const SizedBox(width: 12), Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.delete_outline, color: CodebookColors.danger), label: const Text('删除', style: TextStyle(color: CodebookColors.danger))))]),
          ]),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.action, this.trailing});
  final String label;
  final String value;
  final String? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(child: Row(children: [SizedBox(width: 72, child: Text(label, style: const TextStyle(color: CodebookColors.muted))), Expanded(child: Text(value, overflow: TextOverflow.ellipsis)), if (trailing != null) trailing!, if (action != null) TextButton.icon(onPressed: () {}, icon: const Icon(Icons.copy_rounded, size: 18), label: Text(action!))])),
    );
  }
}

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({super.key});

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final title = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final website = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    title.dispose(); username.dispose(); password.dispose(); website.dispose(); notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(child: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: [
        Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new)), const SizedBox(width: 6), Text('新增账号', style: Theme.of(context).textTheme.headlineMedium)]),
        const SizedBox(height: 22),
        TextField(controller: title, decoration: const InputDecoration(labelText: '名称', hintText: '例如 Google')),
        const SizedBox(height: 12),
        TextField(controller: username, decoration: const InputDecoration(labelText: '用户名')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: '密码', suffixIcon: TextButton(onPressed: () => setState(() => password.text = _generatePassword()), child: const Text('生成强密码')))),
        const SizedBox(height: 12),
        TextField(controller: website, decoration: const InputDecoration(labelText: '网站', hintText: 'https://')),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: '分类', hintText: '个人')),
        const SizedBox(height: 12),
        TextField(controller: notes, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: '备注', hintText: '可选，添加备注信息…')),
        const SizedBox(height: 18),
        const GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('密码强度：强', style: TextStyle(color: CodebookColors.success)), SizedBox(height: 10), LinearProgressIndicator(value: .82)])),
        const SizedBox(height: 20),
        PrimaryButton(label: '保存', icon: Icons.save_outlined, onPressed: () {
          if (title.text.trim().isEmpty) return;
          Navigator.pop(context, VaultEntry(title: title.text.trim(), username: username.text.trim(), password: password.text, website: website.text.trim(), category: '个人', notes: notes.text.trim()));
        }),
      ]))),
    );
  }
}

String _generatePassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*';
  final random = Random.secure();
  return List.generate(18, (_) => chars[random.nextInt(chars.length)]).join();
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [('⭐', '收藏', '0'), ('🌐', '网站', '3'), ('💼', '工作', '1'), ('👤', '个人', '2'), ('💰', '金融', '1'), ('🛒', '购物', '0')];
    return ListView(padding: const EdgeInsets.all(22), children: [Text('分类', style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 20), ...items.map((i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(child: Row(children: [Text(i.$1, style: const TextStyle(fontSize: 24)), const SizedBox(width: 14), Expanded(child: Text(i.$2, style: const TextStyle(fontWeight: FontWeight.w700))), Text(i.$3, style: const TextStyle(color: CodebookColors.muted)), const SizedBox(width: 8), const Icon(Icons.chevron_right, color: CodebookColors.muted)]))))]);
  }
}

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  double length = 18;
  bool upper = true, lower = true, numbers = true, symbols = true, exclude = true;
  late String generated = _build();

  String _build() {
    var chars = '';
    if (upper) chars += 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    if (lower) chars += 'abcdefghijkmnopqrstuvwxyz';
    if (numbers) chars += '23456789';
    if (symbols) chars += '!@#%&*';
    if (chars.isEmpty) chars = 'abcdefghijkmnopqrstuvwxyz';
    final r = Random.secure();
    return List.generate(length.round(), (_) => chars[r.nextInt(chars.length)]).join();
  }

  void refresh() => setState(() => generated = _build());

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      Text('密码生成器', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 20),
      GlassCard(child: Column(children: [SelectableText(generated, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: CodebookColors.primary)), const SizedBox(height: 18), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.copy), label: const Text('复制'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('重新生成')))])])),
      const SizedBox(height: 18),
      Row(children: [const Text('密码长度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const Spacer(), Text('${length.round()}')]),
      Slider(value: length, min: 8, max: 32, divisions: 24, onChanged: (v) => setState(() { length = v; generated = _build(); })),
      GlassCard(child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('大写字母'), subtitle: const Text('A-Z'), value: upper, onChanged: (v) => setState(() { upper = v; generated = _build(); })),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('小写字母'), subtitle: const Text('a-z'), value: lower, onChanged: (v) => setState(() { lower = v; generated = _build(); })),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('数字'), subtitle: const Text('0-9'), value: numbers, onChanged: (v) => setState(() { numbers = v; generated = _build(); })),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('特殊字符'), subtitle: const Text('!@#%&*'), value: symbols, onChanged: (v) => setState(() { symbols = v; generated = _build(); })),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('排除易混淆字符'), value: exclude, onChanged: (v) => setState(() => exclude = v)),
      ])),
      const SizedBox(height: 16),
      const GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('密码强度：非常强', style: TextStyle(color: CodebookColors.success, fontWeight: FontWeight.w700)), SizedBox(height: 10), LinearProgressIndicator(value: 1), SizedBox(height: 10), Text('建议每个账号使用独立密码。', style: TextStyle(color: CodebookColors.muted))])),
    ]);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool bio = true;
  bool screenshots = true;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      Row(children: [Expanded(child: Text('设置', style: Theme.of(context).textTheme.headlineLarge)), const Chip(avatar: Icon(Icons.lock, size: 16, color: CodebookColors.success), label: Text('已解锁'))]),
      const SizedBox(height: 20),
      GlassCard(child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.fingerprint, color: CodebookColors.primary), title: const Text('生物识别解锁'), subtitle: const Text('使用指纹或面部识别解锁应用'), value: bio, onChanged: (v) => setState(() => bio = v)),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.timer_outlined, color: CodebookColors.primary), title: Text('自动锁定'), subtitle: Text('应用在无操作后自动锁定'), trailing: Text('30 秒  ›')),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.content_paste_outlined, color: CodebookColors.primary), title: Text('剪贴板自动清除'), subtitle: Text('复制的密码在设定时间后自动清除'), trailing: Text('30 秒  ›')),
        SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.shield_outlined, color: CodebookColors.primary), title: const Text('截图保护'), subtitle: const Text('防止应用内容在截图中泄露'), value: screenshots, onChanged: (v) => setState(() => screenshots = v)),
      ])),
      const SizedBox(height: 14),
      const GlassCard(child: Column(children: [
        ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.key_rounded, color: CodebookColors.primary), title: Text('修改主密码'), trailing: Icon(Icons.chevron_right)),
        ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.cloud_upload_outlined, color: CodebookColors.primary), title: Text('导出加密备份'), trailing: Icon(Icons.chevron_right)),
        ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.cloud_download_outlined, color: CodebookColors.primary), title: Text('导入备份'), trailing: Icon(Icons.chevron_right)),
        ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.info_outline, color: CodebookColors.primary), title: Text('关于密码本'), trailing: Icon(Icons.chevron_right)),
      ])),
      const SizedBox(height: 16),
      const Center(child: Text('🛡  离线优先 · 本地加密 · V0.1', style: TextStyle(color: CodebookColors.muted))),
    ]);
  }
}
