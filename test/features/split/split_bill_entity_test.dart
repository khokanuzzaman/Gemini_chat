import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/split/domain/entities/split_bill_entity.dart';

void main() {
  test('equal split with one payer produces correct settlements', () {
    final split = SplitBillEntity(
      id: 1,
      title: 'Kacchi dinner',
      totalAmount: 1200,
      persons: const [
        SplitPerson(name: 'রহিম', amountPaid: 1200, shareAmount: 300),
        SplitPerson(name: 'করিম', amountPaid: 0, shareAmount: 300),
        SplitPerson(name: 'জামাল', amountPaid: 0, shareAmount: 300),
        SplitPerson(name: 'সেলিম', amountPaid: 0, shareAmount: 300),
      ],
      date: DateTime(2026, 4, 5),
      notes: null,
      isSettled: false,
      category: 'Food',
    );

    expect(split.perPersonShare, 300);
    expect(split.settlements, hasLength(3));
    expect(
      split.settlements
          .map(
            (settlement) =>
                '${settlement.from}->${settlement.to}:${settlement.amount}',
          )
          .toList(),
      ['করিম->রহিম:300.0', 'জামাল->রহিম:300.0', 'সেলিম->রহিম:300.0'],
    );
  });

  test('multiple payers produce minimal settlement suggestions', () {
    final split = SplitBillEntity(
      id: 2,
      title: 'Lunch',
      totalAmount: 1200,
      persons: const [
        SplitPerson(name: 'A', amountPaid: 600, shareAmount: 400),
        SplitPerson(name: 'B', amountPaid: 400, shareAmount: 400),
        SplitPerson(name: 'C', amountPaid: 200, shareAmount: 400),
      ],
      date: DateTime(2026, 4, 5),
      notes: null,
      isSettled: false,
      category: 'Food',
    );

    expect(split.settlements, hasLength(1));
    expect(split.settlements.single.from, 'C');
    expect(split.settlements.single.to, 'A');
    expect(split.settlements.single.amount, 200);
  });
}
