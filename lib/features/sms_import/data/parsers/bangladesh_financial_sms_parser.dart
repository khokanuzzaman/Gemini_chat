import '../../domain/entities/parsed_sms_transaction_entity.dart';
import '../../domain/entities/sms_message_entity.dart';
import 'bank_sms_parser.dart';
import 'bkash_sms_parser.dart';
import 'financial_sms_message_parser.dart';
import 'nagad_sms_parser.dart';
import 'rocket_sms_parser.dart';

class BangladeshFinancialSmsParser {
  BangladeshFinancialSmsParser({List<FinancialSmsMessageParser>? parsers})
    : _parsers =
          parsers ??
          const [
            BkashSmsParser(),
            NagadSmsParser(),
            RocketSmsParser(),
            BankSmsParser(),
          ];

  final List<FinancialSmsMessageParser> _parsers;

  ParsedSmsTransactionEntity? parseMessage(SmsMessageEntity message) {
    final normalizedBody = message.body.trim();
    if (normalizedBody.isEmpty) {
      return null;
    }

    for (final parser in _parsers) {
      if (!parser.canParse(message)) {
        continue;
      }

      final parsed = parser.parse(message);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  List<ParsedSmsTransactionEntity> parseMessages(
    Iterable<SmsMessageEntity> messages,
  ) {
    final parsed = messages
        .map(parseMessage)
        .whereType<ParsedSmsTransactionEntity>()
        .toList(growable: false);
    parsed.sort(
      (first, second) => second.occurredAt.compareTo(first.occurredAt),
    );
    return parsed;
  }
}
