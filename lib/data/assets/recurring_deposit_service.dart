import 'package:drift/drift.dart';

import '../../database/app_database.dart';

const recurringDepositType = 'recurring_deposit';
const fixedDepositInterestType = 'fixed_deposit_interest';
const recurringDepositAutoPostSource = 'auto_recurring_deposit';
const fixedDepositInterestAutoPostSource = 'auto_fixed_deposit_interest';

Future<int> applyDueDepositTransactions(AppDatabase db,
    {DateTime? today}) async {
  final now = today ?? DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final schedules = await (db.select(db.recurringTransactions)
        ..where((t) =>
            t.recurringType
                .isIn([recurringDepositType, fixedDepositInterestType]) &
            t.status.equals('active')))
      .get();
  var posted = 0;

  for (final listedSchedule in schedules) {
    await db.transaction(() async {
      final schedule =
          await db.recurringTransactionsDao.getScheduleById(listedSchedule.id);
      if (schedule == null || schedule.status != 'active') return;

      final maturityDate = schedule.endDate == null
          ? null
          : DateTime(schedule.endDate!.year, schedule.endDate!.month,
              schedule.endDate!.day);
      var due = schedule.nextDueDate;
      var lastProcessed = schedule.lastProcessedDate;
      var status = schedule.status;
      final paysInterest = schedule.recurringType == fixedDepositInterestType;
      final intervalMonths =
          paysInterest ? await _itemCompoundingMonths(schedule, db) ?? 1 : 1;

      while (due != null &&
          !due.isAfter(day) &&
          (maturityDate == null ||
              (paysInterest
                  ? !due.isAfter(maturityDate)
                  : due.isBefore(maturityDate)))) {
        final dueDay = DateTime(due.year, due.month, due.day);
        if (lastProcessed != null && !dueDay.isAfter(lastProcessed)) {
          due =
              _nextScheduledDate(dueDay, schedule.scheduledDay, intervalMonths);
          continue;
        }

        final itemId = schedule.financialItemId;
        final item = itemId == null
            ? null
            : await db.financialItemsDao.getItemById(itemId);
        if (item == null || item.status != 'active') {
          status = 'cancelled';
          due = null;
          break;
        }

        if (paysInterest) {
          final interestPaise = _simpleInterestPaise(
            principalPaise: item.initialValuePaise,
            rateBasisPoints: item.interestRateBasisPoints ?? 0,
            months: _monthsBetween(lastProcessed ?? schedule.startDate, dueDay),
          );
          if (interestPaise > 0) {
            await db.transactionsDao.insertTransaction(TransactionsCompanion(
              profileId: Value(schedule.profileId),
              transactionType: const Value('interest_received'),
              categoryId: Value(schedule.categoryId),
              financialItemId: Value(item.id),
              transactionDate: Value(dueDay),
              amountPaise: Value(interestPaise),
              netAmountPaise: Value(interestPaise),
              source: const Value(fixedDepositInterestAutoPostSource),
              notes: Value('FD interest · ${item.name}'),
            ));
            posted++;
          }
        } else {
          await db.transactionsDao.insertTransaction(TransactionsCompanion(
            profileId: Value(schedule.profileId),
            transactionType: const Value('investment_purchase'),
            categoryId: Value(schedule.categoryId),
            financialItemId: Value(item.id),
            transactionDate: Value(dueDay),
            amountPaise: Value(schedule.amountPaise),
            netAmountPaise: Value(schedule.amountPaise),
            source: const Value(recurringDepositAutoPostSource),
            notes: Value('RD installment · ${item.name}'),
          ));
          await db.financialItemsDao.updateItem(item.copyWith(
            initialValuePaise: item.initialValuePaise + schedule.amountPaise,
            currentValuationPaise:
                item.currentValuationPaise + schedule.amountPaise,
            updatedAt: DateTime.now().toUtc(),
          ));
          posted++;
        }

        lastProcessed = dueDay;
        final nextDue =
            _nextScheduledDate(dueDay, schedule.scheduledDay, intervalMonths);
        due = paysInterest &&
                maturityDate != null &&
                nextDue.isAfter(maturityDate) &&
                dueDay.isBefore(maturityDate)
            ? maturityDate
            : nextDue;
      }

      if (maturityDate != null &&
          due != null &&
          (paysInterest
              ? due.isAfter(maturityDate)
              : !due.isBefore(maturityDate))) {
        status = 'completed';
        due = null;
      }
      await (db.update(db.recurringTransactions)
            ..where((t) => t.id.equals(schedule.id)))
          .write(RecurringTransactionsCompanion(
        lastProcessedDate: Value(lastProcessed),
        nextDueDate: Value(due),
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
    });
  }
  return posted;
}

DateTime _nextScheduledDate(DateTime date, int scheduledDay, int months) {
  final monthIndex = date.year * 12 + date.month - 1 + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, scheduledDay.clamp(1, lastDay));
}

int _monthsBetween(DateTime start, DateTime end) {
  final months = (end.year - start.year) * 12 + end.month - start.month;
  final startsAtMonthEnd =
      start.day == DateTime(start.year, start.month + 1, 0).day;
  final endsAtMonthEnd = end.day == DateTime(end.year, end.month + 1, 0).day;
  return end.day < start.day && !(startsAtMonthEnd && endsAtMonthEnd)
      ? months - 1
      : months;
}

int _simpleInterestPaise({
  required int principalPaise,
  required int rateBasisPoints,
  required int months,
}) {
  if (principalPaise <= 0 || rateBasisPoints <= 0 || months <= 0) return 0;
  final interest = BigInt.from(principalPaise) *
      BigInt.from(rateBasisPoints) *
      BigInt.from(months) ~/
      BigInt.from(120000);
  return interest > BigInt.from(1 << 62) ? 1 << 62 : interest.toInt();
}

Future<int?> _itemCompoundingMonths(
    RecurringTransaction schedule, AppDatabase db) async {
  final itemId = schedule.financialItemId;
  if (itemId == null) return null;
  return (await db.financialItemsDao.getItemById(itemId))
      ?.depositCompoundingMonths;
}
