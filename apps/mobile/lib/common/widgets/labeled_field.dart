import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';

/// A label above the input, as in the design. Above rather than inside,
/// because the 1.5 px input border alone falls short of 3:1 on white
/// (`docs/DESIGN_BRIEF.md`, "Accessibility"). Merged, so a screen reader
/// announces the label with the field.
class const LabeledField({super.key, required final String label, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}
