import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:gemini_chat/core/export/csv_export_service.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';

void main() {
  late PathProviderPlatform originalPathProvider;
  late Directory tempDirectory;

  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    tempDirectory = Directory.systemTemp.createTempSync(
      'pocketpilot_ai_csv_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      temporaryPath: tempDirectory.path,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('CsvExportService.generateFileName', () {
    const service = CsvExportService();

    test('returns single month file name when range is inside same month', () {
      final fileName = service.generateFileName(
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 28),
      );

      expect(fileName, 'PocketPilot_AI_Mar_2026');
    });

    test('returns month span file name when range crosses months', () {
      final fileName = service.generateFileName(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 3, 31),
      );

      expect(fileName, 'PocketPilot_AI_Jan_2026_to_Mar_2026');
    });
  });

  test('exportToCSV writes headers, rows, and summary', () async {
    const service = CsvExportService();
    final file = await service.exportToCSV(
      fileName: 'PocketPilot_AI_Test',
      expenses: [
        ExpenseEntity(
          id: 1,
          amount: 150,
          category: 'Food',
          description: 'দুপুরের খাবার',
          date: DateTime(2026, 3, 4),
        ),
        ExpenseEntity(
          id: 2,
          amount: 60,
          category: 'Transport',
          description: 'রিকশা',
          date: DateTime(2026, 3, 4),
          isManual: true,
        ),
      ],
    );

    final csvText = await file.readAsString();

    expect(csvText, contains('তারিখ,বিবরণ,Category,পরিমাণ (৳),Manual'));
    expect(csvText, contains('04/03/2026,দুপুরের খাবার,Food,150.00,না'));
    expect(csvText, contains('04/03/2026,রিকশা,Transport,60.00,হ্যাঁ'));
    expect(csvText, contains('মোট খরচ,,,210.00,'));
    expect(csvText, contains('মোট transactions,,,2,'));
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({required this.temporaryPath});

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}
