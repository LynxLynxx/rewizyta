import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/widgets/back_link.dart';
import 'package:rewizyta/common/widgets/labeled_field.dart';
import 'package:rewizyta/pages/catalog/service_type_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Usługi i cykle: the trades and their service types, each with its cycle,
/// default price and archive.
class const CatalogPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<CatalogCubit>()..init(),
      child: const CatalogView(),
    );
  }
}

@visibleForTesting
class const CatalogView({super.key}) extends StatefulWidget {
  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState()
    extends State<CatalogView>
    with
        ErrorHandlerStateMixin<CatalogCubit, CatalogView>,
        SignalHandlerStateMixin<CatalogCubit, CatalogSignal, CatalogView> {
  @override
  void handleSignal(CatalogSignal signal) {
    switch (signal) {
      case CatalogSignal.defaultsRestored:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.catalogDefaultsRestored)));
    }
  }

  Future<void> _addTrade() async {
    final cubit = context.read<CatalogCubit>();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => const _TradeSheet(),
    );
    if (name != null) await cubit.addTrade(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: AppSpacing.xs,
            title: const BackLink(),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(l10n.catalogTitle, style: context.textTheme.headlineMedium),
                    ),
                    if (state.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(l10n.catalogEmpty, style: context.textTheme.bodyLarge),
                      ),
                    // Flat, so each label, row and button is its own node for
                    // screen readers (and Maestro), as on the due list.
                    for (final trade in state.trades) ...[
                      _TradeLabel(text: trade.localizedName(l10n)),
                      for (final type in trade.serviceTypes)
                        _ServiceTypeRow(tradeId: trade.id, type: type),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: OutlinedButton(
                          onPressed: () => ServiceTypeSheet.show(context, tradeId: trade.id),
                          child: Text(l10n.catalogAddServiceType),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(onPressed: _addTrade, child: Text(l10n.catalogAddTrade)),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => context.read<CatalogCubit>().restoreDefaults(),
                            child: Text(l10n.catalogRestoreDefaults),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// A trade's name, upper-case, above its service types.
class const _TradeLabel({required final String text}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          color: context.appColors.accentText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "Przegląd kotła" over "co 12 mies. · 180 zł"; a tap opens its sheet.
class const _ServiceTypeRow({
  required final String tradeId,
  required final ServiceTypeViewModel type,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colorScheme.outlineVariant)),
      ),
      child: ListTile(
        title: Text(
          type.localizedName(l10n),
          style: type.isArchived ? TextStyle(color: context.colorScheme.onSurfaceVariant) : null,
        ),
        subtitle: Text(type.details(l10n)),
        onTap: () => ServiceTypeSheet.show(context, tradeId: tradeId, type: type),
      ),
    );
  }
}

/// "Nowa branża": pops with the trimmed name. Its one rule (a name) lives here
/// rather than in a cubit's state, a deliberate exception for a single field.
class const _TradeSheet() extends StatefulWidget {
  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState() extends State<_TradeSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_name.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            Text(l10n.catalogNewTrade, style: context.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            LabeledField(
              label: l10n.catalogName,
              child: TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.catalogNewTradeHint),
              ),
            ),
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) => FilledButton(
                onPressed: _name.text.trim().isEmpty ? null : _save,
                child: Text(l10n.catalogSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
