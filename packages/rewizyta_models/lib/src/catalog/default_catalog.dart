/// The default catalogue: trades in onboarding order, each with its service
/// types and their cycles. Rows store the value (snake_case, `chimney_sweep_solid`)
/// in `template_key`, so never rename or reuse one. Names are not data: the UI
/// localizes the value (`rewizyta_view_models`) until the user renames the row.
/// A self-hoster edits this file and `app_pl.arb` to change the defaults. See
/// docs/DATABASE.md, "service_types".
enum TradeTemplate(final List<ServiceTypeTemplate> serviceTypes) {
  chimney([
    ServiceTypeTemplate.chimneyInspection,
    ServiceTypeTemplate.chimneySweepSolid,
    ServiceTypeTemplate.chimneySweepGas,
  ]),
  gas([ServiceTypeTemplate.gasInstallationCheck]),
  boiler([ServiceTypeTemplate.boilerService]),
}

enum ServiceTypeTemplate({required final int cycleMonths}) {
  chimneyInspection(cycleMonths: 12),
  chimneySweepSolid(cycleMonths: 3),
  chimneySweepGas(cycleMonths: 12),
  gasInstallationCheck(cycleMonths: 12),
  boilerService(cycleMonths: 12),
}
