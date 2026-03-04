import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recognitions Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<RecognitionsBloc, RecognitionsState>(
                  builder: (context, state) {
                    if (state.status == RecognitionStatus.loading &&
                        state.badges.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == RecognitionStatus.failure &&
                        state.badges.isEmpty) {
                      return Center(
                          child: Text('Error: ${state.errorMessage}'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppreciationComposer(
                          badges: state.badges,
                          onBadgeSelected: (badge) {
                            _showSendRecognitionDialog(
                                context, badge, state.users);
                          },
                        ),
                        const SizedBox(height: 32),
                        if (state.stats != null) ...[
                          AppreciationStats(stats: state.stats!),
                          const SizedBox(height: 32),
                        ],
                        // Feed placeholder for now
                        const Text(
                          'Recognition Feed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RecognitionFeedList(feed: state.feed),
                      ],
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
        return AlertDialog(
          title: Text('Send ${badge.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Select Colleague'),
                  items: users.map((user) {
                    return DropdownMenuItem<int>(
                      value: user.id,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedReceiverId = value,
                  validator: (value) =>
                      value == null ? 'Please select a colleague' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Message (Optional)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  onChanged: (value) => message = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Use the context from the build method (the one with BlocProvider)
                  // BUT showDialog creates a new context branch.
                  // We can't access the BlocProvider from dialogContext if it's above the Navigator?
                  // Actually, showDialog pushes a new route. The context passed to showDialog (context)
                  // should be able to provide the Bloc if the BlocProvider is above the Navigator (MaterialApp).
                  // Here BlocProvider is local to EmployeeRecognitionsPage.
                  // So we must capture the bloc before showing dialog or use BlocProvider.value if we were navigating.
                  // Since showDialog context is different, we should pass the bloc callback or use the parent context
                  // to find the bloc *before* the dialog, or capture it.

                  // Simple fix: Invoke the event using the parent 'context' (from build)
                  // but we are in a stateless widget, so 'context' is available in the method scope variables if passed.
                  // Yes, we passed 'context' to _showSendRecognitionDialog.

                  // Wait, accessing Provider via 'context' inside the callback might be unsafe if the widget is rebuilt?
                  // But 'context' here is the one from build().

                  context.read<RecognitionsBloc>().add(SendRecognitionRequested(
                        receiverId: selectedReceiverId!,
                        badgeId: badge.id,
                        message: message,
                      ));
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
