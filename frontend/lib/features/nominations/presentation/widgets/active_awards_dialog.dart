import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/nominations_bloc.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/utils/award_utils.dart';
import 'nominate_employee_dialog.dart';

/// Step 1 of the nomination flow.
///
/// Shows all available (backend-filtered) award types in a list.
/// Clicking "Nominate" on an award closes this dialog and immediately
/// opens [NominateEmployeeDialog] with that award pre-selected.
class ActiveAwardsDialog extends StatelessWidget {
  final List<AwardTypeEntity> awardTypes;
  final List<UserEntity> users;
  final NominationsBloc bloc;
  final UserEntity currentUser;

  const ActiveAwardsDialog({
    super.key,
    required this.awardTypes,
    required this.users,
    required this.bloc,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Active Awards',
      showCloseButton: false,
      maxWidth: 520,
      content: awardTypes.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: awardTypes
                  .map((type) => _AwardListTile(
                        type: type,
                        onNominate: () => _openNominationDialog(context, type),
                      ))
                  .toList(),
            ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _openNominationDialog(BuildContext context, AwardTypeEntity selected) {
    Navigator.pop(context); // close Active Awards
    showDialog(
      context: context,
      builder: (_) => NominateEmployeeDialog(
        awardTypes: awardTypes,
        users: users,
        bloc: bloc,
        currentUser: currentUser,
        initialAwardType: selected,
      ),
    );
  }
}

class _AwardListTile extends StatelessWidget {
  final AwardTypeEntity type;
  final VoidCallback onNominate;

  const _AwardListTile({required this.type, required this.onNominate});

  @override
  Widget build(BuildContext context) {
    final color = AwardUtils.getColor(type.awardKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AwardUtils.getIcon(type.awardKey),
                color: color, size: 24),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(type.name,
                          style: AppTextStyles.sectionTitle(
                              color: Colors.black87)),
                    ),
                    // Points badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green.shade200, width: 0.8),
                      ),
                      child: Text(
                        '+${type.points} pts',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
                if (type.description != null &&
                    type.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    type.description!,
                    style: AppTextStyles.small(color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Frequency badge
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          type.frequency.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.3),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Nominate button
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onNominate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Nominate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
