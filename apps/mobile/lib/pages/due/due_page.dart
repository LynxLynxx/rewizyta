import 'package:flutter/material.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/launch_external.dart';
import 'package:rewizyta/common/widgets/due_status_tag.dart';
import 'package:rewizyta/pages/clients/open_client_card.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Terminy: who is overdue or due within 60 days.
class const DuePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<DueCubit>()..init(),
      child: const DueView(),
    );
  }
}

@visibleForTesting
class const DueView({super.key}) extends StatefulWidget {
  @override
  State<DueView> createState() => _DueViewState();
}

class _DueViewState() extends State<DueView> with ErrorHandlerStateMixin<DueCubit, DueView> {
  Future<void> _openClient(String id) {
    final cubit = context.read<DueCubit>();
    return openClientCard(context, id, onUndo: () => cubit.restoreClient(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<DueCubit, DueState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.dueTitle)),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.dueEmpty,
                      style: context.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        l10n.dueCount(state.count),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (state.overdue.isNotEmpty) ...[
                      _SectionLabel(
                        text: l10n.dueOverdueSection,
                        color: context.appColors.overdueForeground,
                      ),
                      for (final item in state.overdue) _DueRow(item: item, onOpen: _openClient),
                    ],
                    if (state.upcoming.isNotEmpty) ...[
                      _SectionLabel(
                        text: l10n.dueUpcomingSection,
                        color: context.appColors.accentText,
                      ),
                      for (final item in state.upcoming) _DueRow(item: item, onOpen: _openClient),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class const _SectionLabel({required final String text, required final Color color})
    extends StatelessWidget {
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
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class const _DueRow({
  required final DueListItemViewModel item,
  required final ValueChanged<String> onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle(context.l10n);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colorScheme.outlineVariant)),
      ),
      child: ListTile(
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) Text(subtitle),
            const SizedBox(height: AppSpacing.xs),
            DueStatusTag(status: item.status),
          ],
        ),
        trailing: item.phone == null
            ? null
            : OutlinedButton(
                // The theme stretches buttons to full width; a trailing one cannot.
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => launchExternal(context, Uri(scheme: 'tel', path: item.phone)),
                child: Text(context.l10n.dueCall),
              ),
        onTap: () => onOpen(item.id),
      ),
    );
  }
}
