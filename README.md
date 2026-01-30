<p align="center">
<img src="https://raw.githubusercontent.com/rudoapps/hybrid-hub-vault/main/flutter/images/hybrid-calendar/banner.png" width="100%" alt="Banner">
</p>

A highly customizable and feature-rich Flutter calendar widget with support for date selection, range selection, swipe navigation, and extensive styling options.

## Features

- **Single Date Selection** - Select individual dates with ease
- **Date Range Selection** - Select start and end dates for ranges
- **Swipe Navigation** - Navigate between months with smooth swipe gestures
- **Customizable Styling** - Full control over colors, text styles, and sizing
- **Date Restrictions** - Set min/max selectable dates and navigable months
- **Disabled Dates** - Disable specific dates or days of the week
- **Adjacent Month Days** - Show or hide days from previous/next months
- **Localization Support** - Automatic localization based on device locale
- **Flexible Configuration** - Extensive configuration options for all use cases

## Quick Start

### Basic Usage With MinSelectableDate

<img src="https://raw.githubusercontent.com/rudoapps/hybrid-hub-vault/main/flutter/images/hybrid-calendar/Example2.png" width="100%" alt="Banner">

```dart

 HybridCalendar(
  config: CalendarConfig(
    disabledDaysOfWeek: {DayOfWeek.sunday},
    minSelectableDate: DateTime(2026, 2, 13),
  ),
  onDateSelected: (_) {},
),

```

### Date With Range Selection and Swipe, Without Header and Adjacent Month Days

<img src="https://raw.githubusercontent.com/rudoapps/hybrid-hub-vault/main/flutter/images/hybrid-calendar/Example4.png" width="100%" alt="Banner">

```dart
HybridCalendar(
  config: CalendarConfig(
    enableSwipe: true,
    firstDayOfWeek: DayOfWeek.friday,
    showAdjacentMonthDays: false,
    showHeader: false,
    mustActivateDateRanges: true,
  ),
  initialSelectedDate: DateTime(2026, 4),
  onDateSelected: (_) {},
)
```

### Dum Calendar

<img src="https://raw.githubusercontent.com/rudoapps/hybrid-hub-vault/main/flutter/images/hybrid-calendar/Example3.png" width="100%" alt="Banner">

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.blue.shade200, width: 5),
    borderRadius: BorderRadius.circular(20),
  ),
  child: HybridCalendar(
    config: CalendarConfig(
      mustActivateDateRanges: true,
      disabledDaysOfWeek: {DayOfWeek.sunday},
      disabledDates: {DateTime.now().subtract(const Duration(days: 7))},
      style: CalendarStyle(
        borderColor: Colors.transparent,
        selectedDateColor: Colors.lightBlue.shade800,
        disabledDateColor: Colors.lightBlue.shade100,
        arrowDisabledColor: Colors.amber,
        isInRangeDateColor: Colors.lightBlue.shade300,
        arrowLeftColor: Colors.blueGrey,
        arrowRightColor: Colors.cyan,

        selectedDateTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        disabledDateTextStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 20,
          fontStyle: FontStyle.italic,
        ),
        defaultDateTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        headerTextStyle: TextStyle(
          color: Colors.blue.shade600,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
          weekDayTextStyle: TextStyle(
          color: Colors.lightBlue.shade400,
          fontSize: 20,
        ),

        dayCellSize: 40,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(0),
      ),
    ),
    onDateSelected: (day) {
      debugPrint("Día seleccionado: ${day.date}");
    },
  ),
)
```

## Calendar Date Picker

<img src="https://raw.githubusercontent.com/rudoapps/hybrid-hub-vault/main/flutter/images/hybrid-calendar/Example5.png" width="100%" alt="Banner">

```dart
HybridCalendar(
  config: CalendarConfig(
    disabledDaysOfWeek: {DayOfWeek.sunday},
    minNavigableMonth: DateTime(2025, 11),
    maxNavigableMonth: DateTime(2026, 4),
    showYearPickerHeader: true
  ),
  onDateSelected: (_) {},
),
```

## Configuration Options

### CalendarConfig

```dart
CalendarConfig({
  // Navigation limits
  DateTime? minNavigableMonth,
  DateTime? maxNavigableMonth,

  // Selection limits
  DateTime? minSelectableDate,
  DateTime? maxSelectableDate,

  // Disabled dates
  Set<DateTime> disabledDates = const {},
  Set<DayOfWeek> disabledDaysOfWeek = const {},

  // Display options
  DayOfWeek firstDayOfWeek = DayOfWeek.monday,
  bool showAdjacentMonthDays = true,
  bool showHeader = true,
  bool showWeekDayLabels = true,

  // Features
  bool enableSwipe = false,
  bool mustActivateDateRanges = false,

  // Styling
  CalendarStyle style = const CalendarStyle(),
})
```

### CalendarStyle

```dart
CalendarStyle({
  // Colors
  Color borderColor = const Color(0xFFB9BBC6),
  Color selectedDateColor = const Color(0xFF1D1D1B),
  Color disabledDateColor = Colors.transparent,
  Color defaultDateColor = Colors.transparent,
  Color isInRangeDateColor = const Color.fromARGB(255, 204, 204, 207),
  Color arrowDisabledColor = Colors.grey,

  // Text Styles
  TextStyle selectedDateTextStyle = ...,
  TextStyle disabledDateTextStyle = ...,
  TextStyle defaultDateTextStyle = ...,
  TextStyle headerTextStyle = ...,
  TextStyle weekDayTextStyle = ...,

  // Icons
  IconData arrowLeftIcon = Icons.keyboard_arrow_left_outlined,
  IconData arrowRightIcon = Icons.keyboard_arrow_right_outlined,
  Color arrowLeftColor = Colors.black,
  Color arrowRightColor = Colors.black,
  double arrowSize = 24,

  // Sizing
  double dayCellSize = 38,
  double borderRadius = 15,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  EdgeInsets margin = const EdgeInsets.all(16),
})
```

### Date Restrictions

```dart
HybridCalendar(
  config: CalendarConfig(
    minSelectableDate: DateTime.now(),
    maxSelectableDate: DateTime.now().add(Duration(days: 90)),
    disabledDaysOfWeek: {DayOfWeek.saturday, DayOfWeek.sunday},
    disabledDates: {
      DateTime(2026, 2, 14), // Valentine's Day
      DateTime(2026, 12, 25), // Christmas
    },
  ),
  onDateSelected: (day) {
    print('Selected: ${day.date}');
  },
)
```

## Architecture

This package uses the BLoC (Business Logic Component) pattern for state management:

- **CalendarBloc**: Manages calendar state and handles events
- **CalendarEvent**: Defines all possible calendar interactions
- **CalendarState**: Represents the current state of the calendar
- **CalendarWeeksBuilder**: Service for generating calendar weeks

## Localization

The calendar automatically adapts to the device's locale for month and day names. Ensure you have `easy_localization` configured in your app:

```dart
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('es'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}
```

## Credits

Built with:

- [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [easy_localization](https://pub.dev/packages/easy_localization)

## Author ✒️

- **Daniela Perez Juan** - _Flutter Developer_ - [dperez@laberit.com](dperez@laberit.com)

---

With ❤️ by RudoApps Flutter Team 😊

![Rudo Apps](https://rudo.es/wp-content/uploads/logo-rudo.svg)
