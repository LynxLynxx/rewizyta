import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// "umówiony pn 29.09, 09:30", in the same shape as the due status tag. On the
/// client card and the due list row.
class const BookingTag({super.key, required final DateTime startsAt}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.doneBackground,
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(
          context.l10n.bookingTag(formatBooking(context.l10n, startsAt)),
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.doneForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
