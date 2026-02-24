import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

/// A standardized header used at the top of main pages.
class AppPageHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? action;

  const AppPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = title != null || subtitle != null;

    // Nothing to render
    if (!hasText && action == null) return const SizedBox(height: 24);

    // Action-only (title/subtitle moved to top bar)
    if (!hasText) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(alignment: Alignment.centerRight, child: action!),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile && action != null) ...[
          if (title != null) Text(title!, style: AppTextStyles.pageTitle()),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.body(color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 12),
          action!,
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!, style: AppTextStyles.pageTitle()),
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
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
