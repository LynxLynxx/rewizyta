import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/widgets/back_link.dart';
import 'package:rewizyta/router/route_paths.dart';
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
              onPressed: () => context.push(RoutePaths.clientEditFor(client.id)),
              child: Text(context.l10n.clientEdit),
            ),
        ],
      ),
      body: client == null
          ? const Center(child: CircularProgressIndicator())
          : _ClientCard(client: client),
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
