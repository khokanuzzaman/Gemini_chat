import '../../../core/utils/bangla_formatters.dart';
import '../../obligations/domain/upcoming_obligation.dart';

/// How a hub status line should be drawn: [attention] is the one place the hub
/// uses the danger colour (over budget, overdue); everything else is quiet text.
enum StatusTone { normal, attention }

/// One line under a hub card's title ("৩টি সক্রিয় লক্ষ্য"). Pure data, so every
/// wording and every edge case is unit-tested without a widget.
class HubStatus {
  const HubStatus(this.text, {this.tone = StatusTone.normal});

  final String text;
  final StatusTone tone;

  @override
  bool operator ==(Object other) =>
      other is HubStatus && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);

  @override
  String toString() => 'HubStatus($text, $tone)';
}

/// Money with a NON-BREAKING space after the symbol, so a status line can never
/// wrap between "৳" and its number.
String _taka(num amount) =>
    BanglaFormatters.currency(amount).replaceAll(' ', '\u00A0');

/// বাজেট: "এই মাসে ৳X / ৳Y · Z%"; over budget → "৳N বেশি — বাজেট ছাড়িয়েছে".
///
/// [budgeted] is the active plan's total (null/<=0 = no plan). [spent] is this
/// month's spending — the SAME figure Home's budget row uses.
HubStatus budgetStatus({required double? budgeted, required double spent}) {
  if (budgeted == null || budgeted <= 0) {
    return const HubStatus('বাজেট ঠিক করুন');
  }
  if (spent > budgeted) {
    return HubStatus(
      '${_taka(spent - budgeted)} বেশি — বাজেট ছাড়িয়েছে',
      tone: StatusTone.attention,
    );
  }
  final percent = (spent / budgeted * 100).floor();
  return HubStatus(
    'এই মাসে ${_taka(spent)} / ${_taka(budgeted)} · ${BanglaFormatters.count(percent)}%',
  );
}

/// লক্ষ্য: "৩টি সক্রিয় লক্ষ্য" (the spec's own example).
HubStatus goalsStatus({required int active}) {
  if (active <= 0) {
    return const HubStatus('প্রথম লক্ষ্য ঠিক করুন');
  }
  return HubStatus('${BanglaFormatters.count(active)}টি সক্রিয় লক্ষ্য');
}

/// দেনা-পাওনা: overdue first (attention), else what I owe / am owed.
HubStatus debtStatus({
  required int active,
  required int overdue,
  required double iOwe,
  required double owedToMe,
}) {
  if (active <= 0) {
    return const HubStatus('কোনো ঋণ নেই');
  }
  if (overdue > 0) {
    return HubStatus(
      '${BanglaFormatters.count(overdue)}টি মেয়াদ পেরিয়েছে',
      tone: StatusTone.attention,
    );
  }
  final parts = <String>[
    if (iOwe > 0) 'আমি দেব ${_taka(iOwe)}',
    if (owedToMe > 0) 'পাব ${_taka(owedToMe)}',
  ];
  if (parts.isEmpty) {
    return HubStatus('${BanglaFormatters.count(active)}টি সক্রিয়');
  }
  return HubStatus(parts.join(' · '));
}

/// নিয়মিত খরচ: "৩টি নিয়মিত · পরেরটি: বাড়িভাড়া ১৬ অক্টোবর". [next] is the soonest
/// RECURRING obligation (from the upcoming list, never the stale stored date).
HubStatus recurringStatus({required int active, UpcomingObligation? next}) {
  if (active <= 0) {
    return const HubStatus('কিছু চিহ্নিত নেই');
  }
  final base = '${BanglaFormatters.count(active)}টি নিয়মিত';
  if (next == null) {
    return HubStatus(base);
  }
  return HubStatus(
    '$base · পরেরটি: ${next.title} ${BanglaFormatters.dayMonthLong(next.dueDate)}',
  );
}

/// The strip above the cards: "আগামী ৩০ দিনে ৩টি পরিশোধ · ৳X". Null when there is
/// nothing coming (the strip is then not drawn at all).
HubStatus? upcomingStripStatus(UpcomingObligations upcoming) {
  if (upcoming.isEmpty) {
    return null;
  }
  final overdue = upcoming.overdueCount;
  final head =
      'আগামী ৩০ দিনে ${BanglaFormatters.count(upcoming.count)}টি পরিশোধ · ${_taka(upcoming.totalAmount)}';
  if (overdue > 0) {
    return HubStatus(
      '$head · ${BanglaFormatters.count(overdue)}টি মেয়াদ পেরিয়েছে',
      tone: StatusTone.attention,
    );
  }
  return HubStatus(head);
}

/// আরও → SMS আমদানি.
HubStatus smsHubStatus({required bool enabled, required int pending}) {
  if (pending > 0) {
    return HubStatus(
      '${BanglaFormatters.count(pending)}টি লেনদেন নিশ্চিতের অপেক্ষায়',
    );
  }
  if (enabled) {
    return const HubStatus('চালু আছে — নতুন SMS এলে ধরা হবে');
  }
  return const HubStatus('চালু করুন — bKash, নগদ ও ব্যাংকের SMS থেকে খরচ ধরুন');
}
