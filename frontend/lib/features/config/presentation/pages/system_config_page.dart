import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/system_config_entity.dart';
import '../bloc/config_bloc.dart';
import '../bloc/config_event.dart';
import '../bloc/config_state.dart';

class SystemConfigPage extends StatelessWidget {
  const SystemConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConfigBloc>()..add(LoadConfig()),
      child: const _SystemConfigView(),
    );
  }
}

class _SystemConfigView extends StatelessWidget {
  const _SystemConfigView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
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
                        Text('Configuration', style: AppTextStyles.pageTitle()),
                        const SizedBox(height: 4),
                        Text('Manage system settings and point rules',
                            style: AppTextStyles.body(
                                color: Colors.grey.shade500)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          context.read<ConfigBloc>().add(LoadConfig()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!state.isLoading) ...[
                  // System Configuration Section
                  _buildSectionHeader('System Configuration',
                      'Global settings and parameters', Icons.settings_rounded),
                  const SizedBox(height: 12),
                  if (state.configs.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: state.configs
                            .map((c) => _buildConfigTile(context, c, theme))
                            .toList(),
                      ),
                    ),
                  if (state.configs.isEmpty)
                    _buildEmptyState(
                        Icons.settings_outlined, 'No configuration entries'),
                  const SizedBox(height: 32),

                  // Point Rules & Eligibility Section
                  _buildSectionHeader('Point Rules & Eligibility',
                      'Define point values for different actions',
                      Icons.rule_rounded),
                  const SizedBox(height: 12),
                  if (state.rules.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: state.rules
                            .map((r) => _buildRuleTile(r, theme))
                            .toList(),
                      ),
                    ),
                  if (state.rules.isEmpty)
                    _buildEmptyState(
                        Icons.rule_rounded, 'No point rules configured'),
                ],
              ],
            ),
          ),
        );
      },
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
            Text(title, style: AppTextStyles.label()),
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

  Widget _buildRuleTile(dynamic rule, ThemeData theme) {
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
                Text(rule.name, style: AppTextStyles.cardTitle()),
                if (rule.description != null && rule.description!.isNotEmpty)
                  Text(rule.description!,
                      style: AppTextStyles.small(color: Colors.grey.shade500)),
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
            child: Text('${rule.points}', style: AppTextStyles.cardTitle()),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile(
      BuildContext context, SystemConfigEntity config, ThemeData theme) {
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
                Text(config.key, style: AppTextStyles.cardTitle()),
                if (config.description != null &&
                    config.description!.isNotEmpty)
                  Text(config.description!,
                      style: AppTextStyles.small(color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(config.value, style: AppTextStyles.bodyBold()),
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

  void _showEditDialog(BuildContext context, SystemConfigEntity config) {
    final controller = TextEditingController(text: config.value);
    final bloc = context.read<ConfigBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Edit: ${config.key}',
        maxWidth: 420,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(config.description!,
                    style: AppTextStyles.body(color: Colors.grey.shade600)),
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
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(UpdateConfigEntry(
                  key: config.key, value: controller.text));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
