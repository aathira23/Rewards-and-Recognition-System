import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
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
  State<NominateEmployeeDialog> createState() => _NominateEmployeeDialogState();
}

class _NominateEmployeeDialogState extends State<NominateEmployeeDialog> {
  AwardTypeEntity? _selectedAwardType;
  UserEntity? _selectedUser;

  final _searchController = TextEditingController();
  final _citationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _searchQuery = '';

  // ── Persona ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _personas = [];
  late Map<String, dynamic> _selectedPersona;

  @override
  void initState() {
    super.initState();
    _selectedAwardType = widget.initialAwardType;

    // Build persona list based on the logged-in user's role.
    _personas = [{'persona_type': 'PERSONAL', 'persona_label': null}];

    // We need the AuthBloc to be in scope — find it via context at build time.
    // We defer population to the first build via a post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.auth.user;
        final role = user?.role.toUpperCase() ?? '';
        final deptName = user?.departmentName ?? 'Department';
        if (role == 'HR' || role == 'MANAGER' || role == 'DEPT_HEAD') {
          setState(() {
            _personas = [
              {'persona_type': 'PERSONAL', 'persona_label': null},
              {'persona_type': 'DEPARTMENT', 'persona_label': '$deptName Team'},
            ];
            _selectedPersona = _personas.first;
          });
        } else if (role == 'ADMIN') {
          setState(() {
            _personas = [
              {'persona_type': 'PERSONAL', 'persona_label': null},
              {'persona_type': 'Company', 'persona_label': 'Tarento'},
            ];
            _selectedPersona = _personas.first;
          });
        }
      }
    });

    _selectedPersona = _personas.first;
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
      final directReports = list.where((u) => u.managerId == myId).toList();
      // Graceful fallback: manager_id may be null when using an external
      // User Service that doesn't expose hierarchy data. In that case show
      // all non-admin employees so nominations are still possible.
      list = directReports.isNotEmpty
          ? directReports
          : list.where((u) => !UserRoleUtils.isHR(u.role));
    } else if (UserRoleUtils.isDepartmentHead(myRole)) {
      if (myDeptId != null) {
        final deptMembers =
            list.where((u) => u.departmentId == myDeptId).toList();
        // Same fallback: department_id might not be populated.
        list = deptMembers.isNotEmpty
            ? deptMembers
            : list.where((u) => !UserRoleUtils.isHR(u.role));
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
            if (_personas.length > 1) ...[
              const SizedBox(height: 24),
              _sectionLabel('3. Nominate as'),
              const SizedBox(height: 12),
              _buildPersonaSelector(),
            ],
            const SizedBox(height: 24),
            _sectionLabel(_personas.length > 1 ? '4. Citation' : '3. Citation'),
            const SizedBox(height: 12),
            _buildCitationField(),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _onSubmit,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Submit Nomination'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                (_selectedAwardType != null && _selectedUser != null)
                    ? AppTheme.brandBlue
                    : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(AwardUtils.getIcon(type.awardKey),
                      color: color, size: 14),
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
            const SizedBox(height: 6),
            Text(
              type.name,
              style: AppTextStyles.bodyBold(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const SizedBox(height: 4),
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
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Section 2: Nominee Search ────────────────────────────────────────
  Widget _buildNomineeSearch(BuildContext context) {
    final theme = Theme.of(context);

    // Show a loading skeleton while the user list is still being fetched.
    if (widget.users.isEmpty) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 12),
            Text('Loading employees…',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

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
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
                                    .withOpacity(0.06)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.12),
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

  // ── Section 4: Persona Selector ──────────────────────────────────────
  Widget _buildPersonaSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedPersona,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          items: _personas.map((persona) {
            final isPersonal = persona['persona_type'] == 'PERSONAL';
            final label = isPersonal
                ? 'Nominate as Myself'
                : (persona['persona_label'] ?? persona['persona_type'].toString());
            return DropdownMenuItem<Map<String, dynamic>>(
              value: persona,
              child: Row(
                children: [
                  Icon(
                    isPersonal
                        ? Icons.person_outline
                        : Icons.business_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Text(label, style: AppTextStyles.body()),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedPersona = val);
          },
        ),
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
          borderSide: BorderSide(color: AppTheme.brandBlue, width: 1.5),
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
      AppSnackbar.warning(context, 'Please select a nominee');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isPersonal = _selectedPersona['persona_type'] == 'PERSONAL';
    widget.bloc.add(CreateNominationRequested(
      nomineeId: _selectedUser!.id,
      awardTypeId: _selectedAwardType!.id,
      citation: _citationController.text.trim(),
      personaType: _selectedPersona['persona_type'] as String?,
      personaLabel: isPersonal ? null : _selectedPersona['persona_label'] as String?,
    ));
    Navigator.pop(context);
  }
}
