import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc, Emitter;
import '../models/calendar_config.dart';
import '../models/calendar_day_entity.dart';
import '../service/source/calendar_weeks_builder.dart';
import '../utils/calendar_utils.dart';
import 'calendar_event.dart';

part 'calendar_state.dart';

/// Business Logic Component for managing calendar state.
///
/// This BLoC handles all calendar business logic including:
/// - Month navigation (previous/next)
/// - Date selection (single and range)
/// - Week generation for current, previous, and next months
/// - Date validation and selectability checks
/// - State updates and emissions
///
/// Uses the BLoC pattern to separate business logic from UI,
/// making the code more testable and maintainable.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  /// CONFIGURATION
  ///
  /// Immutable configuration containing all calendar settings.
  final CalendarConfig _config;

  /// CALENDAR SERVICE
  ///
  /// Service responsible for building calendar week structures.
  final CalendarWeeksBuilder _calendarService;

  /// CONSTRUCTOR
  ///
  /// Initializes the BLoC with configuration and services, setting
  /// the initial state with the provided or current month.
  CalendarBloc({
    required CalendarConfig config,
    required CalendarWeeksBuilder calendarService,
    DateTime? initialMonth,
  }) : _config = config,
       _calendarService = calendarService,
       super(CalendarInitial(initialMonth)) {
    /// EVENT HANDLER REGISTRATION
    ///
    /// Uses pattern matching to route events to their handlers.
    /// This provides type-safe exhaustive event handling.
    on<CalendarEvent>((event, emit) async {
      await switch (event) {
        CalendarStarted() => _onStarted(event, emit),
        CalendarDateSelected() => _onDateSelected(event, emit),
        CalendarPreviousMonthPressed() => _onGoToPreviousMonth(event, emit),
        CalendarNextMonthPressed() => _onGoToNextMonth(event, emit),
        CalendarFirstDaySelected() => _onFirstDaySelected(event, emit),
        CalendarLastDaySelected() => _onLastDaySelected(event, emit),
        CalendarRangeDaySelected() => _onRangeDaySelected(event, emit),
        CalendarDayChanged() => _onDaySelected(event, emit),
        CalendarMonthChanged() => _onMonthChanged(event, emit),
      };
    });
  }

  /// ON STARTED EVENT HANDLER
  ///
  /// Handles the initial calendar setup when [CalendarStarted] is dispatched.
  ///
  /// Performs the following operations:
  /// 1. Generates weeks for the displayed month
  /// 2. Calculates the starting date based on first day of week config
  /// 3. Generates the week day labels row
  /// 4. Pre-generates weeks for previous and next months (for swipe)
  /// 5. Emits the initial success state
  FutureOr<void> _onStarted(
    CalendarStarted event,
    Emitter<CalendarState> emit,
  ) async {
    final displayedMonth = state.data.month;

    /// GENERATE WEEKS FOR CURRENT MONTH
    final weeks = _calendarService.call(
      year: displayedMonth.year,
      month: displayedMonth.month,
      config: _config,
    );

    /// CALCULATE STARTING DATE FOR DISPLAY
    ///
    /// Adjusts to show the correct starting day based on
    /// firstDayOfWeek configuration.
    DateTime displayedDate = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final int targetWeekday = _config.firstDayOfWeek.index + 1;

    while (displayedDate.weekday != targetWeekday) {
      displayedDate = displayedDate.subtract(const Duration(days: 1));
    }

    /// GENERATE WEEK DAY LABELS
    ///
    /// Creates a list of dates representing one week starting
    /// from the configured first day of week.
    final List<DateTime> weekDays = [];
    final int dayPosition = _config.firstDayOfWeek.index + 1;
    DateTime tempDate = DateTime.utc(2026, 1, 4);

    final int offset = (dayPosition - tempDate.weekday + 7) % 7;
    tempDate = tempDate.add(Duration(days: offset));

    for (int i = 0; i < 7; i++) {
      weekDays.add(tempDate.add(Duration(days: i)));
    }

    /// GENERATE PREVIOUS MONTH WEEKS
    final prevMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month - 1,
    );
    final prevWeeks = _calendarService.call(
      year: prevMonth.year,
      month: prevMonth.month,
      config: _config,
    );

    /// GENERATE NEXT MONTH WEEKS
    final nextMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
    );
    final nextWeeks = _calendarService.call(
      year: nextMonth.year,
      month: nextMonth.month,
      config: _config,
    );

    /// EMIT SUCCESS STATE
    emit(
      CalendarSuccess(
        data: state.data.copyWith(
          month: displayedMonth,
          weeks: weeks,
          weekDays: weekDays,
          nextWeeks: nextWeeks,
          prevWeeks: prevWeeks,
          selectedDate: DateTime.now(),
        ),
      ),
    );
  }

  /// ON DATE SELECTED EVENT HANDLER
  ///
  /// Routes date selection to appropriate handler based on selection mode.
  ///
  /// If range selection is enabled, dispatches [CalendarRangeDaySelected].
  /// Otherwise, dispatches [CalendarDayChanged] for single selection.
  FutureOr<void> _onDateSelected(
    CalendarDateSelected event,
    Emitter<CalendarState> emit,
  ) async {
    if (_config.mustActivateDateRanges) {
      add(CalendarRangeDaySelected(day: event.selectedDate));
    } else {
      add(CalendarDayChanged(selectedDate: event.selectedDate));
    }
  }

  /// ON GO TO PREVIOUS MONTH EVENT HANDLER
  ///
  /// Handles navigation to the previous month when the left arrow is pressed.
  ///
  /// Validates that:
  /// - Navigation doesn't go beyond minDate boundary
  /// - Current month is not before minDate
  ///
  /// Then:
  /// 1. Calculates the new month
  /// 2. Generates weeks for new current, previous, and next months
  /// 3. Emits updated state
  FutureOr<void> _onGoToPreviousMonth(
    CalendarPreviousMonthPressed event,
    Emitter<CalendarState> emit,
  ) async {
    final currentMonth = DateTime(
      state.data.month.year,
      state.data.month.month,
    );

    /// VALIDATE MIN DATE BOUNDARY
    if (event.minDate != null) {
      final minMonth = DateTime(
        event.minDate!.year,
        event.minDate!.month,
      );

      /// Already at minimum month
      if (currentMonth.year == minMonth.year && currentMonth.month == minMonth.month) {
        return;
      }

      /// Before minimum month
      if (currentMonth.isBefore(minMonth)) {
        return;
      }
    }

    /// CALCULATE NEW MONTH
    final newMonth = DateTime(
      state.data.month.year,
      state.data.month.month - 1,
    );

    /// GENERATE WEEKS FOR NEW MONTH
    final weeks = _calendarService.call(
      year: newMonth.year,
      month: newMonth.month,
      config: _config,
    );

    /// GENERATE ADJACENT MONTHS WEEKS
    final prevMonth = DateTime(newMonth.year, newMonth.month - 1);
    final nextMonth = DateTime(newMonth.year, newMonth.month + 1);

    final prevWeeks = _calendarService.call(
      year: prevMonth.year,
      month: prevMonth.month,
      config: _config,
    );

    final nextWeeks = _calendarService.call(
      year: nextMonth.year,
      month: nextMonth.month,
      config: _config,
    );

    /// EMIT UPDATED STATE
    emit(
      CalendarSuccess(
        data: state.data.copyWith(
          month: newMonth,
          weeks: weeks,
          prevWeeks: prevWeeks,
          nextWeeks: nextWeeks,
        ),
      ),
    );
  }

  /// ON GO TO NEXT MONTH EVENT HANDLER
  ///
  /// Handles navigation to the next month when the right arrow is pressed.
  ///
  /// Similar to previous month handler but validates against maxDate boundary.
  FutureOr<void> _onGoToNextMonth(
    CalendarNextMonthPressed event,
    Emitter<CalendarState> emit,
  ) async {
    /// VALIDATE MAX DATE BOUNDARY
    if (event.maxDate != null) {
      final currentMonth = DateTime(
        state.data.month.year,
        state.data.month.month,
      );
      final maxMonth = DateTime(
        event.maxDate!.year,
        event.maxDate!.month,
      );

      /// Already at maximum month
      if (currentMonth.year == maxMonth.year && currentMonth.month == maxMonth.month) {
        return;
      }

      /// After maximum month
      if (currentMonth.isAfter(maxMonth)) {
        return;
      }
    }

    /// CALCULATE NEW MONTH
    final newMonth = DateTime(
      state.data.month.year,
      state.data.month.month + 1,
    );

    /// GENERATE WEEKS FOR NEW MONTH
    final weeks = _calendarService.call(
      year: newMonth.year,
      month: newMonth.month,
      config: _config,
    );

    /// GENERATE ADJACENT MONTHS WEEKS
    final prevMonth = DateTime(newMonth.year, newMonth.month - 1);
    final nextMonth = DateTime(newMonth.year, newMonth.month + 1);

    final prevWeeks = _calendarService.call(
      year: prevMonth.year,
      month: prevMonth.month,
      config: _config,
    );

    final nextWeeks = _calendarService.call(
      year: nextMonth.year,
      month: nextMonth.month,
      config: _config,
    );

    /// EMIT UPDATED STATE
    emit(
      CalendarSuccess(
        data: state.data.copyWith(
          month: newMonth,
          weeks: weeks,
          prevWeeks: prevWeeks,
          nextWeeks: nextWeeks,
        ),
      ),
    );
  }

  /// ON FIRST DAY SELECTED EVENT HANDLER
  ///
  /// Handles selection of the first day in a date range.
  ///
  /// If a first day already exists, sets mustReload flag to clear
  /// the last day, effectively starting a new range selection.
  FutureOr<void> _onFirstDaySelected(
    CalendarFirstDaySelected event,
    Emitter<CalendarState> emit,
  ) async {
    if (state.data.firstDay != null) {
      emit(
        CalendarSuccess(
          data: state.data.copyWith(
            firstDay: event.firstDay,
            mustReload: true,
          ),
        ),
      );
    }
    emit(
      CalendarSuccess(
        data: state.data.copyWith(firstDay: event.firstDay),
      ),
    );
  }

  /// ON LAST DAY SELECTED EVENT HANDLER
  ///
  /// Handles selection of the last day in a date range.
  /// Completes the range selection started with firstDay.
  FutureOr<void> _onLastDaySelected(
    CalendarLastDaySelected event,
    Emitter<CalendarState> emit,
  ) async {
    emit(
      CalendarSuccess(
        data: state.data.copyWith(lastDay: event.lastDay),
      ),
    );
  }

  /// ON RANGE DAY SELECTED EVENT HANDLER
  ///
  /// Handles the complex logic of range date selection.
  ///
  /// Decision tree:
  /// 1. If no firstDay: Set the selected day as firstDay
  /// 2. If no lastDay and selected day is before firstDay:
  ///    Swap them (selected becomes firstDay, old firstDay becomes lastDay)
  /// 3. If no lastDay and selected day is after firstDay:
  ///    Set it as lastDay (complete the range)
  /// 4. If both exist: Start a new range with selected day as firstDay
  FutureOr<void> _onRangeDaySelected(
    CalendarRangeDaySelected event,
    Emitter<CalendarState> emit,
  ) async {
    /// NO FIRST DAY YET - START NEW RANGE
    if (state.data.firstDay == null) {
      add(CalendarFirstDaySelected(firstDay: event.day));
    }
    /// SELECTED DAY IS BEFORE FIRST DAY - SWAP THEM
    else if (state.data.lastDay == null && event.day.date.isBefore(state.data.firstDay!.date)) {
      emit(
        CalendarSuccess(
          data: state.data.copyWith(
            firstDay: event.day,
            lastDay: state.data.firstDay,
          ),
        ),
      );
    }
    /// SELECTED DAY IS AFTER FIRST DAY - COMPLETE RANGE
    else if (state.data.lastDay == null && event.day.date.isAfter(state.data.firstDay!.date)) {
      add(CalendarLastDaySelected(lastDay: event.day));
    }
    /// RANGE ALREADY COMPLETE - START NEW RANGE
    else {
      add(CalendarFirstDaySelected(firstDay: event.day));
    }
  }

  /// ON DAY SELECTED EVENT HANDLER
  ///
  /// Handles single date selection (non-range mode).
  ///
  /// Validates the date is selectable before updating the state.
  Future<void> _onDaySelected(
    CalendarDayChanged event,
    Emitter<CalendarState> emit,
  ) async {
    /// VALIDATE DATE SELECTABILITY
    if (!CalendarUtils.isDateSelectable(
      day: event.selectedDate,
      config: _config,
    )) {
      return;
    }

    /// UPDATE SELECTED DATE
    emit(
      CalendarSuccess(
        data: state.data.copyWith(
          selectedDate: event.selectedDate.date,
        ),
      ),
    );
  }

  /// ON MONTH CHANGED EVENT HANDLER
  ///
  /// Handles direct navigation to a specific month selected from the picker.
  ///
  /// This is similar to next/previous month navigation but jumps directly
  /// to the selected month rather than incrementing/decrementing.
  FutureOr<void> _onMonthChanged(
    CalendarMonthChanged event,
    Emitter<CalendarState> emit,
  ) async {
    final newMonth = DateTime(
      event.selectedMonth.year,
      event.selectedMonth.month,
    );

    /// GENERATE WEEKS FOR SELECTED MONTH
    final weeks = _calendarService.call(
      year: newMonth.year,
      month: newMonth.month,
      config: _config,
    );

    /// GENERATE ADJACENT MONTHS WEEKS
    final prevMonth = DateTime(newMonth.year, newMonth.month - 1);
    final nextMonth = DateTime(newMonth.year, newMonth.month + 1);

    final prevWeeks = _calendarService.call(
      year: prevMonth.year,
      month: prevMonth.month,
      config: _config,
    );

    final nextWeeks = _calendarService.call(
      year: nextMonth.year,
      month: nextMonth.month,
      config: _config,
    );

    /// EMIT UPDATED STATE
    emit(
      CalendarSuccess(
        data: state.data.copyWith(
          month: newMonth,
          weeks: weeks,
          prevWeeks: prevWeeks,
          nextWeeks: nextWeeks,
        ),
      ),
    );
  }
}
