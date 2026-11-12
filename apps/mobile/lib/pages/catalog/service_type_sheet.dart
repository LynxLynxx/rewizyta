import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/widgets/labeled_field.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// A service type's name, cycle, default price and archive, or a new one under
/// [tradeId]. A bottom sheet over the tab bar.
class const ServiceTypeSheet({
  super.key,
  required final String tradeId,
  final ServiceTypeViewModel? type,
}) extends StatelessWidget {
  static Future<void> show(
    BuildContext context, {
    required String tradeId,
    ServiceTypeViewModel? type,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => ServiceTypeSheet(tradeId: tradeId, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          Dependencies.instance.get<ServiceTypeFormCubit>()..init(tradeId: tradeId, type: type),
      child: const ServiceTypeSheetView(),
    );
  }
}

@visibleForTesting
class const ServiceTypeSheetView({super.key}) extends StatefulWidget {
  @override
  State<ServiceTypeSheetView> createState() => _ServiceTypeSheetViewState();
}

class _ServiceTypeSheetViewState()
    extends State<ServiceTypeSheetView>
    with
        ErrorHandlerStateMixin<ServiceTypeFormCubit, ServiceTypeSheetView>,
        SignalHandlerStateMixin<ServiceTypeFormCubit, ServiceTypeFormSignal, ServiceTypeSheetView> {
  @override
  void handleSignal(ServiceTypeFormSignal signal) {
    switch (signal) {
      case ServiceTypeFormSignal.saved:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.catalogSaved)));
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ServiceTypeFormCubit cubit() => context.read<ServiceTypeFormCubit>();
    final state = context.watch<ServiceTypeFormCubit>().state;
    final mono = context.textTheme.bodyLarge?.copyWith(fontFamily: AppFonts.mono);
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
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
              state.isEditing ? l10n.catalogEditServiceType : l10n.catalogNewServiceType,
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            LabeledField(
              label: l10n.catalogName,
              child: TextFormField(
                initialValue: state.name,
                onChanged: (value) => cubit().update(name: value),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: state.template?.localizedName(l10n) ?? l10n.catalogNewServiceTypeHint,
                ),
              ),
            ),
            LabeledField(
              label: l10n.catalogCycleLabel,
              child: TextFormField(
                initialValue: state.cycle,
                onChanged: (value) => cubit().update(cycle: value),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: mono,
                decoration: InputDecoration(
                  helperText: l10n.catalogCycleHelper,
                  helperMaxLines: 2,
                  errorText: state.isCycleInvalid
                      ? l10n.catalogCycleInvalid(ServiceType.maxCycleMonths)
                      : null,
                ),
              ),
            ),
            LabeledField(
              label: l10n.catalogPrice,
              child: TextFormField(
                initialValue: state.price,
                onChanged: (value) => cubit().update(price: value),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: mono,
                decoration: InputDecoration(
                  hintText: l10n.visitPriceHint,
                  errorText: state.isPriceInvalid ? l10n.visitPriceInvalid : null,
                ),
              ),
            ),
            if (state.isEditing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.catalogArchive),
                subtitle: Text(l10n.catalogArchiveHint),
                value: state.isArchived,
                onChanged: (value) => cubit().update(isArchived: value),
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: state.canSave ? cubit().save : null,
              child: Text(l10n.catalogSave),
            ),
          ],
        ),
      ),
    );
  }
}
