import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/booking/booking_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/subscription_manager_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The "Umów termin" sheet. Watches the week's plans, so a booking synced in
/// from elsewhere takes its hour away while the sheet is open.
class BookingCubit(
  final AppointmentsService _appointmentsService,
  final DayPlanService _dayPlanService, {
  DateTime Function()? now,
}) extends Cubit<BookingState>
    with
        SubscriptionManagerMixin<BookingState>,
        BlocErrorEmitterMixin<BookingState>,
        BlocSignalEmitterMixin<BookingSignal, BookingState> {
  this : super(const BookingState());

  static const _days = 7;

  final DateTime Function() _now = now ?? DateTime.now;
  late String _clientId;
  late DateTime _today;
  late DateTime _weekStart;
  List<DayPlan>? _plans;
  Appointment? _open;
  bool _hasOpenState = false;
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  bool _isTimeFixed = false;
  bool _isSaving = false;

  void init(String clientId) {
    _clientId = clientId;
    final now = _now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = _today;
    subscribe(#open, _appointmentsService.watchOpenBooking(clientId), (open) {
      if (!_hasOpenState) {
        _isTimeFixed = open?.isTimeFixed ?? false;
      }
      _hasOpenState = true;
      _open = open;
      _emitState();
    }, onError: _onError);
    _watchWeek();
  }

  void selectDay(int index) {
    final plans = _plans;
    if (plans == null || index < 0 || index >= plans.length) return;
    _selectedDate = _day(_weekStart, index);
    _selectedSlot = null;
    _emitState();
  }

  void selectSlot(DateTime slot) {
    _selectedSlot = _selectedSlot == slot ? null : slot;
    _emitState();
  }

  void setTimeFixed({required bool value}) {
    _isTimeFixed = value;
    _emitState();
  }

  void nextWeek() => _moveWeek(_day(_weekStart, _days));

  void previousWeek() {
    if (_weekStart == _today) return;
    _moveWeek(_day(_weekStart, -_days));
  }

  Future<void> book() async {
    final slot = _selectedSlot;
    if (slot == null || _isSaving) return;
    _setSaving(value: true);
    try {
      await _appointmentsService.book(
        clientId: _clientId,
        startsAt: slot,
        isTimeFixed: _isTimeFixed,
      );
      if (isClosed) return;
      emitSignal(BookingSignal.booked);
    } on Exception catch (error) {
      if (isClosed) return;
      _setSaving(value: false);
      emitError(LocalizedException.create(error));
    }
  }

  Future<void> cancel() async {
    final open = _open;
    if (open == null || _isSaving) return;
    _setSaving(value: true);
    try {
      await _appointmentsService.setStatus(open.id, AppointmentStatus.cancelled);
      if (isClosed) return;
      emitSignal(BookingSignal.cancelled);
    } on Exception catch (error) {
      if (isClosed) return;
      _setSaving(value: false);
      emitError(LocalizedException.create(error));
    }
  }

  /// Stays set after a successful write: the sheet is closing, and a second tap
  /// must not write or signal again.
  void _setSaving({required bool value}) {
    _isSaving = value;
    _emitState();
  }

  void _moveWeek(DateTime start) {
    _weekStart = start;
    _plans = null;
    _selectedDate = null;
    _selectedSlot = null;
    emit(const BookingState());
    _watchWeek();
  }

  void _watchWeek() {
    subscribe(#days, _dayPlanService.watchDays(_weekStart, _days), (plans) {
      _plans = plans;
      _emitState();
    }, onError: _onError);
  }

  /// Local calendar day [offset] days from [from]; month arithmetic through
  /// the constructor, never a `Duration`, which is an hour off on a DST day.
  DateTime _day(DateTime from, int offset) => DateTime(from.year, from.month, from.day + offset);

  /// Waits for the plans and the open booking, so the sheet never opens half
  /// filled.
  void _emitState() {
    final plans = _plans;
    if (isClosed || plans == null || !_hasOpenState) return;
    final settings = plans.first.settings;
    final now = _now();
    // The client's own booking is being moved, so it does not take a slot.
    final others = [
      for (final plan in plans)
        [
          for (final stop in plan.stops)
            if (stop.appointment.id != _open?.id) stop.appointment,
        ],
    ];
    List<DateTime> slotsOf(int index) => freeSlots(
      day: _day(_weekStart, index),
      settings: settings,
      taken: others[index],
      notBefore: now,
    );

    var selected = _selectedDate == null
        ? -1
        : [for (var i = 0; i < _days; i++) _day(_weekStart, i)].indexOf(_selectedDate!);
    if (selected < 0) {
      selected = [for (var i = 0; i < _days; i++) i].firstWhere(
        (i) => slotsOf(i).isNotEmpty,
        orElse: () => 0,
      );
      _selectedDate = _day(_weekStart, selected);
    }
    final slots = slotsOf(selected);
    if (!slots.contains(_selectedSlot)) {
      _selectedSlot = null;
    }
    emit(
      BookingState(
        isLoading: false,
        days: [
          for (var i = 0; i < _days; i++)
            BookingDayViewModel(date: _day(_weekStart, i), visitCount: others[i].length),
        ],
        selectedDay: selected,
        slots: slots,
        selectedSlot: _selectedSlot,
        isTimeFixed: _isTimeFixed,
        hasBooking: _open != null,
        canGoBack: _weekStart != _today,
        isSaving: _isSaving,
      ),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (isClosed) return;
    emitError(LocalizedException.create(error));
  }
}
