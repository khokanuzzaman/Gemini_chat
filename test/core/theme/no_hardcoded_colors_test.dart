import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: screens consume design tokens, never colour literals.
///
/// Counts hard-coded `Color(0x…)` and palette `Colors.<name>` uses (everything
/// except white / black / transparent) in `lib/`, excluding `lib/core/theme/`
/// (where the tokens live) and generated code.
///
/// `_allowed` is the debt as of R0a. It can only go DOWN:
/// - adding a literal anywhere (a new file, or more in an existing one) fails;
/// - cleaning a file up also fails until its allowance is lowered/removed, so
///   the number can never silently creep back up.
///
/// Known remaining debt: AI-chat widgets (Phase 2), domain-entity palette
/// colours, per-person split colours, and the category colour picker (a data
/// palette). Fix by moving each to `context.tokens` / a data palette.
const _allowed = <String, int>{
  'lib/features/chat/presentation/widgets/usage_details_sheet.dart': 27,
  'lib/features/sms_import/presentation/screens/sms_history_screen.dart': 19,
  'lib/features/category/presentation/widgets/add_edit_category_sheet.dart': 13,
  'lib/features/chat/presentation/widgets/multiple_income_confirmation_widget.dart':
      12,
  'lib/features/chat/presentation/widgets/rag/rag_comparison_widget.dart': 10,
  'lib/features/chat/presentation/widgets/multiple_expense_confirmation_widget.dart':
      9,
  'lib/features/split/presentation/utils/person_color.dart': 8,
  'lib/features/chat/presentation/widgets/income_confirmation_widget.dart': 6,
  'lib/features/debt/presentation/screens/debt_list_screen.dart': 6,
  'lib/features/prediction/domain/entities/prediction_entity.dart': 6,
  'lib/features/sms_import/presentation/screens/sms_import_screen.dart': 5,
  'lib/core/notifications/notification_service.dart': 3,
  'lib/features/anomaly/domain/entities/anomaly_alert.dart': 3,
  'lib/features/budget/domain/entities/budget_plan_entity.dart': 3,
  'lib/features/chat/presentation/widgets/expense_confirmation_widget.dart': 3,
  'lib/features/goals/domain/entities/goal_entity.dart': 3,
  'lib/features/chat/presentation/widgets/rag/rag_summary_widget.dart': 2,
  'lib/features/chat/presentation/widgets/receipt_confirmation_widget.dart': 1,
  'lib/features/split/presentation/screens/split_bill_screen.dart': 1,
};

final _literal = RegExp(
  r'Color\(0x[0-9A-Fa-f]{8}\)|(?<![A-Za-z0-9_])Colors\.(?!white\b|black\b|transparent\b)[a-zA-Z]+',
);

Map<String, int> _scan() {
  final found = <String, int>{};
  final root = Directory('lib');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final path = entity.path.replaceAll(r'\', '/');
    if (path.endsWith('.g.dart') || path.startsWith('lib/core/theme/')) {
      continue;
    }
    var count = 0;
    for (final line in entity.readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) {
        continue;
      }
      count += _literal.allMatches(line).length;
    }
    if (count > 0) found[path] = count;
  }
  return found;
}

void main() {
  final found = _scan();

  test('no new hard-coded colours outside the theme', () {
    final offenders = <String>[];
    found.forEach((path, count) {
      final allowed = _allowed[path] ?? 0;
      if (count > allowed) {
        offenders.add('$path: $count literal(s), allowed $allowed');
      }
    });
    expect(
      offenders,
      isEmpty,
      reason:
          'Use context.tokens (or AppColors for fills/icons) instead of colour '
          'literals:\n${offenders.join('\n')}',
    );
  });

  test('the allowlist only shrinks — lower it when you clean a file up', () {
    final stale = <String>[];
    _allowed.forEach((path, allowed) {
      final count = found[path] ?? 0;
      if (count < allowed) {
        stale.add('$path: now $count, allowlist says $allowed — lower it');
      }
    });
    expect(
      stale,
      isEmpty,
      reason:
          'Tighten the ratchet in no_hardcoded_colors_test.dart:\n'
          '${stale.join('\n')}',
    );
  });
}
