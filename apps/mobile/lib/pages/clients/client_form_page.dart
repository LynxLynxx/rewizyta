import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/common/handlers/error_handler_state_mixin.dart';
import 'package:rewizyta/common/handlers/signal_handler_state_mixin.dart';
import 'package:rewizyta/common/widgets/back_link.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Add (no [id]) or edit a client. A new client pops with its id, an edit
/// with nothing.
class const ClientFormPage({super.key, final String? id}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Dependencies.instance.get<ClientFormCubit>()..init(id),
      child: const ClientFormView(),
    );
  }
}

@visibleForTesting
class const ClientFormView({super.key}) extends StatefulWidget {
  @override
  State<ClientFormView> createState() => _ClientFormViewState();
}

class _ClientFormViewState()
    extends State<ClientFormView>
    with
        ErrorHandlerStateMixin<ClientFormCubit, ClientFormView>,
        SignalHandlerStateMixin<ClientFormCubit, ClientFormSaved, ClientFormView> {
  @override
  void handleSignal(ClientFormSaved signal) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(signal.created ? l10n.clientAdded : l10n.clientSaved)));
    context.pop(signal.created ? signal.id : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.xs,
        title: const BackLink(),
      ),
      body: BlocBuilder<ClientFormCubit, ClientFormState>(
        builder: (context, state) => state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _Form(state: state),
      ),
    );
  }
}

class const _Form({required final ClientFormState state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ClientFormCubit cubit() => context.read<ClientFormCubit>();
    String? errorFor(ClientValidationError error) =>
        state.error == error ? error.localizedMessage(context) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        Text(
          state.isEditing ? l10n.clientFormEditTitle : l10n.clientFormNewTitle,
          style: context.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _LabeledField(
          label: l10n.clientFormName,
          child: TextFormField(
            initialValue: state.name,
            onChanged: (value) => cubit().update(name: value),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.clientFormNameHint,
              errorText: errorFor(ClientValidationError.nameEmpty),
            ),
          ),
        ),
        _LabeledField(
          label: l10n.clientFormPhone,
          child: TextFormField(
            initialValue: state.phone,
            onChanged: (value) => cubit().update(phone: value),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: context.textTheme.bodyLarge?.copyWith(fontFamily: AppFonts.mono),
            decoration: InputDecoration(
              hintText: l10n.clientFormPhoneHint,
              errorText: errorFor(ClientValidationError.phoneInvalid),
            ),
          ),
        ),
        _LabeledField(
          label: l10n.clientFormAddress,
          child: TextFormField(
            initialValue: state.addressLine,
            onChanged: (value) => cubit().update(addressLine: value),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _LabeledField(
                label: l10n.clientFormPostalCode,
                child: TextFormField(
                  initialValue: state.postalCode,
                  onChanged: (value) => cubit().update(postalCode: value),
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: _LabeledField(
                label: l10n.clientFormTown,
                child: TextFormField(
                  initialValue: state.town,
                  onChanged: (value) => cubit().update(town: value),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),
          ],
        ),
        _LabeledField(
          label: l10n.clientNote,
          child: TextFormField(
            initialValue: state.note,
            onChanged: (value) => cubit().update(note: value),
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: state.canSave ? () => cubit().save() : null,
          child: Text(l10n.clientFormSave),
        ),
      ],
    );
  }
}

/// A label above the input, as in the design. Above rather than inside,
/// because the 1.5 px input border alone falls short of 3:1 on white
/// (`docs/DESIGN_BRIEF.md`, "Accessibility"). Merged, so a screen reader
/// announces the label with the field.
class const _LabeledField({required final String label, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}
