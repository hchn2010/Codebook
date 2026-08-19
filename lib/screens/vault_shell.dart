import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/vault_item.dart';
import '../repositories/vault_repository.dart';
import '../widgets/codebook_widgets.dart';
import 'auth_screens.dart';

class VaultShell extends StatefulWidget {
  const VaultShell({required this.repository, super.key});

  final VaultRepository repository;

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> with WidgetsBindingObserver {
  static const _autoLockAfter = Duration(seconds: 30);

  int _index = 0;
  List<VaultItem> _entries = const [];
  bool _loading = true;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= _autoLockAfter) {
        _lockNow();
      }
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final entries = await widget.repository.listItems();
      if (mounted) setState(() => _entries = entries);
    } on VaultLockedException {
      if (mounted) _lockNow();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _lockNow() {
    widget.repository.lock();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => UnlockScreen(repository: widget.repository),
      ),
      (_) => false,
    );
  }

  Future<void> _addEntry() async {
    final item = await Navigator.of(context).push<VaultItem>(
      MaterialPageRoute(builder: (_) => const EntryEditorPage()),
    );
    if (item == null) return;
    await widget.repository.addItem(item);
    await _reload();
  }

  Future<void> _openEntry(VaultItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(
          repository: widget.repository,
          initialItem: item,
        ),
      ),
    );
    if (changed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      VaultHome(
        entries: _entries,
        loading: _loading,
        onAdd: _addEntry,
        onOpen: _openEntry,
      ),
      CategoriesPage(entries: _entries),
      const GeneratorPage(),
      SettingsPage(onLockNow: _lockNow),
    ];

    return Scaffold(
      body: AppBackdrop(child: SafeArea(child: pages[_index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock_rounded),
            label: '密码库',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: '生成器',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class VaultHome extends StatefulWidget {
  const VaultHome({
    required this.entries,
    required this.loading,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  final List<VaultItem> entries;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<VaultItem> onOpen;

  @override
  State<VaultHome> createState() => _VaultHomeState();
}

class _VaultHomeState extends State<VaultHome> {
  String _query = '';
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    Iterable<VaultItem> visible = widget.entries;
    if (_filter == 1) visible = visible.where((item) => item.favorite);
    if (_filter == 2) visible = visible.take(10);
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      visible = visible.where(
        (item) => '${item.title} ${item.username} ${item.website} ${item.category}'
            .toLowerCase()
            .contains(q),
      );
    }
    final items = visible.toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '密码本',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const Chip(
                  avatar: Icon(
                    Icons.lock,
                    size: 16,
                    color: CodebookColors.success,
                  ),
                  label: Text('已解锁'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '搜索账号、网站、名称',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: _filter == 0,
                  onSelected: (_) => setState(() => _filter = 0),
                ),
                ChoiceChip(
                  label: const Text('收藏'),
                  selected: _filter == 1,
                  onSelected: (_) => setState(() => _filter = 1),
                ),
                ChoiceChip(
                  label: const Text('最近'),
                  selected: _filter == 2,
                  onSelected: (_) => setState(() => _filter = 2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('密码库', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (widget.loading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const GlassCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: 48,
                      color: CodebookColors.primary,
                    ),
                    SizedBox(height: 12),
                    Text('密码库还是空的'),
                    SizedBox(height: 6),
                    Text(
                      '点击右下角 + 添加第一个账号',
                      style: TextStyle(color: CodebookColors.muted),
                    ),
                  ],
                ),
              )
            else
              ...items.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => widget.onOpen(entry),
                    child: GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                CodebookColors.primary.withValues(alpha: .16),
                            child: Text(
                              entry.title.isEmpty ? '?' : entry.title.characters.first,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: CodebookColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        entry.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (entry.favorite) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  entry.username,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: CodebookColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: CodebookColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 22,
          bottom: 22,
          child: FloatingActionButton(
            onPressed: widget.onAdd,
            backgroundColor: CodebookColors.primary,
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ],
    );
  }
}

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({this.initialItem, super.key});

  final VaultItem? initialItem;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _website;
  late final TextEditingController _category;
  late final TextEditingController _notes;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _title = TextEditingController(text: item?.title ?? '');
    _username = TextEditingController(text: item?.username ?? '');
    _password = TextEditingController(text: item?.password ?? '');
    _website = TextEditingController(text: item?.website ?? '');
    _category = TextEditingController(text: item?.category ?? '个人');
    _notes = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _website.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _generatePassword() {
    _password.text = PasswordGenerator.generate(length: 20);
    setState(() {});
  }

  void _save() {
    if (_title.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名称和密码不能为空')),
      );
      return;
    }
    final now = DateTime.now();
    final old = widget.initialItem;
    Navigator.pop(
      context,
      VaultItem(
        id: old?.id,
        title: _title.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        website: _website.text.trim(),
        category: _category.text.trim().isEmpty ? '个人' : _category.text.trim(),
        notes: _notes.text.trim(),
        favorite: old?.favorite ?? false,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialItem != null;
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    editing ? '编辑账号' : '新增账号',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _username,
                decoration: const InputDecoration(labelText: '用户名'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: !_showPassword,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: '密码',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _generatePassword,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('生成强密码'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: '网站'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: '备注'),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Row(
                  children: [
                    const Text('密码强度'),
                    const Spacer(),
                    Text(
                      _strengthLabel(_password.text),
                      style: TextStyle(
                        color: _password.text.length >= 16
                            ? CodebookColors.success
                            : CodebookColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: '保存',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _strengthLabel(String value) {
    if (value.length >= 20) return '非常强';
    if (value.length >= 16) return '强';
    if (value.length >= 12) return '中等';
    return '较弱';
  }
}

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({
    required this.repository,
    required this.initialItem,
    super.key,
  });

  final VaultRepository repository;
  final VaultItem initialItem;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late VaultItem _item = widget.initialItem;
  bool _showPassword = false;
  bool _changed = false;

  Future<void> _copy(String value, {bool sensitive = false}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sensitive ? '密码已复制，30 秒后自动清除' : '已复制'),
      ),
    );
    if (sensitive) {
      Future<void>.delayed(const Duration(seconds: 30), () async {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }
  }

  Future<void> _edit() async {
    final edited = await Navigator.of(context).push<VaultItem>(
      MaterialPageRoute(
        builder: (_) => EntryEditorPage(initialItem: _item),
      ),
    );
    if (edited == null) return;
    _item = await widget.repository.updateItem(edited);
    if (mounted) {
      setState(() => _changed = true);
    }
  }

  Future<void> _toggleFavorite() async {
    _item = await widget.repository.updateItem(
      _item.copyWith(favorite: !_item.favorite),
    );
    if (mounted) setState(() => _changed = true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账号？'),
        content: const Text('删除后当前版本无法恢复，请确认。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || _item.id == null) return;
    await widget.repository.deleteItem(_item.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: AppBackdrop(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Spacer(),
                    Text('详情', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
                  ],
                ),
                const SizedBox(height: 22),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: Text(
                    _item.title.isEmpty ? '?' : _item.title.characters.first,
                    style: const TextStyle(
                      fontSize: 34,
                      color: CodebookColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Center(
                  child: Text(
                    _item.website.replaceFirst('https://', ''),
                    style: const TextStyle(color: CodebookColors.muted),
                  ),
                ),
                const SizedBox(height: 26),
                DetailRow(
                  label: '用户名',
                  value: _item.username,
                  onCopy: () => _copy(_item.username),
                ),
                DetailRow(
                  label: '密码',
                  value: _showPassword ? _item.password : '••••••••••••••',
                  leadingAction: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  onCopy: () => _copy(_item.password, sensitive: true),
                ),
                DetailRow(
                  label: '网站',
                  value: _item.website.isEmpty ? '未填写' : _item.website,
                  onCopy: _item.website.isEmpty ? null : () => _copy(_item.website),
                ),
                DetailRow(label: '分类', value: _item.category),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('备注', style: TextStyle(color: CodebookColors.muted)),
                      const SizedBox(height: 12),
                      Text(_item.notes.isEmpty ? '无备注' : _item.notes),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '最后修改 ${_formatDate(_item.updatedAt)}',
                    style: const TextStyle(color: CodebookColors.muted),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _item.favorite ? Icons.star : Icons.star_border,
                        ),
                        label: Text(_item.favorite ? '已收藏' : '收藏'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: CodebookColors.danger,
                        ),
                        label: const Text(
                          '删除',
                          style: TextStyle(color: CodebookColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.leadingAction,
    this.onCopy,
    super.key,
  });

  final String label;
  final String value;
  final Widget? leadingAction;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: const TextStyle(color: CodebookColors.muted)),
            ),
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
            if (leadingAction != null) leadingAction!,
            if (onCopy != null)
              IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded)),
          ],
        ),
      ),
    );
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({required this.entries, super.key});

  final List<VaultItem> entries;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final item in entries) {
      counts.update(item.category, (value) => value + 1, ifAbsent: () => 1);
    }
    final categories = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('分类', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 22),
        if (categories.isEmpty)
          const GlassCard(
            child: Text(
              '添加账号后，这里会自动按分类汇总。',
              style: TextStyle(color: CodebookColors.muted),
            ),
          )
        else
          ...categories.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, color: CodebookColors.primary),
                    const SizedBox(width: 14),
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(color: CodebookColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  double _length = 20;
  bool _upper = true;
  bool _lower = true;
  bool _numbers = true;
  bool _symbols = true;
  bool _excludeAmbiguous = true;
  late String _password = _generate();

  String _generate() => PasswordGenerator.generate(
        length: _length.round(),
        upper: _upper,
        lower: _lower,
        numbers: _numbers,
        symbols: _symbols,
        excludeAmbiguous: _excludeAmbiguous,
      );

  void _refresh() => setState(() => _password = _generate());

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密码已复制，30 秒后自动清除')),
    );
    final copied = _password;
    Future<void>.delayed(const Duration(seconds: 30), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == copied) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
      children: [
        Text('密码生成器', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 22),
        GlassCard(
          child: Column(
            children: [
              SelectableText(
                _password,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CodebookColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新生成'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text('密码长度'),
            const Spacer(),
            Text('${_length.round()}'),
          ],
        ),
        Slider(
          value: _length,
          min: 12,
          max: 40,
          divisions: 28,
          onChanged: (value) {
            setState(() {
              _length = value;
              _password = _generate();
            });
          },
        ),
        GlassCard(
          child: Column(
            children: [
              _switch('大写字母 A-Z', _upper, (v) => _setOption(() => _upper = v)),
              _switch('小写字母 a-z', _lower, (v) => _setOption(() => _lower = v)),
              _switch('数字 0-9', _numbers, (v) => _setOption(() => _numbers = v)),
              _switch('特殊字符 !@#%', _symbols, (v) => _setOption(() => _symbols = v)),
              _switch(
                '排除易混淆字符',
                _excludeAmbiguous,
                (v) => _setOption(() => _excludeAmbiguous = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const GlassCard(
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: CodebookColors.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '密码生成使用系统安全随机数 Random.secure()。',
                  style: TextStyle(color: CodebookColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  void _setOption(VoidCallback update) {
    setState(() {
      update();
      if (!_upper && !_lower && !_numbers && !_symbols) _lower = true;
      _password = _generate();
    });
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.onLockNow, super.key});

  final VoidCallback onLockNow;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('设置', style: Theme.of(context).textTheme.headlineLarge),
            ),
            const Chip(
              avatar: Icon(Icons.lock, size: 16, color: CodebookColors.success),
              label: Text('已解锁'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const GlassCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.timer_outlined, color: CodebookColors.primary),
                title: Text('自动锁定'),
                subtitle: Text('进入后台 30 秒后重新要求主密码'),
                trailing: Text('30 秒'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.content_paste, color: CodebookColors.primary),
                title: Text('剪贴板自动清除'),
                subtitle: Text('复制密码 30 秒后清除'),
                trailing: Text('30 秒'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fingerprint, color: CodebookColors.muted),
                title: Text('生物识别解锁'),
                subtitle: Text('V0.2：接入 Android Keystore / BiometricPrompt'),
                trailing: Text('待接入'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.shield_outlined, color: CodebookColors.muted),
                title: Text('截图保护'),
                subtitle: Text('V0.2：接入 Android FLAG_SECURE'),
                trailing: Text('待接入'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const GlassCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.key_outlined, color: CodebookColors.primary),
                title: Text('主密码派生'),
                subtitle: Text('Argon2id · 19 MiB · 2 iterations · 256-bit'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.enhanced_encryption_outlined, color: CodebookColors.primary),
                title: Text('密码库加密'),
                subtitle: Text('AES-256-GCM · 每条记录独立随机 Nonce'),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.storage_outlined, color: CodebookColors.primary),
                title: Text('本地存储'),
                subtitle: Text('SQLite 仅保存加密 Payload 与非敏感时间戳'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: onLockNow,
            icon: const Icon(Icons.lock_outline),
            label: const Text('立即锁定密码库'),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '离线优先 · 本地加密 · V0.1',
            style: TextStyle(color: CodebookColors.muted),
          ),
        ),
      ],
    );
  }
}

abstract final class PasswordGenerator {
  static const _upperChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _lowerChars = 'abcdefghijkmnopqrstuvwxyz';
  static const _numberChars = '23456789';
  static const _symbolChars = '!@#%&*+-_?';

  static String generate({
    int length = 20,
    bool upper = true,
    bool lower = true,
    bool numbers = true,
    bool symbols = true,
    bool excludeAmbiguous = true,
  }) {
    var pool = '';
    if (upper) pool += excludeAmbiguous ? _upperChars : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (lower) pool += excludeAmbiguous ? _lowerChars : 'abcdefghijklmnopqrstuvwxyz';
    if (numbers) pool += excludeAmbiguous ? _numberChars : '0123456789';
    if (symbols) pool += _symbolChars;
    if (pool.isEmpty) pool = _lowerChars;

    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => pool[random.nextInt(pool.length)],
    ).join();
  }
}
