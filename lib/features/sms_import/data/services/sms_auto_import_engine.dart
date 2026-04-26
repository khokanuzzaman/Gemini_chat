import '../../domain/entities/parsed_sms_transaction_entity.dart';
import '../../domain/entities/sms_message_entity.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../parsers/bangladesh_financial_sms_parser.dart';
import 'android_sms_reader_service.dart';
import 'sms_permission_service.dart';

class SmsAutoImportEngine {
  SmsAutoImportEngine({
    SmsPermissionService? permissionService,
    AndroidSmsReaderService? readerService,
    BangladeshFinancialSmsParser? parser,
  }) : _permissionService = permissionService ?? const SmsPermissionService(),
       _readerService = readerService ?? AndroidSmsReaderService(),
       _parser = parser ?? BangladeshFinancialSmsParser();

  final SmsPermissionService _permissionService;
  final AndroidSmsReaderService _readerService;
  final BangladeshFinancialSmsParser _parser;

  bool get isSupported => _permissionService.isSupported;

  Future<SmsPermissionState> getPermissionStatus() {
    return _permissionService.getStatus();
  }

  Future<SmsPermissionState> requestPermission() {
    return _permissionService.requestPermission();
  }

  Future<List<SmsMessageEntity>> readInboxMessages({
    int limit = 200,
    DateTime? since,
  }) async {
    await _permissionService.ensurePermission();
    return _readerService.readInboxMessages(limit: limit, since: since);
  }

  Future<List<ParsedSmsTransactionEntity>> readParsedTransactions({
    int limit = 200,
    DateTime? since,
  }) async {
    final messages = await readInboxMessages(limit: limit, since: since);
    return parseMessages(messages);
  }

  ParsedSmsTransactionEntity? parseMessage(SmsMessageEntity message) {
    return _parser.parseMessage(message);
  }

  List<ParsedSmsTransactionEntity> parseMessages(
    Iterable<SmsMessageEntity> messages,
  ) {
    return _parser.parseMessages(messages);
  }
}
