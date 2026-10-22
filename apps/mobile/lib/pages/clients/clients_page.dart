import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/router/route_paths.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Page = the only place that touches DI. `ClientsView` is a plain widget a
/// test can pump with a mock cubit.
class const ClientsPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<ClientsCubit>()..init(),
      child: const ClientsView(),
    );
  }
}

@visibleForTesting
class const ClientsView({super.key}) extends StatefulWidget {
  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState()
    extends State<ClientsView>
    with ErrorHandlerStateMixin<ClientsCubit, ClientsView> {
  /// The form pops with the new client's id; the card opens from here, so
  /// its delete still comes back to this list for the undo.
  Future<void> _addClient() async {
    final id = await context.push<String>(RoutePaths.clientNew);
    if (id != null && mounted) await _openClient(id);
  }

  /// The card pops with `true` after a delete; the undo lives here because
  /// this cubit outlives the card.
  Future<void> _openClient(String id) async {
    final cubit = context.read<ClientsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final deleted = await context.push<bool>(RoutePaths.clientDetailFor(id));
    if (deleted != true) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.clientDeleted),
        action: SnackBarAction(label: l10n.undo, onPressed: () => cubit.restoreClient(id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.clientsTitle),
            actions: [
              if (!state.isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Text(
                    '${state.items.length}',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontFamily: AppFonts.mono,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: FilledButton(
                        onPressed: _addClient,
                        child: Text(context.l10n.clientsAdd),
                      ),
                    ),
                    if (!state.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          onChanged: (query) => context.read<ClientsCubit>().search(query),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(hintText: context.l10n.clientsSearchHint),
                        ),
                      ),
                    Expanded(
                      child: state.isEmpty
                          ? _Message(text: context.l10n.clientsEmpty)
                          : state.visibleItems.isEmpty
                          ? _Message(text: context.l10n.clientsNoResults)
                          : _ClientList(items: state.visibleItems, onOpen: _openClient),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class const _ClientList({
  required final List<ClientListItemViewModel> items,
  required final ValueChanged<String> onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.addressLabel ?? context.l10n.clientNoAddress),
          onTap: () => onOpen(item.id),
        );
      },
    );
  }
}

class const _Message({required final String text}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(text, style: context.textTheme.bodyLarge, textAlign: TextAlign.center),
      ),
    );
  }
}
