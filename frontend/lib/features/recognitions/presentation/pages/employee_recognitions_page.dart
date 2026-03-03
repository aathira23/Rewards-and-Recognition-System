import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_event.dart';
import '../bloc/recognitions_state.dart';
import '../widgets/appreciation_composer.dart';
import '../widgets/appreciation_stats.dart';
import '../widgets/recognition_feed_list.dart';

import '../../domain/entities/badge_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';

class EmployeeRecognitionsPage extends StatelessWidget {
  const EmployeeRecognitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecognitionsBloc>()
        ..add(GetBadgesRequested())
        ..add(GetAppreciationStatsRequested())
        ..add(GetRecognitionFeedRequested())
        ..add(GetUsersRequested()),
      child: BlocListener<RecognitionsBloc, RecognitionsState>(
        listener: (context, state) {
          if (state.status == RecognitionStatus.success &&
              state.lastSentRecognition != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recognition sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == RecognitionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'Failed to send recognition'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<RecognitionsBloc, RecognitionsState>(
                  builder: (context, state) {
                    if (state.status == RecognitionStatus.loading &&
                        state.badges.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == RecognitionStatus.failure &&
                        state.badges.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to load recognitions',
                        message: state.errorMessage,
                        onRetry: () => context
                            .read<RecognitionsBloc>()
                            .add(GetBadgesRequested()),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 768;

                        // Received section — always full width on top
                        final receivedSection = state.stats != null
                            ? AppreciationStats(stats: state.stats!)
                            : const SizedBox.shrink();

                        final sendSection = AppreciationComposer(
                          badges: state.badges,
                          onBadgeSelected: (badge) {
                            _showSendRecognitionDialog(
                                context, badge, state.users);
                          },
                        );

                        final feedPanel = Container(
                          height: isWide
                              ? MediaQuery.of(context).size.height * 0.72
                              : 420,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Recognition Feed',
                                      style: AppTextStyles.sectionHeader(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: RecognitionFeedList(feed: state.feed),
                              ),
                            ],
                          ),
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column: Received + Send
                              Expanded(
                                flex: 65,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    receivedSection,
                                    const SizedBox(height: 24),
                                    sendSection,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right column: Feed
                              Expanded(flex: 35, child: feedPanel),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            receivedSection,
                            const SizedBox(height: 24),
                            sendSection,
                            const SizedBox(height: 24),
                            feedPanel,
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSendRecognitionDialog(
      BuildContext context, BadgeEntity badge, List<UserEntity> users) {
    final formKey = GlobalKey<FormState>();
    int? selectedReceiverId;
    String? message;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AppDialog(
          title: 'Send ${badge.name}',
          maxWidth: 600,
          showCloseButton: false,
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To',
                  style: AppTextStyles.sectionTitle(),
                ),
                const SizedBox(height: 8),
                DropdownMenu<int>(
                  initialSelection: selectedReceiverId,
                  expandedInsets: EdgeInsets.zero,
                  menuHeight:
                      250, // Constrain height to prevent it from opening upwards
                  inputDecorationTheme: InputDecorationTheme(
                    hintStyle: AppTextStyles.body(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  hintText: 'Search employee name...',
                  dropdownMenuEntries: users.map((user) {
                    return DropdownMenuEntry<int>(
                      value: user.id,
                      label: user.name,
                    );
                  }).toList(),
                  onSelected: (value) => selectedReceiverId = value,
                  textStyle: AppTextStyles.body(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Message',
                  style: AppTextStyles.sectionTitle(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  style: AppTextStyles.body(),
                  decoration: InputDecoration(
                    hintText:
                        'Write a personalized message explaining why you\'re recognizing this person...',
                    hintStyle: AppTextStyles.body(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 4,
                  onChanged: (value) => message = value,
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<RecognitionsBloc>().add(SendRecognitionRequested(
                        receiverId: selectedReceiverId!,
                        badgeId: badge.id,
                        message: message,
                      ));
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Send Recognition'),
            ),
          ],
        );
      },
    );
  }
}
