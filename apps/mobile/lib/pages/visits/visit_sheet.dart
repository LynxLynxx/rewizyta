import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/widgets/labeled_field.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// "Zapisz wizytę": a bottom sheet, not a route (`docs/APP_FLOW.md`,
/// "Navigation"). With a [visitId] it edits that visit from the history and
/// can delete it.
class const VisitSheet({super.key, required final String clientId, final String? visitId})
    extends StatelessWidget {
  /// Completes with `true` after a delete, so the caller, whose cubit outlives
  /// the sheet, can offer the undo.
  static Future<bool?> show(BuildContext context, {required String clientId, String? visitId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => VisitSheet(clientId: clientId, visitId: visitId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          Dependencies.instance.get<VisitFormCubit>()..init(clientId, visitId: visitId),
      child: const VisitSheetView(),
    );
  }
}

@visibleForTesting
class const VisitSheetView({super.key}) extends StatefulWidget {
  @override
  State<VisitSheetView> createState() => _VisitSheetViewState();
}

class _VisitSheetViewState()
    extends State<VisitSheetView>
    with
        ErrorHandlerStateMixin<VisitFormCubit, VisitSheetView>,
        SignalHandlerStateMixin<VisitFormCubit, VisitFormSignal, VisitSheetView> {
  @override
  void handleSignal(VisitFormSignal signal) {
    switch (signal) {
      case VisitFormSignal.saved:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.visitSaved)));
        Navigator.of(context).pop();
      case VisitFormSignal.deleted:
        Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisitFormCubit, VisitFormState>(
      builder: (context, state) => Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: state.isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : _Form(state: state),
      ),
    );
  }
}

class const _Form({required final VisitFormState state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    VisitFormCubit cubit() => context.read<VisitFormCubit>();
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
          Text(
            state.isEditing ? l10n.visitEdit : l10n.visitRecord,
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.equipment.isNotEmpty) ...[
            Text(
              l10n.visitWorkDone,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in state.equipment)
                  FilterChip(
                    label: Text(item.workLabel(l10n)),
                    selected: state.ticked.contains(item.id),
                    onSelected: (_) => cubit().toggle(item.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          LabeledField(
            label: l10n.visitDate,
            child: TextFormField(
              initialValue: state.date,
              onChanged: (value) => cubit().update(date: value),
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
              style: context.textTheme.bodyLarge?.copyWith(fontFamily: AppFonts.mono),
              decoration: InputDecoration(
                hintText: l10n.clientFormLastVisitHint,
                errorText: state.dateError?.localizedMessage(l10n),
              ),
            ),
          ),
          LabeledField(
            label: l10n.visitPrice,
            child: TextFormField(
              initialValue: state.price,
              onChanged: (value) => cubit().update(price: value),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              style: context.textTheme.bodyLarge?.copyWith(fontFamily: AppFonts.mono),
              decoration: InputDecoration(
                hintText: l10n.visitPriceHint,
                errorText: state.isPriceInvalid ? l10n.visitPriceInvalid : null,
              ),
            ),
          ),
          LabeledField(
            label: l10n.clientNote,
            child: TextFormField(
              initialValue: state.note,
              onChanged: (value) => cubit().update(note: value),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
            ),
          ),
          if (state.nextDueLabel != null) _NextDue(date: state.nextDueLabel!),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: state.canSave ? cubit().save : null,
            child: Text(l10n.visitSave),
          ),
          if (state.isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
              onPressed: state.isSaving ? null : cubit().delete,
              child: Text(l10n.visitDelete),
            ),
          ],
        ],
      ),
    );
  }
}

class const _NextDue({required final String date}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = context.textTheme.bodyMedium?.copyWith(color: colors.soonForeground);
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.soonBackground,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.clientFormNextDue, style: style),
              Text(
                date,
                style: style?.copyWith(fontFamily: AppFonts.mono, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
