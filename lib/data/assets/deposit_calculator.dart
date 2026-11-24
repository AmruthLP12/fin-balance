import 'dart:math' as math;

typedef DepositEstimate = ({
  int contributionsPaise,
  int interestPaise,
  int maturityPaise,
});

DepositEstimate estimateDeposit({
  required double installmentRupees,
  required int rateBasisPoints,
  required int tenureMonths,
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
