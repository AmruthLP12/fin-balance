import 'dart:math' as math;

typedef DepositEstimate = ({
  int contributionsPaise,
  int interestPaise,
  int maturityPaise,
});

DepositEstimate estimateDeposit({
  required double installmentRupees,
  required int rateBasisPoints,
  required num tenureMonths, // fractional when entered in days
  required int compoundingMonths,
  required bool recurring,
  required bool cumulative,
}) {
  if (!installmentRupees.isFinite ||
      installmentRupees <= 0 ||
      tenureMonths <= 0 ||
      compoundingMonths <= 0) {
    return (
      contributionsPaise: 0,
      interestPaise: 0,
      maturityPaise: 0,
    );
  }

  final annualRate = math.max(0, rateBasisPoints) / 10000;
  final periodRate = annualRate * compoundingMonths / 12;
  final monthsContributed = recurring ? tenureMonths : 1;
  final contributionsPaise = _toPaise(installmentRupees * monthsContributed);
  double maturityRupees;

  if (recurring) {
    maturityRupees = 0;
    for (var month = 0; month < tenureMonths; month++) {
      maturityRupees += installmentRupees *
          math.pow(1 + periodRate, (tenureMonths - month) / compoundingMonths);
    }
  } else if (cumulative) {
    maturityRupees = installmentRupees *
        math.pow(1 + periodRate, tenureMonths / compoundingMonths);
  } else {
    maturityRupees = installmentRupees * (1 + annualRate * tenureMonths / 12);
  }

  final maturityPaise = _toPaise(maturityRupees);
  return (
    contributionsPaise: contributionsPaise,
    interestPaise:
        (maturityPaise - contributionsPaise).clamp(0, 1 << 62).toInt(),
    maturityPaise: maturityPaise,
  );
}

int _toPaise(double rupees) {
  final paise = rupees * 100;
  if (!paise.isFinite || paise >= (1 << 62)) return 1 << 62;
  return paise.round();
}

/// [date] plus [months], clamping the day (31 Jan + 1 month = 28/29 Feb).
DateTime addMonthsClamped(DateTime date, int months) {
  final totalMonths = date.year * 12 + date.month - 1 + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(date.day, lastDay));
}

/// Days between start and maturity when the deposit was entered in days (its
/// maturity is not a whole number of months after the start); otherwise null.
int? depositTenureDays(DateTime? start, DateTime? maturity, int? tenureMonths) {
  if (start == null || maturity == null || (tenureMonths ?? 0) <= 0) {
    return null;
  }
  final s = DateTime(start.year, start.month, start.day);
  final m = DateTime(maturity.year, maturity.month, maturity.day);
  if (addMonthsClamped(s, tenureMonths!) == m) return null;
  return DateTime.utc(m.year, m.month, m.day)
      .difference(DateTime.utc(s.year, s.month, s.day))
      .inDays;
}

/// Months used to estimate interest for a tenure entered in days.
double monthsFromDays(int days) => days / 30.4375;
