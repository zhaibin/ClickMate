import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'click_config.dart';
import 'l10n/app_localizations.dart';

/// Configuration management dialog
class ConfigManagementDialog extends StatefulWidget {
  final Function(ClickConfig) onConfigLoaded;
  final String? currentConfigId;

  const ConfigManagementDialog({
    super.key,
    required this.onConfigLoaded,
    this.currentConfigId,
  });

  @override
  State<ConfigManagementDialog> createState() => _ConfigManagementDialogState();
}

class _ConfigManagementDialogState extends State<ConfigManagementDialog> {
  List<ClickConfig> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    
    try {
      final configs = ClickConfigService.instance.getAllConfigs();
      setState(() {
        _configs = configs;
        _isLoading = false;
      });
      print('Loaded ${_configs.length} configurations for display');
    } catch (e) {
      print('Error loading configurations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConfig(ClickConfig config) async {
    final l10n = AppLocalizations.of(context);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Text(l10n.configDeleteConfirm, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text('${l10n.configDeleteConfirmMsg}\n\n"${config.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.configDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClickConfigService.instance.deleteConfig(config.id);
        await _loadConfigs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.configDeleteSuccess),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error deleting config: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorOperationFailed}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _renameConfig(ClickConfig config) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: config.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(l10n.configRename, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.configNewName,
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
          ],
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != config.name) {
      try {
        await ClickConfigService.instance.renameConfig(config.id, newName);
        await _loadConfigs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.configRenameSuccess),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error renaming config: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorOperationFailed}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadConfig(ClickConfig config) async {
    final l10n = AppLocalizations.of(context);
    
    try {
      await ClickConfigService.instance.setLastUsedConfig(config.id);
      widget.onConfigLoaded(config);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${l10n.configLoadSuccess}: ${config.name}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error loading config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOperationFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getButtonName(int buttonValue) {
    switch (buttonValue) {
      case 0:
        return 'L';
      case 1:
        return 'R';
      case 2:
        return 'M';
      default:
        return '?';
    }
  }

  Color _getButtonColor(int buttonValue) {
    switch (buttonValue) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.folder_special, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(l10n.configManage, style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _configs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          l10n.configNoConfigs,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _configs.length,
                    itemBuilder: (context, index) {
                      final config = _configs[index];
                      final isSelected = config.id == widget.currentConfigId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 4 : 2,
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: InkWell(
                          onTap: () => _loadConfig(config),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: isSelected ? BoxDecoration(
                              border: Border.all(color: Colors.blue.shade300, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.bookmark : Icons.bookmark_border,
                                      size: 16,
                                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              config.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                l10n.configLoaded,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getButtonColor(config.mouseButton),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getButtonName(config.mouseButton),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _renameConfig(config),
                                      tooltip: l10n.configRename,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: Colors.red,
                                      onPressed: () => _deleteConfig(config),
                                      tooltip: l10n.configDelete,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${config.x}, ${config.y})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.timer,
                                        size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${config.interval}ms',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    if (config.randomInterval > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '±${config.randomInterval}ms',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                    if (config.offset > 0) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.open_in_full,
                                          size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '±${config.offset}px',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.configUpdatedAt}: ${_formatDateTime(config.updatedAt)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.btnCancel),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

