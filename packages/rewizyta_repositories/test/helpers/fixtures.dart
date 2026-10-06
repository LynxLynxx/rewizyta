import 'package:rewizyta_models/rewizyta_models.dart';

/// The clock every fixture is stamped with.
final t0 = DateTime.utc(2026, 9, 28, 10);

Client client({String id = 'c1', String name = 'Jan Kowalski', DateTime? deletedAt}) =>
    Client(id: id, name: name, createdAt: t0, updatedAt: t0, deletedAt: deletedAt);

Trade trade({
  String id = 't1',
  String? name = 'Kominiarz',
  TradeTemplate? template,
  int sortOrder = 0,
  DateTime? createdAt,
  DateTime? deletedAt,
}) => Trade(
  id: id,
  name: name,
  template: template,
  sortOrder: sortOrder,
  createdAt: createdAt ?? t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

ServiceType serviceType({
  String id = 's1',
  String? name = 'Przegląd przewodów kominowych',
  int cycleMonths = 12,
  String? tradeId,
  int? defaultPriceGrosze,
  ServiceTypeTemplate? template,
  int sortOrder = 0,
  DateTime? deletedAt,
}) => ServiceType(
  id: id,
  name: name,
  cycleMonths: cycleMonths,
  tradeId: tradeId,
  defaultPriceGrosze: defaultPriceGrosze,
  template: template,
  sortOrder: sortOrder,
  createdAt: t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

Equipment equipment({
  String id = 'e1',
  String clientId = 'c1',
  String serviceTypeId = 's1',
  DateTime? createdAt,
  DateTime? deletedAt,
}) => Equipment(
  id: id,
  clientId: clientId,
  serviceTypeId: serviceTypeId,
  createdAt: createdAt ?? t0,
  updatedAt: createdAt ?? t0,
  deletedAt: deletedAt,
);

Visit visit({
  String id = 'v1',
  String clientId = 'c1',
  DateTime? doneAt,
  int? priceGrosze,
  String? appointmentId,
  DateTime? deletedAt,
}) => Visit(
  id: id,
  clientId: clientId,
  doneAt: doneAt ?? DateTime.utc(2026, 9),
  priceGrosze: priceGrosze,
  appointmentId: appointmentId,
  createdAt: t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

VisitItem visitItem({
  String id = 'i1',
  String visitId = 'v1',
  String equipmentId = 'e1',
  DateTime? deletedAt,
}) => VisitItem(
  id: id,
  visitId: visitId,
  equipmentId: equipmentId,
  createdAt: t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

Appointment appointment({
  String id = 'a1',
  String clientId = 'c1',
  DateTime? startsAt,
  AppointmentStatus status = AppointmentStatus.planned,
  DateTime? deletedAt,
}) => Appointment(
  id: id,
  clientId: clientId,
  startsAt: startsAt ?? DateTime.utc(2026, 10, 5, 8),
  status: status,
  createdAt: t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

Reminder reminder({
  String id = 'r1',
  String clientId = 'c1',
  ReminderKind kind = ReminderKind.manual,
  DateTime? sendAt,
  DateTime? deletedAt,
}) => Reminder(
  id: id,
  clientId: clientId,
  kind: kind,
  sendAt: sendAt ?? DateTime.utc(2026, 10, 1, 8),
  phone: '+48601234567',
  body: 'Dzień dobry, zbliża się termin przeglądu.',
  createdAt: t0,
  updatedAt: t0,
  deletedAt: deletedAt,
);

Device device({String id = 'd1'}) => Device(
  id: id,
  platform: DevicePlatform.android,
  pushProvider: PushProvider.fcm,
  pushToken: 'token',
  createdAt: t0,
  updatedAt: t0,
);
