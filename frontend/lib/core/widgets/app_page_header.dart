import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// A standardized header used at the top of main pages.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.pageTitle()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.body(color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 16),
              action!,
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
