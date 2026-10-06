import 'dart:convert';

import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

/// Encodes like the outbox does and decodes like a pull will.
Map<String, dynamic> wire(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('round trip through JSON', () {
    test('every synced entity survives fromDomain → JSON → toDomain', () {
      final dueEquipment = equipment().withDue(
        lastVisitAt: DateTime.utc(2026, 1, 31),
        nextDueAt: DateTime.utc(2027, 1, 31),
        updatedAt: t0,
      );
      final dueReminder = Reminder(
        id: 'r1',
        clientId: 'c1',
        kind: ReminderKind.due,
        equipmentId: 'e1',
        dueOn: DateTime.utc(2026, 11, 2),
        offsetDays: 30,
        sendAt: DateTime.utc(2026, 10, 3, 6),
        phone: '+48601234567',
        body: 'Dzień dobry',
        status: ReminderStatus.sent,
        sentAt: DateTime.utc(2026, 10, 3, 6, 1),
        createdAt: t0,
        updatedAt: t0,
      );

      expect(
        ClientDto.fromJson(wire(ClientDto.fromDomain(client()).toJson())).toDomain(),
        client(),
      );
      expect(TradeDto.fromJson(wire(TradeDto.fromDomain(trade()).toJson())).toDomain(), trade());
      final defaultTrade = trade(name: null, template: TradeTemplate.chimney);
      final defaultTradeJson = TradeDto.fromDomain(defaultTrade).toJson();
      expect(defaultTradeJson['template_key'], 'chimney');
      expect(TradeDto.fromJson(wire(defaultTradeJson)).toDomain(), defaultTrade);
      final pricedType = serviceType(
        tradeId: 't1',
        defaultPriceGrosze: 25000,
        name: null,
        template: ServiceTypeTemplate.chimneySweepSolid,
      );
      expect(ServiceTypeDto.fromDomain(pricedType).toJson()['template_key'], 'chimney_sweep_solid');
      expect(
        ServiceTypeDto.fromJson(wire(ServiceTypeDto.fromDomain(pricedType).toJson())).toDomain(),
        pricedType,
      );
      expect(
        EquipmentDto.fromJson(wire(EquipmentDto.fromDomain(dueEquipment).toJson())).toDomain(),
        dueEquipment,
      );
      final pricedVisit = visit(priceGrosze: 18050, appointmentId: 'a1');
      expect(
        VisitDto.fromJson(wire(VisitDto.fromDomain(pricedVisit).toJson())).toDomain(),
        pricedVisit,
      );
      expect(
        VisitItemDto.fromJson(wire(VisitItemDto.fromDomain(visitItem()).toJson())).toDomain(),
        visitItem(),
      );
      final noShow = appointment(status: AppointmentStatus.noShow);
      expect(
        AppointmentDto.fromJson(wire(AppointmentDto.fromDomain(noShow).toJson())).toDomain(),
        noShow,
      );
      expect(
        ReminderDto.fromJson(wire(ReminderDto.fromDomain(dueReminder).toJson())).toDomain(),
        dueReminder,
      );
      expect(
        DeviceDto.fromJson(wire(DeviceDto.fromDomain(device()).toJson())).toDomain(),
        device(),
      );
    });
  });

  group('Postgres shapes', () {
    test('keys are the column names, user_id included when known', () {
      final json = AppointmentDto.fromDomain(appointment(), userId: 'u1').toJson();

      expect(
        json.keys,
        containsAll(['client_id', 'starts_at', 'duration_minutes', 'is_time_fixed', 'user_id']),
      );
      expect(json['user_id'], 'u1');
      expect(json['starts_at'], '2026-10-05T08:00:00.000Z');
    });

    test('timestamptz with an offset and a date column decode to UTC values', () {
      final dto = EquipmentDto.fromJson({
        'id': 'e1',
        'user_id': 'u1',
        'client_id': 'c1',
        'service_type_id': 's1',
        'count': 1,
        'last_visit_at': '2026-01-31',
        'next_due_at': '2027-01-31',
        'created_at': '2026-09-28T12:00:00+02:00',
        'updated_at': '2026-09-28T10:00:00.123456+00:00',
      });

      final equipment = dto.toDomain();
      expect(equipment.createdAt, DateTime.utc(2026, 9, 28, 10));
      expect(equipment.updatedAt.isUtc, isTrue);
      expect(equipment.nextDueAt, DateTime.utc(2027, 1, 31));
    });

    test('money stays an integer number of grosze on the wire', () {
      final json = wire(VisitDto.fromDomain(visit(priceGrosze: 18050)).toJson());

      expect(json['price_grosze'], 18050);
      expect(json['price_grosze'], isA<int>());
    });

    test('a snake_case enum value from the server decodes', () {
      final json = AppointmentDto.fromDomain(appointment()).toJson()..['status'] = 'no_show';

      expect(AppointmentDto.fromJson(json).toDomain().status, AppointmentStatus.noShow);
    });

    test('an unknown enum value fails loudly', () {
      final json = AppointmentDto.fromDomain(appointment()).toJson()..['status'] = 'rescheduled';

      expect(() => AppointmentDto.fromJson(json).toDomain(), throwsArgumentError);
    });

    test('every catalogue template has its own template_key and round-trips', () {
      for (final template in TradeTemplate.values) {
        final json = wire(TradeDto.fromDomain(trade(name: null, template: template)).toJson());
        expect(TradeDto.fromJson(json).toDomain().template, template);
      }
      for (final template in ServiceTypeTemplate.values) {
        final type = serviceType(name: null, template: template);
        final json = wire(ServiceTypeDto.fromDomain(type).toJson());
        expect(ServiceTypeDto.fromJson(json).toDomain().template, template);
      }
    });

    test('a template_key from a newer catalogue fails loudly, so the pull can skip the row', () {
      final json = TradeDto.fromDomain(trade()).toJson()..['template_key'] = 'plumber';

      expect(() => TradeDto.fromJson(json).toDomain(), throwsArgumentError);
    });
  });
}
