import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// A status by colour and word, never colour alone (`docs/DESIGN_BRIEF.md`,
/// "Status").
class const DueStatusTag({super.key, required final DueStatusViewModel status})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (background, foreground) = switch (status.kind) {
      DueStatusKind.overdue => (colors.overdueBackground, colors.overdueForeground),
      DueStatusKind.today || DueStatusKind.soon => (colors.soonBackground, colors.soonForeground),
      DueStatusKind.later || DueStatusKind.none => (colors.laterBackground, colors.laterForeground),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(
          status.localizedLabel(context.l10n),
          style: context.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
