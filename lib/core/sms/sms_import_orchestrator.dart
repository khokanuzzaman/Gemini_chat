import '../../features/wallet/domain/entities/wallet_entity.dart';
import 'parsed_transaction.dart';
import 'sms_category_mapper.dart';
import 'sms_duplicate_detector.dart';
import 'sms_filter.dart';
import 'sms_import_result.dart';
import 'sms_parser.dart';
import 'sms_reader_service.dart';
import 'sms_wallet_matcher.dart';

class SmsImportOrchestrator {
  const SmsImportOrchestrator({
    required this.reader,
    required this.filter,
    required this.parser,
    required this.categoryMapper,
    required this.walletMatcher,
    required this.duplicateDetector,
  });

  final SmsReaderService reader;
  final SmsFilter filter;
  final SmsParserEngine parser;
  final SmsCategoryMapper categoryMapper;
  final SmsWalletMatcher walletMatcher;
  final SmsDuplicateDetector duplicateDetector;

  Future<SmsImportResult> scanForNewTransactions(
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) async {
    final lastImportDate = await duplicateDetector.getLastImportDate();
    final since =
        lastImportDate ?? DateTime.now().subtract(const Duration(days: 30));

    final scannedMessages = await reader.readSmsSince(since);
    final financialMessages = filter.filterFinancialSms(scannedMessages);
    final parsedTransactions = parser.parseAll(financialMessages);
    final newTransactions = await duplicateDetector.filterNew(
      parsedTransactions,
      financialMessages,
    );

    final originalById = {
      for (final message in financialMessages) message.id: message,
    };
    final candidates = <SmsImportCandidate>[];
    for (final transaction in newTransactions) {
      final originalMessage = originalById[transaction.smsId];
      if (originalMessage == null) {
        continue;
      }

      candidates.add(
        SmsImportCandidate(
          sms: originalMessage,
          transaction: transaction,
          suggestedWallet: walletMatcher.matchWallet(
            transaction,
            wallets,
            defaultWallet: defaultWallet,
          ),
          suggestedCategory: transaction.type == TransactionType.expense
              ? categoryMapper.mapToExpenseCategory(transaction)
              : null,
          suggestedIncomeSource: transaction.type == TransactionType.income
              ? categoryMapper.mapToIncomeSource(transaction)
              : null,
        ),
      );
    }

    return SmsImportResult(
      since: since,
      scannedMessages: scannedMessages,
      financialMessages: financialMessages,
      parsedTransactions: parsedTransactions,
      candidates: candidates,
      duplicateCount: parsedTransactions.length - newTransactions.length,
    );
  }
}
