import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/repository_service.dart';

class RepositoriesScreen extends StatefulWidget {
  const RepositoriesScreen({super.key});

  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> {
  List<SystemRepository> _repos = [];
  bool _loading = true;
  String? _error;
  PkgManager _pkgManager = PkgManager.unknown;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    setState(() { _loading = true; _error = null; });
    try {
      _pkgManager = await RepositoryService.detectPkgManager();
      final repos = await RepositoryService.loadRepositories();
      if (mounted) {
        setState(() { _repos = repos; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _toggleRepo(SystemRepository repo, bool enable) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await RepositoryService.toggleRepository(repo, enable);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable ? l10n.repoEnabled(repo.name) : l10n.repoDisabled(repo.name)),
          backgroundColor: enable ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadRepos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoError), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeRepo(SystemRepository repo) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.repoRemoveTitle),
        content: Text(l10n.repoRemoveConfirm(repo.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await RepositoryService.removeRepository(repo);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoRemoved(repo.name)), backgroundColor: Colors.green),
      );
      _loadRepos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoError), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editRepo(SystemRepository repo) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: repo.rawContent);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.repoEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.repoFilePathLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(repo.filePath, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.repoContentLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == null || result == repo.rawContent) return;

    final ok = await RepositoryService.editRepository(repo, result);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoUpdated), backgroundColor: Colors.green),
      );
      _loadRepos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoError), backgroundColor: Colors.red),
      );
    }
  }

  String _repoDisplayLine(SystemRepository repo) {
    if (repo.type == 'deb' || repo.type == 'deb-src') {
      return '${repo.type} ${repo.uri} ${repo.suite} ${repo.components}';
    }
    if (repo.type == 'repo') {
      return '${repo.name} → ${repo.uri}';
    }
    if (repo.type == 'server') {
      return '${repo.name} → ${repo.uri}';
    }
    return repo.uri;
  }

  Color _colorForPackageManager() {
    switch (_pkgManager) {
      case PkgManager.apt: return Colors.orange;
      case PkgManager.dnf: return Colors.blue;
      case PkgManager.pacman: return Colors.cyan;
      case PkgManager.unknown: return Colors.grey;
    }
  }

  String _pkgManagerLabel() {
    switch (_pkgManager) {
      case PkgManager.apt: return 'APT';
      case PkgManager.dnf: return 'DNF';
      case PkgManager.pacman: return 'Pacman';
      case PkgManager.unknown: return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadRepos,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2, color: _colorForPackageManager(), size: 20),
              const SizedBox(width: 8),
              Text(
                '${l10n.repoTitle} (${_pkgManagerLabel()})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${_repos.length} ${l10n.repoCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadRepos,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: l10n.refresh,
              ),
            ],
          ),
        ),
        // Repo list
        Expanded(
          child: _repos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l10n.repoEmpty, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _repos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final repo = _repos[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: repo.enabled
                              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Opacity(
                        opacity: repo.enabled ? 1.0 : 0.55,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: repo.enabled
                                      ? (repo.type == 'deb' || repo.type == 'deb-src'
                                          ? Colors.orange
                                          : repo.type == 'repo' ? Colors.blue : Colors.cyan)
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _repoDisplayLine(repo),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      repo.filePath,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: repo.enabled,
                                onChanged: (v) => _toggleRepo(repo, v),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              PopupMenuButton<String>(
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.edit),
                                    ],
                                  )),
                                  PopupMenuItem(value: 'remove', child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(l10n.remove, style: const TextStyle(color: Colors.red)),
                                    ],
                                  )),
                                ],
                                onSelected: (v) {
                                  if (v == 'edit') _editRepo(repo);
                                  if (v == 'remove') _removeRepo(repo);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
