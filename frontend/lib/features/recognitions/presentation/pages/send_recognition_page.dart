/// "The interface for users to select peers and send personalized recognition badges or eCards."
import 'package:flutter/material.dart';

class SendRecognitionPage extends StatelessWidget {
  const SendRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Recognition')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Send Recognition Page Placeholder'),
            SizedBox(height: 20),
            // TODO: Connect to API
            // TODO: Add state management
            // TODO: Handle loading/error states
          ],
        ),
      ),
    );
  }
}
// TODO: Role-based guards
// TODO: Add pagination (if choosing recipient from long list)
