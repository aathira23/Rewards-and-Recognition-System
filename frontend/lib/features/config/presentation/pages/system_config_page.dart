import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _rules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final client = sl<ApiClient>();
      // Load configs and rules in parallel
      final results = await Future.wait([
        client.get(ApiConstants.systemConfig),
        client.get('${ApiConstants.pointsRules}'),
      ]);

      final configData = results[0].data['data'] ?? [];
      final rulesData = results[1].data['data'] ?? results[1].data ?? [];

      setState(() {
        _configs = (configData is List)
            ? configData.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        _rules = (rulesData is List)
            ? rulesData.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configuration',
                        style: AppTextStyles.pageTitle()),
                    const SizedBox(height: 4),
                    Text('Manage system settings and point rules',
                        style: AppTextStyles.body(
                            color: Colors.grey.shade500)),
                  ],
                ),
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _loadAll),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator())),
            if (_error != null)
              Center(
                  child: Text('Error: $_error',
                      style: TextStyle(color: Colors.red.shade700))),
            if (!_isLoading && _error == null) ...[
              // ── System Configuration Section ──
              _buildSectionHeader('System Configuration',
                  'Global settings and parameters', Icons.settings_rounded),
              const SizedBox(height: 12),
              if (_configs.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: _configs.map((config) {
                      return _buildConfigTile(context, config, theme);
                    }).toList(),
                  ),
                ),
              if (_configs.isEmpty)
                _buildEmptyState(
                    Icons.settings_outlined, 'No configuration entries'),
              const SizedBox(height: 32),

              // ── Point Rules & Eligibility Section ──
              _buildSectionHeader(
                  'Point Rules & Eligibility',
                  'Define point values for different actions',
                  Icons.rule_rounded),
              const SizedBox(height: 12),
              if (_rules.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: _rules.map((rule) {
                      return _buildRuleTile(rule, theme);
                    }).toList(),
                  ),
                ),
              if (_rules.isEmpty)
                _buildEmptyState(
                    Icons.rule_rounded, 'No point rules configured'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.label()),
            Text(subtitle,
                style: AppTextStyles.caption(color: Colors.grey.shade400)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile(Map<String, dynamic> rule, ThemeData theme) {
    final name = rule['rule_name'] ?? rule['name'] ?? '';
    final description = rule['description'] ?? '';
    final points = rule['points_value'] ?? rule['points'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toString(),
                    style: AppTextStyles.cardTitle()),
                if (description.toString().isNotEmpty)
                  Text(description.toString(),
                      style: AppTextStyles.small(
                          color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text('$points',
                style: AppTextStyles.cardTitle()),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile(
      BuildContext context, Map<String, dynamic> config, ThemeData theme) {
    final key = config['key'] ?? '';
    final value = config['value'] ?? '';
    final description = config['description'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune_rounded,
                color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key,
                    style: AppTextStyles.cardTitle()),
                if (description.toString().isNotEmpty)
                  Text(description,
                      style: AppTextStyles.small(
                          color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value.toString(),
                style: AppTextStyles.bodyBold()),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
            onPressed: () => _showEditDialog(context, config),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> config) {
    final controller =
        TextEditingController(text: config['value']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Edit: ${config['key']}',
        maxWidth: 420,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config['description'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(config['description'],
                    style: AppTextStyles.body(
                        color: Colors.grey.shade600)),
              ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final client = sl<ApiClient>();
                await client.patch(
                    '${ApiConstants.systemConfig}${config['key']}',
                    data: {'value': controller.text});
                _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
