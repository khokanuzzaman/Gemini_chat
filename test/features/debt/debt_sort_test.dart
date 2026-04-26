import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';

void main() {
  test(
    'sortDebtsForDisplay prioritizes overdue, EMI, active, settled, cancelled',
    () {
      final now = DateTime(2026, 4, 28);
      final debts = [
        _debt(
          id: 5,
          status: DebtStatus.cancelled,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        _debt(
          id: 4,
          status: DebtStatus.settled,
          createdAt: now.subtract(const Duration(days: 2)),
          settledAt: now.subtract(const Duration(hours: 2)),
        ),
        _debt(
          id: 3,
          status: DebtStatus.active,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        _debt(
          id: 2,
          status: DebtStatus.active,
          createdAt: now.subtract(const Duration(days: 4)),
          isEMI: true,
          totalInstallments: 12,
          paidInstallments: 1,
          emiAmount: 200,
          installmentDayOfMonth: 20,
          nextInstallmentDate: now.add(const Duration(days: 2)),
        ),
        _debt(
          id: 1,
          status: DebtStatus.active,
          createdAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 1)),
        ),
      ];

      final sortedIds = sortDebtsForDisplay(
        debts,
      ).map((debt) => debt.id).toList();

      expect(sortedIds, [1, 2, 3, 4, 5]);
    },
  );
}

DebtEntity _debt({
  required int id,
  required DebtStatus status,
  required DateTime createdAt,
  DateTime? dueDate,
  DateTime? settledAt,
  bool isEMI = false,
  int totalInstallments = 0,
  int paidInstallments = 0,
  double emiAmount = 0,
  int? installmentDayOfMonth,
  DateTime? nextInstallmentDate,
}) {
  return DebtEntity(
    id: id,
    personName: 'Debt $id',
    type: DebtType.iOwe,
    originalAmount: 1000,
    remainingAmount: 500,
    status: status,
    createdAt: createdAt,
    dueDate: dueDate,
    settledAt: settledAt,
    isEMI: isEMI,
    totalInstallments: totalInstallments,
    paidInstallments: paidInstallments,
    emiAmount: emiAmount,
    installmentDayOfMonth: installmentDayOfMonth,
    nextInstallmentDate: nextInstallmentDate,
  );
}
