import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta/pages/booking/booking_sheet.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

import '../../helpers/pump_app.dart';

class MockBookingCubit() extends MockCubit<BookingState> implements BookingCubit;

void main() {
  // 29 September 2026 is a Tuesday.
  final days = [
    for (var i = 0; i < 7; i++)
      BookingDayViewModel(date: DateTime(2026, 9, 29 + i), visitCount: i == 1 ? 3 : 0),
  ];
  final nine = DateTime(2026, 9, 29, 9).toUtc();
  final ten = DateTime(2026, 9, 29, 10).toUtc();
  final loaded = BookingState(isLoading: false, days: days, slots: [nine, ten]);

  late MockBookingCubit cubit;
  late StreamController<BookingSignal> signals;

  setUpAll(() => registerFallbackValue(DateTime.utc(2026)));

  setUp(() {
    cubit = MockBookingCubit();
    signals = StreamController<BookingSignal>.broadcast();
    when(() => cubit.errorStream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.signalStream).thenAnswer((_) => signals.stream);
    when(cubit.book).thenAnswer((_) async {});
    when(cubit.cancel).thenAnswer((_) async {});
  });

  tearDown(() => signals.close());

  Widget subject() => BlocProvider<BookingCubit>.value(
    value: cubit,
    child: const Scaffold(body: BookingSheetView()),
  );

  /// The sheet over a Scaffold of its own, which the snackbar shows on.
  Widget opened() => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => BlocProvider<BookingCubit>.value(
            value: cubit,
            child: const BookingSheetView(),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );

  testWidgets('shows a spinner while loading', (tester) async {
    when(() => cubit.state).thenReturn(const BookingState());

    await tester.pumpApp(subject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a chip per day with its visit count, and a chip per free hour', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());

    expect(find.text('Umów termin'), findsNWidgets(2));
    expect(find.text('wt 29.09'), findsOneWidget);
    expect(find.text('3 wiz.'), findsOneWidget);
    expect(find.text('wolne'), findsNWidgets(6));
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Odwołaj wizytę'), findsNothing);
  });

  testWidgets('tapping a day, an hour and the switch goes to the cubit', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());
    await tester.tap(find.text('3 wiz.'));
    await tester.tap(find.text('10:00'));
    await tester.tap(find.byType(Switch));

    verify(() => cubit.selectDay(1)).called(1);
    verify(() => cubit.selectSlot(ten)).called(1);
    verify(() => cubit.setTimeFixed(value: true)).called(1);
  });

  testWidgets('the button waits for an hour', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('the picked hour names the booking on the button', (tester) async {
    when(() => cubit.state).thenReturn(
      BookingState(isLoading: false, days: days, slots: [nine, ten], selectedSlot: nine),
    );

    await tester.pumpApp(subject());

    expect(find.text('Umów na wt 29.09, 09:00'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    verify(cubit.book).called(1);
  });

  testWidgets('says so when the day has no free hour', (tester) async {
    when(() => cubit.state).thenReturn(BookingState(isLoading: false, days: days));

    await tester.pumpApp(subject());

    expect(find.text('Brak wolnych godzin tego dnia.'), findsOneWidget);
  });

  final back = find.widgetWithIcon(IconButton, Icons.chevron_left);
  final forward = find.widgetWithIcon(IconButton, Icons.chevron_right);

  testWidgets('the arrow forward moves the week, back waits for a later one', (tester) async {
    when(() => cubit.state).thenReturn(loaded);

    await tester.pumpApp(subject());

    expect(tester.widget<IconButton>(back).onPressed, isNull);
    await tester.tap(forward);
    verify(cubit.nextWeek).called(1);
  });

  testWidgets('the arrow back is on from the second week', (tester) async {
    when(() => cubit.state).thenReturn(
      BookingState(isLoading: false, days: days, slots: [nine], canGoBack: true),
    );

    await tester.pumpApp(subject());
    await tester.tap(back);

    verify(cubit.previousWeek).called(1);
  });

  testWidgets('a client with a booking moves it or cancels it', (tester) async {
    when(() => cubit.state).thenReturn(
      BookingState(isLoading: false, days: days, slots: [nine], hasBooking: true),
    );

    await tester.pumpApp(subject());

    expect(find.text('Zmień termin'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Odwołaj wizytę'));
    await tester.tap(find.text('Odwołaj wizytę'));
    verify(cubit.cancel).called(1);
  });

  testWidgets('a booked signal closes the sheet and says so', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await tester.pumpApp(opened());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    signals.add(BookingSignal.booked);
    await tester.pumpAndSettle();

    expect(find.byType(BookingSheetView), findsNothing);
    expect(find.text('Umówiono wizytę.'), findsOneWidget);
  });

  testWidgets('a cancelled signal closes the sheet and says so', (tester) async {
    when(() => cubit.state).thenReturn(loaded);
    await tester.pumpApp(opened());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    signals.add(BookingSignal.cancelled);
    await tester.pumpAndSettle();

    expect(find.byType(BookingSheetView), findsNothing);
    expect(find.text('Odwołano wizytę.'), findsOneWidget);
  });
}
