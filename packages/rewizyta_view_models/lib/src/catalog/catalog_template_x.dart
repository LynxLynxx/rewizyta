import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

/// Names of the default catalogue in the user's language. Rows store only the
/// enum; the UI calls `trade.localizedName(context.l10n)`.
extension TradeTemplateX on TradeTemplate {
  String localizedName(AppLocalizations l10n) => switch (this) {
    TradeTemplate.chimney => l10n.catalogTradeChimney,
    TradeTemplate.gas => l10n.catalogTradeGas,
    TradeTemplate.boiler => l10n.catalogTradeBoiler,
  };
}

extension ServiceTypeTemplateX on ServiceTypeTemplate {
  String localizedName(AppLocalizations l10n) => switch (this) {
    ServiceTypeTemplate.chimneyInspection => l10n.catalogServiceTypeChimneyInspection,
    ServiceTypeTemplate.chimneySweepSolid => l10n.catalogServiceTypeChimneySweepSolid,
    ServiceTypeTemplate.chimneySweepGas => l10n.catalogServiceTypeChimneySweepGas,
    ServiceTypeTemplate.gasInstallationCheck => l10n.catalogServiceTypeGasInstallationCheck,
    ServiceTypeTemplate.boilerService => l10n.catalogServiceTypeBoilerService,
  };
}

/// The user's name for the row, or the default's localized name until they
/// rename it. A row always has one of the two (a check constraint).
extension TradeNameX on Trade {
  String localizedName(AppLocalizations l10n) => name ?? template!.localizedName(l10n);
}

extension ServiceTypeNameX on ServiceType {
  String localizedName(AppLocalizations l10n) => name ?? template!.localizedName(l10n);
}
