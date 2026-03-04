import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/utils/user_role_utils.dart';
import '../../../../core/utils/award_utils.dart';

/// Two-step dialog for nominating an employee for an award.
///
/// Step 1 — Pick an Award Type (card grid like badge selection).
/// Step 2 — Search & select the nominee + write citation.
class NominateEmployeeDialog extends StatefulWidget {
  final List<AwardTypeEntity> awardTypes;
  final List<UserEntity> users;
  final NominationsBloc bloc;
  final UserEntity? currentUser;

  const NominateEmployeeDialog({
    super.key,
    required this.awardTypes,
    required this.users,
    required this.bloc,
    this.currentUser,
  });

  @override
  State<NominateEmployeeDialog> createState() => _NominateEmployeeDialogState();
}

class _NominateEmployeeDialogState extends State<NominateEmployeeDialog> {
  int _step = 0; // 0 = award type, 1 = nominee + citation

  AwardTypeEntity? _selectedAwardType;
  UserEntity? _selectedUser;

  final _searchController = TextEditingController();
  final _citationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _citationController.dispose();
    super.dispose();
  }

  List<AwardTypeEntity> get _allowedAwardTypes {
    if (widget.currentUser == null) return [];
    return widget.awardTypes.where((type) {
      final rule = type.eligibilityRule;
      final role = widget.currentUser!.role;

      if (rule == 'PEER') return true;

      if (rule == 'MANAGER_ONLY') {
        return UserRoleUtils.isManagerLike(role);
      }

      if (rule == 'SENIOR_MGMT') {
        return UserRoleUtils.isHR(
            role); // SENIOR_MGMT in this app context maps to HR/ADMIN or Dept Head?
        // Original logic: role == 'DEPT_HEAD' || role == 'HR' || role == 'ADMIN'
      }

      return true;
    }).toList();
  }

  List<UserEntity> get _filteredUsers {
    if (widget.currentUser == null) return [];

    final myId = widget.currentUser!.id;
    final myRole = widget.currentUser!.role;
    final myDeptId = widget.currentUser!.departmentId;

    // 1. Filter based on role/eligibility
    Iterable<UserEntity> list = widget.users.where((u) => u.id != myId);

    if (UserRoleUtils.isManager(myRole)) {
      // Managers can only nominate direct reports
      list = list.where((u) => u.managerId == myId);
    } else if (UserRoleUtils.isDepartmentHead(myRole)) {
      // Dept Heads can only nominate employees within their department
      if (myDeptId != null) {
        list = list.where((u) => u.departmentId == myDeptId);
      }
    } else if (UserRoleUtils.isEmployee(myRole)) {
      // Employees can only nominate other Employees (true Peer-to-Peer)
      list = list.where((u) => UserRoleUtils.isEmployee(u.role));
    }
    // HR and ADMIN can nominate anyone (except self)

    // 2. Filter by search query
    if (_searchQuery.isEmpty) return list.toList();
    return list
        .where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDialog(
      title: 'Nominate an Employee',
      showCloseButton: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Step indicator ──
          _buildStepIndicator(theme),
          const SizedBox(height: 24),
          // ── Body ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _step == 0 ? _buildStep1(theme) : _buildStep2(theme),
          ),
        ],
      ),
      actions: _buildFooterActions(theme),
    );
  }

  // ─── Header ─────────────────────────────────────────────────

  // ─── Step indicator ─────────────────────────────────────────
  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 0),
      child: Row(
        children: [
          _stepDot(theme, 0, 'Award Type'),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _step >= 1
                    ? theme.colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _stepDot(theme, 1, 'Nominee'),
        ],
      ),
    );
  }

  Widget _stepDot(ThemeData theme, int step, String label) {
    final active = _step == step;
    final done = _step > step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active
                ? theme.colorScheme.primary
                : Colors.grey.shade200,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? theme.colorScheme.primary : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Award Type grid ─────────────────────────────────
  Widget _buildStep1(ThemeData theme) {
    if (widget.awardTypes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Choose the award type',
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        ..._allowedAwardTypes
            .map((type) => _buildAwardTypeCard(theme, type))
            .toList(),
      ],
    );
  }

  Widget _buildAwardTypeCard(ThemeData theme, AwardTypeEntity type) {
    final isSelected = _selectedAwardType?.id == type.id;
    final color = AwardUtils.getColor(type.awardKey);

    return GestureDetector(
      onTap: () => setState(() => _selectedAwardType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Award icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(AwardUtils.getIcon(type.awardKey),
                  color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: AppTextStyles.cardTitle(),
                  ),
                  if (type.description != null &&
                      type.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      type.description!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(
                        icon: Icons.toll_rounded,
                        label: '${type.points} pts',
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 6),
                      _chip(
                        icon: Icons.schedule_rounded,
                        label: type.frequency,
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('check'),
                      color: theme.colorScheme.primary,
                      size: 22)
                  : Icon(Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('uncheck'),
                      color: Colors.grey.shade300,
                      size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Step 2: Employee search + citation ─────────────────
  Widget _buildStep2(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Selected award summary pill
          if (_selectedAwardType != null) _buildAwardSummaryPill(theme),
          const SizedBox(height: 16),
          // Employee search
          Text(
            'Select nominee',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 6),
          // User list
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _filteredUsers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No employees found'
                            : 'No results for "$_searchQuery"',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, thickness: 0.5, color: Colors.grey.shade100),
                    itemBuilder: (ctx, i) {
                      final user = _filteredUsers[i];
                      final isSelected = _selectedUser?.id == user.id;
                      return InkWell(
                        onTap: () => setState(() {
                          _selectedUser = user;
                          _searchController.text = user.name;
                          _searchQuery = '';
                        }),
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(10))
                            : i == _filteredUsers.length - 1
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(10))
                                : BorderRadius.zero,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.06)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Text(user.email,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          // Citation
          Text(
            'Citation',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _citationController,
            decoration: InputDecoration(
              hintText: 'Describe why this person deserves this award…',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            maxLines: 4,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please provide a citation'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAwardSummaryPill(ThemeData theme) {
    final type = _selectedAwardType!;
    final color = AwardUtils.getColor(type.awardKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(AwardUtils.getIcon(type.awardKey), color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              type.name,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              '${type.points} pts',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _selectedAwardType = null;
              _step = 0;
            }),
            child: Icon(Icons.edit_outlined,
                size: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── Footer ──────────────────────────────────────────────────
  List<Widget> _buildFooterActions(ThemeData theme) {
    return [
      if (_step == 1)
        TextButton.icon(
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
        ),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      if (_step == 0)
        ElevatedButton.icon(
          onPressed: _selectedAwardType == null
              ? null
              : () => setState(() => _step = 1),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Next'),
        )
      else
        ElevatedButton.icon(
          onPressed: _onSubmit,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Submit'),
        ),
    ];
  }

  // ─── Submit ──────────────────────────────────────────────────
  void _onSubmit() {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a nominee'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.bloc.add(CreateNominationRequested(
      nomineeId: _selectedUser!.id,
      awardTypeId: _selectedAwardType!.id,
      citation: _citationController.text.trim(),
    ));
    Navigator.pop(context);
  }
}
