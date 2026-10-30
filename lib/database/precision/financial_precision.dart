/// Precision constants and conversion utilities for FinBalance.
///
/// Financial storage rules:
/// 1. Currency amounts: Stored as 64-bit integer minor units (Paise for INR, where 1 INR = 100 Paise).
///    This eliminates floating-point representation drift.
/// 2. Investment units: Stored as integer micro-units (1 Unit = 1,000,000 micro-units, 6 decimal places).
///    Mutual funds and stocks allot fractions up to 3-4 decimal places; 6 decimals covers all market precision.
/// 3. NAV / Unit price: Stored as integer micro-paise (1 Rupee = 100 Paise = 1,000,000 micro-paise, 4 decimal places of a Rupee).
///    Published AMFI NAV has 4 decimal places (e.g. ₹125.4560).
class FinancialPrecision {
  FinancialPrecision._();

  /// 1 Rupee = 100 Paise
  static const int paisePerRupee = 100;

  /// 1 Unit = 1,000,000 Micro-units (6 decimal places)
  static const int microUnitsPerUnit = 1000000;

  /// 1 Rupee = 100 Paise = 1,000,000 Micro-paise
  /// 1 NAV Rupee = 1,000,000 micro-paise (4 decimal places of INR)
  static const int microPaisePerRupee = 1000000;

  /// Convert standard Rupees (e.g. 5000.50) to integer Paise (500050).
  static int rupeesToPaise(double rupees) {
    return (rupees * paisePerRupee).round();
  }

  /// Convert integer Paise (500050) to standard Rupees (5000.50).
  static double paiseToRupees(int paise) {
    return paise / paisePerRupee;
  }

  /// Convert fractional units (e.g. 125.4567) to integer micro-units (125456700).
  static int unitsToMicroUnits(double units) {
    return (units * microUnitsPerUnit).round();
  }

  /// Convert integer micro-units (125456700) to fractional units (125.4567).
  static double microUnitsToUnits(int microUnits) {
    return microUnits / microUnitsPerUnit;
  }

  /// Convert standard NAV (e.g. 125.4560) to micro-paise (125456000).
  static int navToMicroPaise(double nav) {
    return (nav * microPaisePerRupee).round();
  }

  /// Parse a raw NAV decimal string (e.g. "200.18460", "15.2") directly into
  /// integer micro-paise (1 Rupee = 1,000,000 micro-paise) without floating-point representation errors.
  static int navStringToMicroPaise(String? navStr) {
    if (navStr == null) return 0;
    final clean = navStr.trim().replaceAll(',', '');
    if (clean.isEmpty) return 0;

    final parts = clean.split('.');
    final intPart = int.tryParse(parts[0]) ?? 0;
    if (parts.length == 1) {
      return intPart * microPaisePerRupee;
    }

    // Pad or trim fractional string to exactly 6 digits (micro-paise)
    var fracStr = parts[1];
    if (fracStr.length > 6) {
      fracStr = fracStr.substring(0, 6);
    } else {
      fracStr = fracStr.padRight(6, '0');
    }
    final fracPart = int.tryParse(fracStr) ?? 0;

    if (intPart < 0) {
      return intPart * microPaisePerRupee - fracPart;
    }
    return intPart * microPaisePerRupee + fracPart;
  }

  /// Convert integer micro-paise (125456000) to standard NAV (125.4560).
  static double microPaiseToNav(int microPaise) {
    return microPaise / microPaisePerRupee;
  }

  /// Calculate units purchased given an amount in Paise and NAV in micro-paise.
  ///
  /// Units in micro-units = (Amount in Paise * 10,000 * 1,000,000) / NAV in micro-paise
  /// Result is returned in micro-units.
  static int calculateUnitsPurchased({
    required int amountPaise,
    required int navMicroPaise,
  }) {
    if (navMicroPaise <= 0) return 0;
    // 1 Rupee = 100 Paise, 1 NAV Rupee = 1,000,000 micro-paise.
    // Factor = microPaisePerRupee / paisePerRupee = 1,000,000 / 100 = 10,000.
    final numerator = BigInt.from(amountPaise) *
        BigInt.from(microUnitsPerUnit) *
        BigInt.from(microPaisePerRupee ~/ paisePerRupee);
    final denominator = BigInt.from(navMicroPaise);
    return (numerator ~/ denominator).toInt();
  }

  /// Calculate valuation in Paise given unit count in micro-units and NAV in micro-paise.
  ///
  /// Value in Paise = (Units in micro-units * NAV in micro-paise) / (1,000,000 * 10,000)
  static int calculateValuationPaise({
    required int unitCountMicroUnits,
    required int navMicroPaise,
  }) {
    if (unitCountMicroUnits <= 0 || navMicroPaise <= 0) return 0;
    final product =
        BigInt.from(unitCountMicroUnits) * BigInt.from(navMicroPaise);
    // Divisor = microUnitsPerUnit * (microPaisePerRupee / paisePerRupee) = 1,000,000 * 10,000 = 10,000,000,000
    final divisor = BigInt.from(microUnitsPerUnit) *
        BigInt.from(microPaisePerRupee ~/ paisePerRupee);
    return (product ~/ divisor).toInt();
  }
}
