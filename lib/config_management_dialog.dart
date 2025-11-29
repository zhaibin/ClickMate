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
    const primaryColor = Color(0xFF1E3A5F);
    const accentColor = Color(0xFF3B82F6);

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_outlined, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.configManage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            SizedBox(
              height: 350,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : _configs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                l10n.configNoConfigs,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _configs.length,
                          itemBuilder: (context, index) {
                            final config = _configs[index];
                            final isSelected = config.id == widget.currentConfigId;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.06) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? primaryColor.withOpacity(0.3) : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _loadConfig(config),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.bookmark : Icons.bookmark_outline,
                                            size: 16,
                                            color: isSelected ? primaryColor : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              config.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected ? primaryColor : Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                l10n.configLoaded,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getButtonColor(config.mouseButton).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getButtonName(config.mouseButton),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getButtonColor(config.mouseButton),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade500),
                                            onPressed: () => _renameConfig(config),
                                            tooltip: l10n.configRename,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                                            onPressed: () => _deleteConfig(config),
                                            tooltip: l10n.configDelete,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildConfigBadge(Icons.location_on_outlined, '(${config.x}, ${config.y})'),
                                          const SizedBox(width: 8),
                                          _buildConfigBadge(Icons.timer_outlined, '${config.interval}ms'),
                                          if (config.randomInterval > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '±${config.randomInterval}',
                                              style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
                                            ),
                                          ],
                                          if (config.offset > 0) ...[
                                            const SizedBox(width: 8),
                                            _buildConfigBadge(Icons.open_in_full, '±${config.offset}px'),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${l10n.configUpdatedAt}: ${_formatDateTime(config.updatedAt)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.btnCancel, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfigBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

