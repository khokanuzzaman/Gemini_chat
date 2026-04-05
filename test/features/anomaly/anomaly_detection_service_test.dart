import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/anomaly/data/services/anomaly_detection_service.dart';
import 'package:gemini_chat/features/anomaly/domain/entities/anomaly_alert.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  const service = AnomalyDetectionService();

  test('detect identifies category spike using previous 90 day baseline', () {
    final previous90 = List.generate(
      12,
      (index) => _expense(
        amount: 500,
        category: 'Food',
        daysAgo: 40 + (index * 5),
      ),
    );
    final last30 = List.generate(
      10,
      (index) => _expense(
        amount: 500,
        category: 'Food',
        daysAgo: 1 + index,
      ),
    );

    final alerts = service.detect(
      last30Days: last30,
      previous90Days: previous90,
    );

    final alert = alerts.firstWhere(
      (item) => item.type == AnomalyType.categorySpike,
    );
    expect(alert.category, 'Food');
    expect(alert.severity, AnomalySeverity.medium);
    expect(alert.ratio, closeTo(2.5, 0.01));
  });

  test('detect identifies large single transaction outlier', () {
    final last30 = [
      for (var index = 0; index < 10; index++)
        _expense(amount: 200, category: 'Food', daysAgo: index + 2),
      _expense(
        amount: 2000,
        category: 'Shopping',
        description: 'ফোন',
        daysAgo: 1,
      ),
    ];

    final alerts = service.detect(last30Days: last30, previous90Days: const []);

    final alert = alerts.firstWhere(
      (item) => item.type == AnomalyType.largeTransaction,
    );
    expect(alert.category, 'Shopping');
    expect(alert.currentAmount, 2000);
    expect(alert.relatedDate, isNotNull);
  });

  test('detect identifies daily spike when one day is much higher', () {
    final last30 = [
      for (var index = 0; index < 20; index++)
        _expense(amount: 200, category: 'Food', daysAgo: index + 2),
      for (var index = 0; index < 3; index++)
        _expense(amount: 400, category: 'Food', daysAgo: 1),
    ];

    final alerts = service.detect(last30Days: last30, previous90Days: const []);

    final alert = alerts.firstWhere(
      (item) => item.type == AnomalyType.dailySpike,
    );
    expect(alert.severity, AnomalySeverity.high);
    expect(alert.relatedDate, isNotNull);
  });

  test('detect identifies frequency increase against previous 30 days', () {
    final last30 = List.generate(
      20,
      (index) => _expense(amount: 120, category: 'Transport', daysAgo: index),
    );
    final previous90 = List.generate(
      8,
      (index) => _expense(
        amount: 120,
        category: 'Transport',
        daysAgo: 35 + index,
      ),
    );

    final alerts = service.detect(
      last30Days: last30,
      previous90Days: previous90,
    );

    final alert = alerts.firstWhere(
      (item) => item.type == AnomalyType.frequencyIncrease,
    );
    expect(alert.severity, AnomalySeverity.low);
    expect(alert.currentAmount, 20);
    expect(alert.normalAmount, 8);
  });

  test('detect returns empty list for normal spending patterns', () {
    final previous90 = List.generate(
      18,
      (index) => _expense(
        amount: 250,
        category: 'Food',
        daysAgo: 35 + (index * 3),
      ),
    );
    final last30 = List.generate(
      8,
      (index) => _expense(
        amount: 280,
        category: 'Food',
        daysAgo: index + 1,
      ),
    );

    final alerts = service.detect(
      last30Days: last30,
      previous90Days: previous90,
    );

    expect(alerts, isEmpty);
  });
}

ExpenseEntity _expense({
  required double amount,
  required String category,
  required int daysAgo,
  String? description,
}) {
  return ExpenseEntity(
    amount: amount,
    category: category,
    description: description ?? category,
    date: DateTime.now().subtract(Duration(days: daysAgo)),
  );
}
