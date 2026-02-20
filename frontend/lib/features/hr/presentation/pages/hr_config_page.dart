import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';
import '../bloc/hr_config_bloc.dart';
import '../bloc/hr_config_event.dart';
import '../bloc/hr_config_state.dart';

/// HR Configuration page — manages Award Types, Rewards Catalog,
/// Points Policy, and System Settings in a single tabbed view.
class HrConfigPage extends StatelessWidget {
  const HrConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HrConfigBloc>()..add(LoadAllHrConfig()),
      child: const _HrConfigView(),
    );
  }
}

class _HrConfigView extends StatefulWidget {
  const _HrConfigView();

  @override
  State<_HrConfigView> createState() => _HrConfigViewState();
}

class _HrConfigViewState extends State<_HrConfigView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<HrConfigBloc, HrConfigState>(
      listener: (context, state) {
        if (state.error != null) {
          _snack(state.error!, isError: true);
        }
        if (state.successMessage != null) {
          _snack(state.successMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainer,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.pagePadding(context),
                  Responsive.pagePadding(context),
                  Responsive.pagePadding(context),
                  0,
                ),
                child: AppPageHeader(
                  title: 'Configuration',
                  subtitle:
                      'Manage awards, badges, catalog, point rules & system settings',
                  action: _RefreshBtn(
                    onTap: () =>
                        context.read<HrConfigBloc>().add(LoadAllHrConfig()),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tab bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.pagePadding(context),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: Responsive.isMobile(context),
                    tabAlignment: Responsive.isMobile(context)
                        ? TabAlignment.start
                        : TabAlignment.fill,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: AppTextStyles.bodyBold(),
                    unselectedLabelStyle: AppTextStyles.bodyMedium(),
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Award Types'),
                      Tab(text: 'Badges'),
                      Tab(text: 'Rewards Catalog'),
                      Tab(text: 'Points Policy'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.awardTypes.isEmpty
                        ? EmptyStateView(
                            icon: Icons.error_outline_rounded,
                            title: 'Failed to load data',
                            message: state.error!,
                            onRetry: () => context
                                .read<HrConfigBloc>()
                                .add(LoadAllHrConfig()),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAwardTypesTab(context, theme, state),
                              _buildBadgesTab(context, theme, state),
                              _buildRewardsCatalogTab(context, theme, state),
                              _buildPointsPolicyTab(context, theme, state),
                              _buildSystemSettingsTab(context, theme, state),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1 — Award Types
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAwardTypesTab(
      BuildContext context, ThemeData theme, HrConfigState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context), vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Award Types',
            subtitle:
                'Define official award categories employees can be nominated for',
            actionLabel: 'Add Award Type',
            onAction: () => _showAwardTypeDialog(context),
          ),
          const SizedBox(height: 12),
          if (state.awardTypes.isEmpty)
            const EmptyStateView(
              icon: Icons.emoji_events_outlined,
              title: 'No award types yet',
            ),
          if (state.awardTypes.isNotEmpty)
            _DataCard(
              columns: const [
                'Name',
                'Key',
                'Points',
                'Frequency',
                'Status',
                ''
              ],
              flexes: const [3, 2, 1, 2, 1, 1],
              rows: state.awardTypes.map((a) {
                final isActive = a['is_active'] ?? true;
                return [
                  Text(a['name']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(a['award_key']?.toString() ?? '',
                      style: AppTextStyles.small(color: Colors.grey.shade600)),
                  Text('${a['points'] ?? 0}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(a['frequency']?.toString() ?? '',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  StatusBadge(status: isActive ? 'ACTIVE' : 'INACTIVE'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showAwardTypeDialog(context, existing: a),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => context.read<HrConfigBloc>().add(
                              ToggleItem(
                                entityType: HrConfigEntityType.awardType,
                                id: a['id'],
                                currentlyActive: isActive,
                              ),
                            ),
                      ),
                    ],
                  ),
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAwardTypeDialog(BuildContext context,
      {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final keyC = TextEditingController(text: existing?['award_key'] ?? '');
    final pointsC = TextEditingController(text: '${existing?['points'] ?? ''}');
    final freqC = TextEditingController(text: existing?['frequency'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final eligC =
        TextEditingController(text: existing?['eligibility_rule'] ?? '');
    final workflowC = TextEditingController(
        text: existing?['approval_workflow'] ?? 'MANAGER,DEPT_HEAD,HR');

    _showFormDialog(
      context: context,
      title: isEdit ? 'Edit Award Type' : 'Create Award Type',
      fields: [
        if (!isEdit)
          _Field(
              label: 'Award Key',
              controller: keyC,
              hint: 'e.g. STAR_PERFORMER'),
        _Field(label: 'Name', controller: nameC, hint: 'Star Performer Award'),
        _Field(label: 'Points', controller: pointsC, isNumber: true),
        _Field(
            label: 'Frequency',
            controller: freqC,
            dropdownOptions: const ['MONTHLY', 'QUARTERLY', 'YEARLY']),
        _Field(
            label: 'Eligibility Rule',
            controller: eligC,
            dropdownOptions: const [
              'PEER',
              'MANAGER_ONLY',
              'SENIOR_MGMT',
            ]),
        _Field(
            label: 'Approval Workflow',
            controller: workflowC,
            dropdownOptions: const [
              'MANAGER',
              'MANAGER,DEPT_HEAD',
              'MANAGER,DEPT_HEAD,HR',
              'DEPT_HEAD,HR',
              'HR',
            ]),
        _Field(label: 'Description', controller: descC, maxLines: 2),
      ],
      onSave: () {
        final data = <String, dynamic>{
          'name': nameC.text,
          'points': int.tryParse(pointsC.text) ?? 0,
          'frequency': freqC.text,
          'eligibility_rule': eligC.text,
          'approval_workflow': workflowC.text,
          'description': descC.text,
        };
        if (!isEdit) data['award_key'] = keyC.text;
        context.read<HrConfigBloc>().add(SaveItem(
              entityType: HrConfigEntityType.awardType,
              data: data,
              id: existing?['id'],
            ));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2 — Badges
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBadgesTab(
      BuildContext context, ThemeData theme, HrConfigState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context), vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Badges',
            subtitle:
                'Recognition badges employees earn through peer recognitions',
            actionLabel: 'Add Badge',
            onAction: () => _showBadgeDialog(context),
          ),
          const SizedBox(height: 12),
          if (state.badges.isEmpty)
            const EmptyStateView(
              icon: Icons.military_tech_outlined,
              title: 'No badges yet',
            ),
          if (state.badges.isNotEmpty)
            _DataCard(
              columns: const ['Name', 'Description', 'Points', 'Status', ''],
              flexes: const [2, 4, 1, 1, 1],
              rows: state.badges.map((b) {
                final isActive = b['is_active'] ?? true;
                return [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (b['icon_url'] != null &&
                              b['icon_url'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                b['icon_url'].toString(),
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.emoji_events, size: 28),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.emoji_events, size: 28),
                            ),
                          Flexible(
                            child: Text(b['name']?.toString() ?? '',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(b['description']?.toString() ?? '—',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis),
                  Text('${b['points'] ?? 50} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  StatusBadge(status: isActive ? 'ACTIVE' : 'INACTIVE'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showBadgeDialog(context, existing: b),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => context.read<HrConfigBloc>().add(
                              ToggleItem(
                                entityType: HrConfigEntityType.badge,
                                id: b['id'],
                                currentlyActive: isActive,
                              ),
                            ),
                      ),
                    ],
                  ),
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showBadgeDialog(BuildContext context,
      {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final iconC = TextEditingController(text: existing?['icon_url'] ?? '');
    final pointsC =
        TextEditingController(text: existing?['points']?.toString() ?? '');

    _showFormDialog(
      context: context,
      title: isEdit ? 'Edit Badge' : 'Create Badge',
      fields: [
        _Field(label: 'Name', controller: nameC, hint: 'e.g. Star Performer'),
        _Field(label: 'Description', controller: descC, maxLines: 2),
        _Field(label: 'Icon URL', controller: iconC, hint: 'https://...'),
        _Field(
            label: 'Points',
            controller: pointsC,
            hint: 'e.g. 50',
            isNumber: true),
      ],
      onSave: () {
        final data = <String, dynamic>{
          'name': nameC.text,
          'description': descC.text,
        };
        if (iconC.text.isNotEmpty) data['icon_url'] = iconC.text;
        if (pointsC.text.isNotEmpty) {
          data['points'] = int.tryParse(pointsC.text);
        }
        context.read<HrConfigBloc>().add(SaveItem(
              entityType: HrConfigEntityType.badge,
              data: data,
              id: existing?['id'],
            ));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — Rewards Catalog
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRewardsCatalogTab(
      BuildContext context, ThemeData theme, HrConfigState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context), vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Rewards Catalog',
            subtitle: 'Manage items employees can redeem with their points',
            actionLabel: 'Add Reward',
            onAction: () => _showRewardDialog(context),
          ),
          const SizedBox(height: 12),
          if (state.rewards.isEmpty)
            const EmptyStateView(
              icon: Icons.card_giftcard_outlined,
              title: 'No rewards yet',
            ),
          if (state.rewards.isNotEmpty)
            _DataCard(
              columns: const [
                'Name',
                'Type',
                'Points Cost',
                'Stock',
                'Status',
                ''
              ],
              flexes: const [3, 2, 2, 1, 1, 1],
              rows: state.rewards.map((r) {
                final isActive = r['is_active'] ?? true;
                final stock = r['stock_quantity'];
                return [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  StatusBadge(status: r['reward_type']?.toString() ?? ''),
                  Text('${r['points_required'] ?? r['points_cost'] ?? 0} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(stock == null ? '∞' : '$stock',
                      style: TextStyle(
                          fontSize: 13,
                          color: stock != null && stock <= 5
                              ? Colors.red.shade600
                              : Colors.grey.shade700)),
                  StatusBadge(status: isActive ? 'ACTIVE' : 'INACTIVE'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showRewardDialog(context, existing: r),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => context.read<HrConfigBloc>().add(
                              ToggleItem(
                                entityType: HrConfigEntityType.reward,
                                id: r['id'],
                                currentlyActive: isActive,
                              ),
                            ),
                      ),
                    ],
                  ),
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showRewardDialog(BuildContext context,
      {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final typeC = TextEditingController(text: existing?['reward_type'] ?? '');
    final pointsC = TextEditingController(
        text:
            '${existing?['points_required'] ?? existing?['points_cost'] ?? ''}');
    final stockC = TextEditingController(
        text: existing?['stock_quantity']?.toString() ?? '');

    _showFormDialog(
      context: context,
      title: isEdit ? 'Edit Reward' : 'Add Reward',
      fields: [
        _Field(label: 'Name', controller: nameC, hint: 'Amazon Gift Card'),
        _Field(
            label: 'Reward Type',
            controller: typeC,
            dropdownOptions: const ['GIFT_CARD', 'MERCHANDISE', 'EXPERIENCE']),
        _Field(label: 'Points Cost', controller: pointsC, isNumber: true),
        _Field(
            label: 'Stock Quantity',
            controller: stockC,
            isNumber: true,
            hint: 'Leave empty for unlimited'),
      ],
      onSave: () {
        final data = <String, dynamic>{
          'name': nameC.text,
          'reward_type': typeC.text,
          'points_required': int.tryParse(pointsC.text) ?? 0,
        };
        if (stockC.text.isNotEmpty) {
          data['stock_quantity'] = int.tryParse(stockC.text);
        }
        context.read<HrConfigBloc>().add(SaveItem(
              entityType: HrConfigEntityType.reward,
              data: data,
              id: existing?['id'],
            ));
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 4 — Points Policy
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPointsPolicyTab(
      BuildContext context, ThemeData theme, HrConfigState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context), vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Points Policy',
            subtitle: 'Define point values, limits & conversion rules',
            actionLabel: 'Add Rule',
            onAction: () => _showPolicyDialog(context),
          ),
          const SizedBox(height: 12),
          if (state.policies.isEmpty)
            const EmptyStateView(
              icon: Icons.rule_outlined,
              title: 'No rules configured',
            ),
          if (state.policies.isNotEmpty)
            _DataCard(
              columns: const [
                'Recognition Type',
                'Points',
                'Monthly Limit',
                'Cooldown',
                'Conv. Rate',
                'Active',
                ''
              ],
              flexes: const [3, 1, 2, 1, 2, 1, 1],
              rows: state.policies.map((p) {
                final isActive = p['is_active'] ?? true;
                return [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['recognition_type']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      if (p['event_key'] != null &&
                          p['event_key'].toString().isNotEmpty)
                        Text(p['event_key'].toString(),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  Text('${p['points'] ?? 0}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(p['monthly_limit']?.toString() ?? '—',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text(p['cooldown_days']?.toString() ?? '—',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text(p['conversion_rate']?.toString() ?? '—',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  StatusBadge(status: isActive ? 'ACTIVE' : 'INACTIVE'),
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => _showPolicyDialog(context, existing: p),
                  ),
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showPolicyDialog(BuildContext context,
      {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final typeC =
        TextEditingController(text: existing?['recognition_type'] ?? '');
    final eventC = TextEditingController(text: existing?['event_key'] ?? '');
    final pointsC = TextEditingController(text: '${existing?['points'] ?? ''}');
    final limitC =
        TextEditingController(text: '${existing?['monthly_limit'] ?? ''}');
    final cooldownC =
        TextEditingController(text: '${existing?['cooldown_days'] ?? ''}');
    final rateC =
        TextEditingController(text: '${existing?['conversion_rate'] ?? ''}');
    final convTypeC =
        TextEditingController(text: existing?['conversion_reward_type'] ?? '');

    _showFormDialog(
      context: context,
      title: isEdit ? 'Edit Policy Rule' : 'Create Policy Rule',
      fields: [
        if (!isEdit)
          _Field(
              label: 'Recognition Type',
              controller: typeC,
              dropdownOptions: const ['PEER', 'BADGE', 'CONVERSION', 'AWARD']),
        if (!isEdit)
          _Field(label: 'Event Key', controller: eventC, hint: 'Optional'),
        _Field(label: 'Points', controller: pointsC, isNumber: true),
        _Field(
            label: 'Monthly Limit',
            controller: limitC,
            isNumber: true,
            hint: 'Optional'),
        _Field(
            label: 'Cooldown Days',
            controller: cooldownC,
            isNumber: true,
            hint: 'Optional'),
        _Field(
            label: 'Conversion Rate',
            controller: rateC,
            hint: 'e.g. 0.1 (optional)'),
        if (!isEdit)
          _Field(
              label: 'Conversion Reward Type',
              controller: convTypeC,
              dropdownOptions: const ['PAYROLL', 'CHARITY']),
      ],
      onSave: () {
        if (isEdit) {
          final data = <String, dynamic>{};
          if (pointsC.text.isNotEmpty) {
            data['points'] = int.tryParse(pointsC.text);
          }
          if (limitC.text.isNotEmpty) {
            data['monthly_limit'] = int.tryParse(limitC.text);
          }
          if (cooldownC.text.isNotEmpty) {
            data['cooldown_days'] = int.tryParse(cooldownC.text);
          }
          if (rateC.text.isNotEmpty) {
            data['conversion_rate'] = double.tryParse(rateC.text);
          }
          data['is_active'] = existing['is_active'] ?? true;
          context.read<HrConfigBloc>().add(SaveItem(
                entityType: HrConfigEntityType.policyRule,
                data: data,
                id: existing['id'],
              ));
        } else {
          final data = <String, dynamic>{
            'recognition_type': typeC.text,
            'points': int.tryParse(pointsC.text) ?? 0,
            'is_active': true,
          };
          if (eventC.text.isNotEmpty) data['event_key'] = eventC.text;
          if (limitC.text.isNotEmpty) {
            data['monthly_limit'] = int.tryParse(limitC.text);
          }
          if (cooldownC.text.isNotEmpty) {
            data['cooldown_days'] = int.tryParse(cooldownC.text);
          }
          if (rateC.text.isNotEmpty) {
            data['conversion_rate'] = double.tryParse(rateC.text);
          }
          if (convTypeC.text.isNotEmpty) {
            data['conversion_reward_type'] = convTypeC.text;
          }
          context.read<HrConfigBloc>().add(SaveItem(
                entityType: HrConfigEntityType.policyRule,
                data: data,
              ));
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 5 — System Settings
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSystemSettingsTab(
      BuildContext context, ThemeData theme, HrConfigState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context), vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'System Settings',
            subtitle: 'Global parameters and feature flags',
          ),
          const SizedBox(height: 12),
          if (state.configs.isEmpty)
            const EmptyStateView(
              icon: Icons.settings_outlined,
              title: 'No settings configured',
            ),
          if (state.configs.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: state.configs.asMap().entries.map((entry) {
                  final c = entry.value;
                  final isLast = entry.key == state.configs.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['key']?.toString() ?? '',
                                  style: AppTextStyles.bodyBold()),
                              if (c['description'] != null &&
                                  c['description'].toString().isNotEmpty)
                                Text(c['description'].toString(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c['value']?.toString() ?? '',
                              style: AppTextStyles.bodyBold()),
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.edit_outlined,
                          color: theme.colorScheme.primary,
                          onTap: () => _showEditConfigDialog(context, c),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditConfigDialog(
      BuildContext context, Map<String, dynamic> config) {
    final valueC =
        TextEditingController(text: config['value']?.toString() ?? '');
    _showFormDialog(
      context: context,
      title: 'Edit: ${config['key']}',
      subtitle: config['description']?.toString(),
      fields: [
        _Field(label: 'Value', controller: valueC),
      ],
      onSave: () {
        context.read<HrConfigBloc>().add(UpdateConfigSetting(
              key: config['key'].toString(),
              value: valueC.text,
            ));
      },
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────────────

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label()),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(actionLabel),
          ),
      ],
    );
  }

  void _showFormDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<_Field> fields,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        maxWidth: 500,
        content: StatefulBuilder(builder: (ctx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ),
              ...fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: f.dropdownOptions != null
                        ? DropdownButtonFormField<String>(
                            initialValue:
                                f.dropdownOptions!.contains(f.controller.text)
                                    ? f.controller.text
                                    : null,
                            decoration: InputDecoration(
                              labelText: f.label,
                              hintText: f.hint ?? 'Select an option',
                              hintStyle: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400),
                            ),
                            items: f.dropdownOptions!
                                .map((o) =>
                                    DropdownMenuItem(value: o, child: Text(o)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                f.controller.text = v;
                                setDialogState(() {});
                              }
                            },
                          )
                        : TextField(
                            controller: f.controller,
                            keyboardType: f.isNumber
                                ? TextInputType.number
                                : TextInputType.text,
                            maxLines: f.maxLines,
                            decoration: InputDecoration(
                              labelText: f.label,
                              hintText: f.hint,
                              hintStyle: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400),
                            ),
                          ),
                  )),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              onSave();
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ═════════════════════════════════════════════════════════════════════
//  Reusable private widgets
// ═════════════════════════════════════════════════════════════════════

class _Field {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isNumber;
  final int maxLines;
  final List<String>? dropdownOptions;
  _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.isNumber = false,
    this.maxLines = 1,
    this.dropdownOptions,
  });
}

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(Icons.refresh_rounded,
              size: 18, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ToggleIconBtn extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleIconBtn({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
          size: 28,
          color: isActive ? Colors.green : Colors.red.shade400,
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final List<String> columns;
  final List<int> flexes;
  final List<List<Widget>> rows;
  const _DataCard({
    required this.columns,
    required this.flexes,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTableContent(theme, scrollable: true),
            )
          else
            _buildTableContent(theme),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text('${rows.length} item${rows.length == 1 ? '' : 's'}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(ThemeData theme, {bool scrollable = false}) {
    // When inside a horizontal SingleChildScrollView we must use fixed SizedBox
    // widths – Expanded requires bounded width which a scrollable axis can't provide.
    const double colUnit = 88.0;

    Widget headerCell(String label, int flex) {
      final text = Text(
        label.toUpperCase(),
        style: AppTextStyles.captionStrong(color: Colors.grey.shade500),
      );
      return scrollable
          ? SizedBox(width: flex * colUnit, child: text)
          : Expanded(flex: flex, child: text);
    }

    Widget dataCell(Widget child, int flex) {
      final aligned = Align(alignment: Alignment.centerLeft, child: child);
      return scrollable
          ? SizedBox(width: flex * colUnit, child: aligned)
          : Expanded(flex: flex, child: aligned);
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: Colors.grey.shade50),
          child: Row(
            children: List.generate(
              columns.length,
              (i) => headerCell(columns[i], flexes[i]),
            ),
          ),
        ),
        const Divider(height: 1),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final cells = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: List.generate(
                cells.length,
                (i) => dataCell(cells[i], flexes[i]),
              ),
            ),
          );
        }),
      ],
    );
  }
}
