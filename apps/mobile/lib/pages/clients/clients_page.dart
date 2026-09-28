import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Page = the only place that touches DI. `_ClientsView` is a plain widget a
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.clientsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // M2: push the add/edit form.
        onPressed: null,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(context.l10n.clientsAdd),
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          if (state.isEmpty) return const _EmptyView();
          return _ClientList(items: state.items);
        },
      ),
    );
  }
}

class const _ClientList({required final List<ClientListItemViewModel> items})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.phoneLabel ?? context.l10n.clientNoPhone),
          trailing: item.town == null ? null : Text(item.town!),
        );
      },
    );
  }
}

class const _EmptyView() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          context.l10n.clientsEmpty,
          style: context.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
