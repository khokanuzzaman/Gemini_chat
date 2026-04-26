import '../../domain/entities/parsed_sms_transaction_entity.dart';
import '../../domain/entities/sms_message_entity.dart';

abstract class FinancialSmsMessageParser {
  const FinancialSmsMessageParser();

  bool canParse(SmsMessageEntity message);

  ParsedSmsTransactionEntity? parse(SmsMessageEntity message);
}
