import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/launch_external.dart';
import 'package:rewizyta/common/widgets/back_link.dart';
import 'package:rewizyta/common/widgets/due_status_tag.dart';
import 'package:rewizyta/pages/visits/visit_sheet.dart';
import 'package:rewizyta/router/routes/routing/clients_route.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The client card. Pops with `true` after a delete, so the screen that
/// pushed it can offer the undo.
class const ClientDetailPage({super.key, required final String id}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<ClientDetailCubit>()..init(id),
      child: const ClientDetailView(),
    );
  }
}

@visibleForTesting
class const ClientDetailView({super.key}) extends StatefulWidget {
  @override
  State<ClientDetailView> createState() => _ClientDetailViewState();
}

class _ClientDetailViewState()
    extends State<ClientDetailView>
    with
        ErrorHandlerStateMixin<ClientDetailCubit, ClientDetailView>,
        SignalHandlerStateMixin<ClientDetailCubit, ClientDetailSignal, ClientDetailView> {
  @override
  void handleSignal(ClientDetailSignal signal) {
    switch (signal) {
      case ClientDetailSignal.deleted:
        context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.select<ClientDetailCubit, ClientDetailViewModel?>(
      (cubit) => cubit.state.client,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.xs,
        title: const BackLink(),
        actions: [
          if (client != null)
            TextButton(
              onPressed: () => ClientEditRoute(id: client.id).push<void>(context),
              child: Text(context.l10n.clientEdit),
            ),
        ],
      ),
      body: client == null
          ? const Center(child: CircularProgressIndicator())
          : _ClientCard(client: client),
      // Sticky, so recording a visit is one tap wherever the card is scrolled.
      bottomNavigationBar: client == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: FilledButton(
                  onPressed: () => VisitSheet.show(context, clientId: client.id),
                  child: Text(context.l10n.visitRecord),
                ),
              ),
            ),
    );
  }
}

class const _ClientCard({required final ClientDetailViewModel client}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final muted = context.colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        Text(client.name, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          client.addressLabel ?? context.l10n.clientNoAddress,
          style: textTheme.bodyMedium?.copyWith(color: context.appColors.text2),
        ),
        if (client.phoneLabel != null)
          Text(
            client.phoneLabel!,
            style: textTheme.bodyMedium?.copyWith(fontFamily: AppFonts.mono, color: muted),
          ),
        if (client.phone != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchExternal(context, Uri(scheme: 'tel', path: client.phone)),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(context.l10n.clientCall),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchExternal(context, Uri(scheme: 'sms', path: client.phone)),
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(context.l10n.clientSms),
                ),
              ),
            ],
          ),
        ],
        if (client.status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DueStatusTag(status: client.status!),
          ),
        ],
        if (client.equipment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.clientEquipment.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in client.equipment) _EquipmentCard(equipment: item),
        ],
        if (client.note != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.clientNote.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(client.note!, style: textTheme.bodyMedium),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
            onPressed: () => context.read<ClientDetailCubit>().deleteClient(),
            child: Text(context.l10n.clientDelete),
          ),
        ),
      ],
    );
  }
}

class const _EquipmentCard({required final ClientEquipmentViewModel equipment})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    return MergeSemantics(
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      equipment.serviceType?.localizedName(l10n) ?? '',
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DueStatusTag(status: equipment.status),
                ],
              ),
              if (equipment.label != null)
                Text(
                  equipment.label!,
                  style: textTheme.bodyMedium?.copyWith(color: context.appColors.text2),
                ),
              if (equipment.lastVisitLabel != null)
                _DateRow(label: l10n.clientFormLastVisit, date: equipment.lastVisitLabel!),
              if (equipment.nextDueLabel != null)
                _DateRow(label: l10n.clientFormNextDue, date: equipment.nextDueLabel!),
            ],
          ),
        ),
      ),
    );
  }
}

class const _DateRow({required final String label, required final String date})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(date, style: style?.copyWith(fontFamily: AppFonts.mono)),
        ],
      ),
    );
  }
}
