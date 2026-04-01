import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:gemini_chat/core/ai/rag_context_builder.dart';
import 'package:gemini_chat/core/database/expense_local_datasource.dart';

class _StubIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EmptyExpenseLocalDataSource extends ExpenseLocalDataSource {
  _EmptyExpenseLocalDataSource() : super(_StubIsar());
}

void main() {
  final builder = RagContextBuilder(
    localDataSource: _EmptyExpenseLocalDataSource(),
  );

  test('needsData returns true for monthly summary question', () {
    expect(builder.needsData('এই মাসে কত?'), isTrue);
  });

  test('needsData returns false for casual greeting', () {
    expect(builder.needsData('হ্যালো'), isFalse);
  });

  test('needsData returns true for category question', () {
    expect(builder.needsData('Food এ কত গেছে?'), isTrue);
  });

  test('needsData returns false for unrelated tech question', () {
    expect(builder.needsData('Flutter কী?'), isFalse);
  });
}
