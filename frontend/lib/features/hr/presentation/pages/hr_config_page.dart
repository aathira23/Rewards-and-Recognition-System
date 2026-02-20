import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

/// HR Configuration page — manages Award Types, Rewards Catalog,
/// Points Policy, and System Settings in a single tabbed view.
class HrConfigPage extends StatefulWidget {
  const HrConfigPage({super.key});

  @override
  State<HrConfigPage> createState() => _HrConfigPageState();
}

class _HrConfigPageState extends State<HrConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  List<Map<String, dynamic>> _awardTypes = [];
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _policies = [];
  List<Map<String, dynamic>> _configs = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = sl<ApiClient>();
      final results = await Future.wait([
        client.get(ApiConstants.awardTypes),
        client.get(ApiConstants.badges),
        client.get(ApiConstants.catalogItems),
        client.get(ApiConstants.pointsRules),
        client.get(ApiConstants.systemConfig),
      ]);

      setState(() {
        _awardTypes = _extractList(results[0].data);
        _badges = _extractList(results[1].data);
        _rewards = _extractList(results[2].data);
        _policies = _extractList(results[3].data);
        _configs = _extractList(results[4].data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    final data = body is Map ? (body['data'] ?? []) : body;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return <Map<String, dynamic>>[];
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configuration', style: AppTextStyles.pageTitle()),
                      const SizedBox(height: 4),
                      Text(
                        'Manage awards, badges, catalog, point rules & system settings',
                        style: AppTextStyles.body(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                _RefreshBtn(onTap: _loadAll),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _loadAll)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAwardTypesTab(theme),
                          _buildBadgesTab(theme),
                          _buildRewardsCatalogTab(theme),
                          _buildPointsPolicyTab(theme),
                          _buildSystemSettingsTab(theme),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1 — Award Types
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAwardTypesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Award Types',
            subtitle:
                'Define official award categories employees can be nominated for',
            actionLabel: 'Add Award Type',
            onAction: () => _showAwardTypeDialog(),
          ),
          const SizedBox(height: 12),
          if (_awardTypes.isEmpty)
            _EmptyState(
                icon: Icons.emoji_events_outlined, text: 'No award types yet'),
          if (_awardTypes.isNotEmpty)
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
              rows: _awardTypes.map((a) {
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
                  _StatusChip(isActive: isActive),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showAwardTypeDialog(existing: a),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => _toggleAwardType(a),
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

  Future<void> _toggleAwardType(Map<String, dynamic> a) async {
    final id = a['id'];
    final current = a['is_active'] ?? true;
    // Optimistic update — item stays visible with new status immediately
    setState(() {
      final idx = _awardTypes.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        _awardTypes[idx] = {..._awardTypes[idx], 'is_active': !current};
      }
    });
    try {
      final client = sl<ApiClient>();
      await client.put('${ApiConstants.awardTypes}types/$id',
          data: {'is_active': !current});
      _snack(!current ? 'Award type activated' : 'Award type deactivated');
    } catch (e) {
      // Revert on failure
      setState(() {
        final idx = _awardTypes.indexWhere((x) => x['id'] == id);
        if (idx != -1) {
          _awardTypes[idx] = {..._awardTypes[idx], 'is_active': current};
        }
      });
      _snack('Failed: $e', isError: true);
    }
  }

  void _showAwardTypeDialog({Map<String, dynamic>? existing}) {
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
      onSave: () async {
        final client = sl<ApiClient>();
        if (isEdit) {
          await client
              .put('${ApiConstants.awardTypes}types/${existing['id']}', data: {
            'name': nameC.text,
            'points': int.tryParse(pointsC.text) ?? 0,
            'frequency': freqC.text,
            'eligibility_rule': eligC.text,
            'approval_workflow': workflowC.text,
            'description': descC.text,
          });
        } else {
          await client.post(ApiConstants.awardTypes, data: {
            'award_key': keyC.text,
            'name': nameC.text,
            'points': int.tryParse(pointsC.text) ?? 0,
            'frequency': freqC.text,
            'eligibility_rule': eligC.text,
            'approval_workflow': workflowC.text,
            'description': descC.text,
          });
        }
        _loadAll();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2 — Badges
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBadgesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Badges',
            subtitle:
                'Recognition badges employees earn through peer recognitions',
            actionLabel: 'Add Badge',
            onAction: () => _showBadgeDialog(),
          ),
          const SizedBox(height: 12),
          if (_badges.isEmpty)
            _EmptyState(
                icon: Icons.military_tech_outlined, text: 'No badges yet'),
          if (_badges.isNotEmpty)
            _DataCard(
              columns: const ['Name', 'Description', 'Points', 'Status', ''],
              flexes: const [2, 4, 1, 1, 1],
              rows: _badges.map((b) {
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
                  _StatusChip(isActive: isActive),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showBadgeDialog(existing: b),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => _toggleBadge(b),
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

  Future<void> _toggleBadge(Map<String, dynamic> b) async {
    final id = b['id'];
    final current = b['is_active'] ?? true;
    setState(() {
      final idx = _badges.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        _badges[idx] = {..._badges[idx], 'is_active': !current};
      }
    });
    try {
      final client = sl<ApiClient>();
      await client
          .put('${ApiConstants.badges}/$id', data: {'is_active': !current});
      _snack(!current ? 'Badge activated' : 'Badge deactivated');
    } catch (e) {
      setState(() {
        final idx = _badges.indexWhere((x) => x['id'] == id);
        if (idx != -1) {
          _badges[idx] = {..._badges[idx], 'is_active': current};
        }
      });
      _snack('Failed: $e', isError: true);
    }
  }

  void _showBadgeDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final descC = TextEditingController(text: existing?['description'] ?? '');
    final iconC = TextEditingController(text: existing?['icon_url'] ?? '');
    final pointsC =
        TextEditingController(text: existing?['points']?.toString() ?? '');

    _showFormDialog(
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
      onSave: () async {
        final client = sl<ApiClient>();
        final data = <String, dynamic>{
          'name': nameC.text,
          'description': descC.text,
        };
        if (iconC.text.isNotEmpty) {
          data['icon_url'] = iconC.text;
        }
        if (pointsC.text.isNotEmpty) {
          data['points'] = int.tryParse(pointsC.text);
        }
        if (isEdit) {
          await client.put('${ApiConstants.badges}/${existing['id']}',
              data: data);
        } else {
          await client.post(ApiConstants.badges, data: data);
        }
        _loadAll();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — Rewards Catalog
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRewardsCatalogTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Rewards Catalog',
            subtitle: 'Manage items employees can redeem with their points',
            actionLabel: 'Add Reward',
            onAction: () => _showRewardDialog(),
          ),
          const SizedBox(height: 12),
          if (_rewards.isEmpty)
            _EmptyState(
                icon: Icons.card_giftcard_outlined, text: 'No rewards yet'),
          if (_rewards.isNotEmpty)
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
              rows: _rewards.map((r) {
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
                  _TypeBadge(type: r['reward_type']?.toString() ?? ''),
                  Text('${r['points_required'] ?? r['points_cost'] ?? 0} pts',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(stock == null ? '∞' : '$stock',
                      style: TextStyle(
                          fontSize: 13,
                          color: stock != null && stock <= 5
                              ? Colors.red.shade600
                              : Colors.grey.shade700)),
                  _StatusChip(isActive: isActive),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        onTap: () => _showRewardDialog(existing: r),
                      ),
                      const SizedBox(width: 4),
                      _ToggleIconBtn(
                        isActive: isActive,
                        onTap: () => _toggleReward(r),
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

  Future<void> _toggleReward(Map<String, dynamic> r) async {
    final id = r['id'];
    final current = r['is_active'] ?? true;
    setState(() {
      final idx = _rewards.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        _rewards[idx] = {..._rewards[idx], 'is_active': !current};
      }
    });
    try {
      final client = sl<ApiClient>();
      await client.put('${ApiConstants.catalogItems}/$id',
          data: {'is_active': !current});
      _snack(!current ? 'Reward activated' : 'Reward deactivated');
    } catch (e) {
      setState(() {
        final idx = _rewards.indexWhere((x) => x['id'] == id);
        if (idx != -1) {
          _rewards[idx] = {..._rewards[idx], 'is_active': current};
        }
      });
      _snack('Failed: $e', isError: true);
    }
  }

  void _showRewardDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final typeC = TextEditingController(text: existing?['reward_type'] ?? '');
    final pointsC = TextEditingController(
        text:
            '${existing?['points_required'] ?? existing?['points_cost'] ?? ''}');
    final stockC = TextEditingController(
        text: existing?['stock_quantity']?.toString() ?? '');

    _showFormDialog(
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
      onSave: () async {
        final client = sl<ApiClient>();
        final data = <String, dynamic>{
          'name': nameC.text,
          'reward_type': typeC.text,
          'points_required': int.tryParse(pointsC.text) ?? 0,
        };
        if (stockC.text.isNotEmpty) {
          data['stock_quantity'] = int.tryParse(stockC.text);
        }
        if (isEdit) {
          await client.put('${ApiConstants.catalogItems}/${existing['id']}',
              data: data);
        } else {
          await client.post(ApiConstants.catalogItems, data: data);
        }
        _loadAll();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — Points Policy
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPointsPolicyTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'Points Policy',
            subtitle: 'Define point values, limits & conversion rules',
            actionLabel: 'Add Rule',
            onAction: () => _showPolicyDialog(),
          ),
          const SizedBox(height: 12),
          if (_policies.isEmpty)
            _EmptyState(icon: Icons.rule_outlined, text: 'No rules configured'),
          if (_policies.isNotEmpty)
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
              rows: _policies.map((p) {
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
                  _StatusChip(isActive: isActive),
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => _showPolicyDialog(existing: p),
                  ),
                ];
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showPolicyDialog({Map<String, dynamic>? existing}) {
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
    bool isActive = existing?['is_active'] ?? true;

    _showFormDialog(
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
      onSave: () async {
        final client = sl<ApiClient>();
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
          data['is_active'] = isActive;
          await client.put('${ApiConstants.pointsRules}/${existing['id']}',
              data: data);
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
          await client.post(ApiConstants.pointsRules, data: data);
        }
        _loadAll();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 4 — System Settings
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSystemSettingsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Column(
        children: [
          _sectionHeader(
            title: 'System Settings',
            subtitle: 'Global parameters and feature flags',
          ),
          const SizedBox(height: 12),
          if (_configs.isEmpty)
            _EmptyState(
                icon: Icons.settings_outlined, text: 'No settings configured'),
          if (_configs.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _configs.asMap().entries.map((entry) {
                  final c = entry.value;
                  final isLast = entry.key == _configs.length - 1;
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
                          onTap: () => _showEditConfigDialog(c),
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

  void _showEditConfigDialog(Map<String, dynamic> config) {
    final valueC =
        TextEditingController(text: config['value']?.toString() ?? '');
    _showFormDialog(
      title: 'Edit: ${config['key']}',
      subtitle: config['description']?.toString(),
      fields: [
        _Field(label: 'Value', controller: valueC),
      ],
      onSave: () async {
        final client = sl<ApiClient>();
        await client.put('${ApiConstants.systemConfig}${config['key']}',
            data: {'value': valueC.text});
        _loadAll();
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
    required String title,
    String? subtitle,
    required List<_Field> fields,
    required Future<void> Function() onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(title, style: AppTextStyles.sectionTitle()),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ),
                    ...fields.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: f.dropdownOptions != null
                              ? DropdownButtonFormField<String>(
                                  value: f.dropdownOptions!
                                          .contains(f.controller.text)
                                      ? f.controller.text
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: f.label,
                                    hintText: f.hint ?? 'Select an option',
                                    hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400),
                                  ),
                                  items: f.dropdownOptions!
                                      .map((o) => DropdownMenuItem(
                                          value: o, child: Text(o)))
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
                                        fontSize: 12,
                                        color: Colors.grey.shade400),
                                  ),
                                ),
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          await onSave();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          _snack('Saved successfully');
                        } catch (e) {
                          _snack('Error: $e', isError: true);
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => saving = false);
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
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
    return Material(
      color: Colors.white,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Failed to load data', style: AppTextStyles.cardTitle()),
          const SizedBox(height: 4),
          Text(message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.red.shade600,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700),
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

/// Larger toggle button used for activate/deactivate actions.
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

/// Generic data table card used across all config tabs.
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: List.generate(columns.length, (i) {
                return Expanded(
                  flex: flexes[i],
                  child: Text(
                    columns[i].toUpperCase(),
                    style: AppTextStyles.captionStrong(
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }),
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
                children: List.generate(cells.length, (i) {
                  return Expanded(
                    flex: flexes[i],
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: cells[i],
                    ),
                  );
                }),
              ),
            );
          }),
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
}
