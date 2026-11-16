import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// "Umów termin": a bottom sheet, not a route (`docs/APP_FLOW.md`,
/// "Navigation"). Picks a day of the coming week and a free hour; a client
/// with a booking moves it here or cancels it.
class const BookingSheet({super.key, required final String clientId}) extends StatelessWidget {
  /// On the root navigator, so the sheet covers the tab bar when a screen
  /// inside a tab opens it.
  static Future<void> show(BuildContext context, {required String clientId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => BookingSheet(clientId: clientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<BookingCubit>()..init(clientId),
      child: const BookingSheetView(),
    );
  }
}

@visibleForTesting
class const BookingSheetView({super.key}) extends StatefulWidget {
  @override
  State<BookingSheetView> createState() => _BookingSheetViewState();
}

class _BookingSheetViewState()
    extends State<BookingSheetView>
    with
        ErrorHandlerStateMixin<BookingCubit, BookingSheetView>,
        SignalHandlerStateMixin<BookingCubit, BookingSignal, BookingSheetView> {
  @override
  void handleSignal(BookingSignal signal) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (signal) {
          BookingSignal.booked => l10n.bookingBooked,
          BookingSignal.cancelled => l10n.bookingCancelled,
        }),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) => state.isLoading
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          : _Form(state: state),
    );
  }
}

class const _Form({required final BookingState state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    BookingCubit cubit() => context.read<BookingCubit>();
    final slot = state.selectedSlot;
    final title = state.hasBooking ? l10n.bookingChange : l10n.bookingOpen;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton(
                tooltip: l10n.bookingPreviousWeek,
                onPressed: state.canGoBack ? cubit().previousWeek : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, day) in state.days.indexed)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            selected: index == state.selectedDay,
                            onSelected: (_) => cubit().selectDay(index),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(day.dateLabel(l10n)),
                                Text(
                                  day.countLabel(l10n),
                                  style: context.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.bookingNextWeek,
                onPressed: cubit().nextWeek,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.slots.isEmpty)
            Text(
              l10n.bookingNoSlots,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final hour in state.slots)
                  ChoiceChip(
                    label: Text(formatTime(hour)),
                    selected: hour == slot,
                    onSelected: (_) => cubit().selectSlot(hour),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.bookingFixedTime),
            value: state.isTimeFixed,
            onChanged: (value) => cubit().setTimeFixed(value: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: state.canBook ? cubit().book : null,
            child: Text(slot == null ? title : l10n.bookingConfirm(formatBooking(l10n, slot))),
          ),
          if (state.hasBooking) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
              onPressed: state.isSaving ? null : cubit().cancel,
              child: Text(l10n.bookingCancel),
            ),
          ],
        ],
      ),
    );
  }
}
