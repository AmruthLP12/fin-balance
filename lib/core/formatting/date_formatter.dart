import 'package:intl/intl.dart';

/// Centralized date formatting for FinBalance.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _shortDate = DateFormat('dd MMM yyyy');
  static final DateFormat _navDate = DateFormat('dd-MM-yyyy');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(DateTime date) => _shortDate.format(date.toLocal());
  static String formatNavDate(DateTime date) => _navDate.format(date.toLocal());
  static String formatMonthYear(DateTime date) =>
      _monthYear.format(date.toLocal());
  static String formatDateTime(DateTime date) =>
      _dateTime.format(date.toLocal());
}
