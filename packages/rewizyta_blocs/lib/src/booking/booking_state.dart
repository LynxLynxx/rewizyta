import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The booking sheet: a week of days, the free hours of the chosen one and
/// what is picked.
final class const BookingState({
  final bool isLoading = true,

  /// Seven consecutive days from the first day of the shown week.
  final List<BookingDayViewModel> days = const [],

  /// Index into [days] of the chosen day.
  final int selectedDay = 0,

  /// Free hours of the chosen day, as UTC instants.
  final List<DateTime> slots = const [],
  final DateTime? selectedSlot,
  final bool isTimeFixed = false,

  /// The client already has an open booking, which booking again moves.
  final bool hasBooking = false,

  /// Whether a week before this one is still in the future.
  final bool canGoBack = false,

  /// A booking or a cancellation is being written; the buttons wait for it.
  final bool isSaving = false,
}) with Equatable {
  bool get canBook => selectedSlot != null && !isSaving;

  @override
  List<Object?> get props => [
    isLoading,
    days,
    selectedDay,
    slots,
    selectedSlot,
    isTimeFixed,
    hasBooking,
    canGoBack,
    isSaving,
  ];
}

enum BookingSignal() {
  /// The booking was saved; the sheet closes.
  booked,

  /// The booking was cancelled; the sheet closes.
  cancelled,
}
