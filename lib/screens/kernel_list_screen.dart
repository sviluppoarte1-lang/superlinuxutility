import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/kernel_info.dart';
import '../services/kernel_service.dart';

class KernelListScreen extends StatefulWidget {
  const KernelListScreen({super.key});

  @override
  State<KernelListScreen> createState() => _KernelListScreenState();
}

class _KernelListScreenState extends State<KernelListScreen> {
  List<KernelInfo> _kernels = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _maxKernelsController = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    _loadKernels();
  }

  @override
  void dispose() {
    _maxKernelsController.dispose();
    super.dispose();
  }

  Future<void> _loadKernels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final kernels = await KernelService.getInstalledKernels();
      setState(() {
        _kernels = kernels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeKernel(KernelInfo kernel) async {
    if (kernel.isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.kernelCannotRemoveActive),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.removeKernel),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.removeKernelQuestion(kernel.version),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.thisOperation),
            Text(AppLocalizations.of(context)!.willRemovePackage),
            Text(AppLocalizations.of(context)!.willUpdateGrub),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.kernelWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.remove,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await KernelService.removeKernel(kernel.packageName);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelRemovedSuccess(kernel.version)),
              backgroundColor: Colors.green,
            ),
          );
          _loadKernels();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelRemoveError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultKernel(KernelInfo kernel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.setDefaultKernel),
        content: Text(
          AppLocalizations.of(context)!.setDefaultKernelQuestion(kernel.version),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.set,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await KernelService.setDefaultKernel(kernel.version);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelSetDefaultSuccess(kernel.version)),
              backgroundColor: Colors.green,
            ),
          );
          _loadKernels();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelSetDefaultError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _updateGrub() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.update, color: Colors.blue),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.updateGrub),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.updateGrubQuestion,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.updateGrub,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await KernelService.updateGrub();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.grubUpdateSuccess),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.grubUpdateError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rebootSystem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.power_settings_new, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.rebootSystem),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.rebootSystemQuestion,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.rebootSystem,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await KernelService.rebootSystem();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.rebootSystemSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.rebootSystemError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanupOldKernels() async {
    final maxKernels = int.tryParse(_maxKernelsController.text);
    if (maxKernels == null || maxKernels < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidKernelCount),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.cleanupKernels),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.keepOnlyRecentKernels(maxKernels),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.totalKernels(_kernels.length)),
            Text(AppLocalizations.of(context)!.kernelsToKeep(maxKernels)),
            Text(AppLocalizations.of(context)!.kernelsToRemove(_kernels.length - maxKernels)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.cleanupKernelsWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.cleanup,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await KernelService.keepOnlyRecentKernels(maxKernels);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelCleanupSuccess),
              backgroundColor: Colors.green,
            ),
          );
          _loadKernels();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.kernelCleanupError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadKernels,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.refresh),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateGrub,
                      icon: const Icon(Icons.update),
                      label: Text(AppLocalizations.of(context)!.updateGrub),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _rebootSystem,
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(AppLocalizations.of(context)!.rebootSystem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Impostazione max kernel
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.keepMax),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _maxKernelsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _cleanupOldKernels,
                          icon: const Icon(Icons.delete_sweep),
                          label: Text(AppLocalizations.of(context)!.cleanup),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Errore
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Lista kernel
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kernels.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context)!.noKernelsFound),
                      )
                    : ListView.builder(
                        itemCount: _kernels.length,
                        itemBuilder: (context, index) {
                          final kernel = _kernels[index];
                          return _buildKernelCard(kernel);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKernelCard(KernelInfo kernel) {
    final theme = Theme.of(context);
    Color? cardColor;
    Color iconColor;
    Color? titleColor;
    
    if (kernel.isActive) {
      cardColor = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.primary;
      titleColor = theme.colorScheme.onPrimaryContainer;
    } else if (kernel.isDefault) {
      cardColor = theme.colorScheme.secondaryContainer;
      iconColor = theme.colorScheme.secondary;
      titleColor = theme.colorScheme.onSecondaryContainer;
    } else {
      cardColor = null;
      iconColor = theme.iconTheme.color ?? theme.colorScheme.onSurface;
      titleColor = null;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: ListTile(
        leading: Icon(
          kernel.isActive
              ? Icons.play_circle
              : kernel.isDefault
                  ? Icons.star
                  : Icons.circle_outlined,
          color: iconColor,
        ),
        title: Text(
          kernel.version,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context)!.package}: ${kernel.packageName}'),
            if (kernel.size != null)
              Text('${AppLocalizations.of(context)!.size}: ${KernelService.formatSize(kernel.size)}'),
            Row(
              children: [
                if (kernel.isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'In Uso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (kernel.isDefault)
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!kernel.isDefault)
              PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.setAsDefault),
                  ],
                ),
              ),
            if (!kernel.isActive)
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.remove,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'set_default') {
              _setDefaultKernel(kernel);
            } else if (value == 'remove') {
              _removeKernel(kernel);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }
}

