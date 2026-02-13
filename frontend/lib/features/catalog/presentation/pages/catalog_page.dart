/// "The reward store interface where users can browse, search, and redeem points for items."
import 'package:flutter/material.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward Catalog')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Catalog Page Placeholder'),
            SizedBox(height: 20),
            // TODO: Connect to API
            // TODO: Add state management
            // TODO: Add pagination
            // TODO: Handle loading/error states
          ],
        ),
      ),
    );
  }
}
// TODO: Role-based guards
