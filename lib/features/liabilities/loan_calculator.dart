import 'dart:math' as math;
import '../../database/app_database.dart';

class LoanCalculator {
  LoanCalculator._();

  static DateTime? maturityDate(FinancialItem loan) {
    final start = loan.startDate;
    if (start == null) return null;
    return DateTime(
      start.year + (loan.tenureYears ?? 0),
      start.month + (loan.tenureMonths ?? 0),
      start.day + (loan.tenureDays ?? 0),
    );
  }

  static bool termEnded(FinancialItem loan, {DateTime? today}) {
    final maturity = maturityDate(loan);
    return maturity != null && !(today ?? DateTime.now()).isBefore(maturity);
  }

  static int remainingMonths(FinancialItem loan, {DateTime? today}) {
    final maturity = maturityDate(loan);
    final now = today ?? DateTime.now();
    if (maturity == null || !now.isBefore(maturity)) return 0;
    var months = (maturity.year - now.year) * 12 + maturity.month - now.month;
    if (maturity.day < now.day) months--;
    return months.clamp(0, 1200);
  }

  /// Closed by the user, or nothing left to pay.
  static bool isClosed(FinancialItem loan) =>
      loan.status == 'closed' || loan.currentValuationPaise <= 0;

  /// Still owed: active with a remaining balance (even after the term ended).
  static bool isOngoing(FinancialItem loan) => !isClosed(loan);

  /// 'Closed' only when nothing is owed. A loan whose term is over but still
  /// has a balance stays on the books as 'Term ended' with its remaining amount.
  static String status(FinancialItem loan) {
    if (isClosed(loan)) return 'Closed';
    if (termEnded(loan)) return 'Term ended';
    return 'Ongoing';
  }

  /// Monthly instalment (paise) for a reducing-balance loan.
  static int emiFor(int principalPaise, double annualRatePct, int months) {
    if (principalPaise <= 0 || months <= 0) return 0;
    final r = annualRatePct / 1200;
    if (r == 0) return (principalPaise / months).round();
    final f = math.pow(1 + r, months);
    return (principalPaise * r * f / (f - 1)).round();
  }

  /// Months needed to clear [principalPaise] with [emiPaise]; null if the EMI
  /// does not even cover the monthly interest.
  static int? tenureMonthsFor(
      int principalPaise, double annualRatePct, int emiPaise) {
    if (principalPaise <= 0 || emiPaise <= 0) return null;
    final r = annualRatePct / 1200;
    if (r == 0) return (principalPaise / emiPaise).ceil();
    final x = 1 - principalPaise * r / emiPaise;
    if (x <= 0) return null;
    return (-math.log(x) / math.log(1 + r) - 0.05).ceil(); // EMI is rounded to paise
  }

  /// Other borrowings are repaid manually; real loans auto-deduct their EMI.
  static bool autoDeducts(FinancialItem loan) =>
      loan.subType != 'other_liability' &&
      loan.status == 'active' &&
      (loan.emiPaise ?? 0) > 0 &&
      loan.startDate != null;

  /// EMI due dates on the start day of each month that fall after the loan
  /// was recorded here (earlier ones are already in the entered balance), up
  /// to [today] and the end of the term.
  static List<DateTime> emiDueDates(FinancialItem loan, DateTime today) {
    final start = loan.startDate;
    if (start == null) return const [];
    final end = maturityDate(loan);
    final recorded =
        DateTime(loan.createdAt.year, loan.createdAt.month, loan.createdAt.day);
    final dates = <DateTime>[];
    for (var k = 1; k < 1200; k++) {
      final first = DateTime(start.year, start.month + k, 1);
      final lastDay = DateTime(first.year, first.month + 1, 0).day;
      final d = DateTime(first.year, first.month, math.min(start.day, lastDay));
      if (d.isAfter(today) || (end != null && d.isAfter(end))) break;
      if (d.isAfter(recorded)) dates.add(d);
    }
    return dates;
  }
}
