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

  static String status(FinancialItem loan) {
    if (loan.currentValuationPaise <= 0) return 'Closed';
    if (termEnded(loan)) return 'Closed';
    return 'Active';
  }
}
