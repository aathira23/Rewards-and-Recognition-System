import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/utils/user_role_utils.dart';
import '../../../../core/utils/award_utils.dart';

/// Single-page nomination form with three numbered sections:
/// 1. Choose Award Type  (2-column grid)
/// 2. Select Nominee     (search + scrollable list)
/// 3. Citation           (textarea)
///
/// Pass [initialAwardType] to pre-select an award and jump straight
/// to section 2 when launched from [ActiveAwardsDialog].
class NominateEmployeeDialog extends StatefulWidget {
  final List<AwardTypeEntity> awardTypes;
  final List<UserEntity> users;
  final NominationsBloc bloc;
  final UserEntity? currentUser;
  final AwardTypeEntity? initialAwardType;

  const NominateEmployeeDialog({
    super.key,
    required this.awardTypes,
    required this.users,
    required this.bloc,
    this.currentUser,
    this.initialAwardType,
  });

  @override
  State<NominateEmployeeDialog> createState() =>
      _NominateEmployeeDialogState();
}

class _NominateEmployeeDialogState extends State<NominateEmployeeDialog> {
  AwardTypeEntity? _selectedAwardType;
  UserEntity? _selectedUser;

  final _searchController = TextEditingController();
  final _citationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedAwardType = widget.initialAwardType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _citationController.dispose();
    super.dispose();
  }

  // ── Eligibility ──────────────────────────────────────────────────────
  List<AwardTypeEntity> get _allowedAwardTypes {
    if (widget.currentUser == null) return widget.awardTypes;
    return widget.awardTypes.where((type) {
      final rule = type.eligibilityRule;
      final role = widget.currentUser!.role;
      if (rule == 'PEER') return true;
      if (rule == 'MANAGER_ONLY') return UserRoleUtils.isManagerLike(role);
      if (rule == 'SENIOR_MGMT') return UserRoleUtils.isHR(role);
      return true;
    }).toList();
  }

  // ── User filtering ───────────────────────────────────────────────────
  List<UserEntity> get _filteredUsers {
    if (widget.currentUser == null) return [];
    final myId = widget.currentUser!.id;
    final myRole = widget.currentUser!.role;
    final myDeptId = widget.currentUser!.departmentId;

    Iterable<UserEntity> list = widget.users.where((u) => u.id != myId);

    if (UserRoleUtils.isManager(myRole)) {
      list = list.where((u) => u.managerId == myId);
    } else if (UserRoleUtils.isDepartmentHead(myRole)) {
      if (myDeptId != null) {
        list = list.where((u) => u.departmentId == myDeptId);
      }
    } else if (UserRoleUtils.isEmployee(myRole)) {
      list = list.where((u) => UserRoleUtils.isEmployee(u.role));
    }

    if (_searchQuery.isEmpty) return list.toList();
    return list
        .where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Nominate an Employee',
      showCloseButton: false,
      maxWidth: 640,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _sectionLabel('1. Choose Award Type'),
            const SizedBox(height: 12),
            _buildAwardGrid(context),
            const SizedBox(height: 24),
            _sectionLabel('2. Select Nominee'),
            const SizedBox(height: 12),
            _buildNomineeSearch(context),
            const SizedBox(height: 24),
            _sectionLabel('3. Citation'),
            const SizedBox(height: 12),
            _buildCitationField(),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _onSubmit,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Submit Nomination'),
          style: ElevatedButton.styleFrom(
            backgroundColor: (_selectedAwardType != null && _selectedUser != null)
                ? const Color(0xFF2D2A70)
                : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyBold(color: Colors.black87),
    );
  }

  // ── Section 1: Award Grid ────────────────────────────────────────────
  Widget _buildAwardGrid(BuildContext context) {
    final allowed = _allowedAwardTypes;
    if (allowed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: allowed.length,
      itemBuilder: (_, i) => _buildAwardCard(context, allowed[i]),
    );
  }

  Widget _buildAwardCard(BuildContext context, AwardTypeEntity type) {
    final theme = Theme.of(context);
    final isSelected = _selectedAwardType?.id == type.id;
    final color = AwardUtils.getColor(type.awardKey);

    return GestureDetector(
      onTap: () => setState(() => _selectedAwardType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(AwardUtils.getIcon(type.awardKey),
                      color: color, size: 16),
                ),
                const Spacer(),
                // Radio indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: isSelected
                      ? Icon(Icons.radio_button_checked,
                          key: const ValueKey('on'),
                          color: theme.colorScheme.primary,
                          size: 18)
                      : Icon(Icons.radio_button_unchecked,
                          key: const ValueKey('off'),
                          color: Colors.grey.shade300,
                          size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              type.name,
              style: AppTextStyles.cardTitle(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (type.description != null && type.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  type.description!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(
                  label: '${type.points} pts',
                  color: Colors.amber.shade700,
                  bgColor: Colors.amber.shade50,
                ),
                const SizedBox(width: 6),
                _chip(
                  icon: Icons.schedule_rounded,
                  label: type.frequency.toUpperCase(),
                  color: Colors.grey.shade600,
                  bgColor: Colors.grey.shade100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    IconData? icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Section 2: Nominee Search ────────────────────────────────────────
  Widget _buildNomineeSearch(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            size: 16, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedUser = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: theme.colorScheme.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) {
                // If they start typing again, clear selection to show dropdown again
                setState(() {
                  _searchQuery = v;
                  if (_selectedUser != null) {
                    _selectedUser = null;
                  }
                });
              },
            ),
          ),
          // User list
          if (_searchQuery.isNotEmpty && _selectedUser == null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _filteredUsers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.shade200),
                      itemBuilder: (ctx, i) {
                        final user = _filteredUsers[i];
                        final isSel = _selectedUser?.id == user.id;
                        return InkWell(
                          onTap: () {
                            // Close dropdown (by setting selected user), keep text in field
                            setState(() {
                              _selectedUser = user;
                              _searchController.text = user.name;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            color: isSel
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.06)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(user.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ),
                                if (isSel)
                                  Icon(Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  // ── Section 3: Citation ──────────────────────────────────────────────
  Widget _buildCitationField() {
    return TextFormField(
      controller: _citationController,
      decoration: InputDecoration(
        hintText: 'Describe why this person deserves this award...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: const Color(0xFF2D2A70), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      maxLines: 4,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Please provide a citation' : null,
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────
  void _onSubmit() {
    if (_selectedAwardType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an award type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
