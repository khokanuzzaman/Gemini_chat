import 'dart:async';

import '../../features/wallet/domain/entities/wallet_entity.dart';
import '../errors/exceptions.dart';
import 'parsed_transaction.dart';
import 'sms_category_mapper.dart';
import 'sms_duplicate_detector.dart';
import 'sms_filter.dart';
import 'sms_import_entry.dart';
import 'sms_message.dart';
import 'sms_parser.dart';
import 'sms_permission_handler.dart';
import 'sms_reader_service.dart';
import 'sms_settings.dart';
import 'sms_wallet_matcher.dart';

class SmsBackgroundListener {
  SmsBackgroundListener({
    required SmsFilter filter,
    required SmsParserEngine parser,
    required SmsDuplicateDetector duplicateDetector,
    required SmsCategoryMapper categoryMapper,
    required SmsWalletMatcher walletMatcher,
    SmsReaderService? reader,
    SmsPermissionHandler? permissionHandler,
    SmsSettings? settings,
    Future<List<WalletEntity>> Function()? walletLoader,
    WalletEntity? Function()? defaultWalletReader,
  }) : _filter = filter,
       _parser = parser,
       _duplicateDetector = duplicateDetector,
       _categoryMapper = categoryMapper,
       _walletMatcher = walletMatcher,
       _reader = reader,
       _permissionHandler = permissionHandler,
       _settings = settings,
       _walletLoader = walletLoader,
       _defaultWalletReader = defaultWalletReader;

  static const Duration pollingInterval = Duration(minutes: 5);

  final SmsFilter _filter;
  final SmsParserEngine _parser;
  final SmsDuplicateDetector _duplicateDetector;
  final SmsCategoryMapper _categoryMapper;
  final SmsWalletMatcher _walletMatcher;
  final SmsReaderService? _reader;
  final SmsPermissionHandler? _permissionHandler;
  final SmsSettings? _settings;
  final Future<List<WalletEntity>> Function()? _walletLoader;
  final WalletEntity? Function()? _defaultWalletReader;
  final StreamController<SmsImportEntry> _streamController =
      StreamController<SmsImportEntry>.broadcast();

  Timer? _pollTimer;
  bool _isListening = false;
  bool _isPolling = false;

  Stream<SmsImportEntry> get onNewTransaction => _streamController.stream;

  bool get isListening => _isListening;

  Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    if (_settings != null && !_settings.isAutoImportEnabled()) {
      return;
    }

    if (_permissionHandler != null &&
        !await _permissionHandler.hasPermission()) {
      return;
    }

    _isListening = true;
    await pollNow();
    _pollTimer = Timer.periodic(pollingInterval, (_) {
      unawaited(pollNow());
    });
  }

  Future<void> stopListening() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isListening = false;
  }

  Future<List<SmsImportEntry>> pollNow() async {
    if (_isPolling) {
      return const [];
    }

    final reader = _reader;
    final permissionHandler = _permissionHandler;
    final settings = _settings;
    if (reader == null || permissionHandler == null || settings == null) {
      return const [];
    }

    _isPolling = true;
    try {
      if (!settings.isAutoImportEnabled()) {
        await stopListening();
        return const [];
      }

      if (!await permissionHandler.hasPermission()) {
        await stopListening();
        return const [];
      }

      final since = settings.getLastScanTime() ?? DateTime.now();
      final scanStartedAt = DateTime.now();
      final messages = await reader.readSmsSince(since);
      await settings.setLastScanTime(scanStartedAt);

      if (messages.isEmpty) {
        return const [];
      }

      final wallets = await (_walletLoader?.call() ??
          Future<List<WalletEntity>>.value(const <WalletEntity>[]));
      final defaultWallet = _defaultWalletReader?.call();
      final enabledSources = _normalizeSources(settings.getEnabledSources());
      final financialMessages = _filter.filterFinancialSms(messages);
      final entries = <SmsImportEntry>[];

      for (final sms in financialMessages) {
        final parsed = _parser.tryParse(sms);
        if (parsed == null || !_isSourceEnabled(parsed.source, enabledSources)) {
          continue;
        }
        if (await _duplicateDetector.isDuplicate(sms)) {
          continue;
        }

        final entry = _buildEntry(
          sms,
          parsed,
          wallets,
          defaultWallet: defaultWallet,
        );
        entries.add(entry);
        if (!_streamController.isClosed) {
          _streamController.add(entry);
        }
      }

      entries.sort(
        (first, second) => second.transaction.occurredAt.compareTo(
          first.transaction.occurredAt,
        ),
      );
      return entries;
    } on PermissionDeniedException {
      await stopListening();
      return const [];
    } finally {
      _isPolling = false;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isListening = false;
    _streamController.close();
  }

  SmsImportEntry _buildEntry(
    SmsMessage sms,
    ParsedTransaction transaction,
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) {
    return SmsImportEntry(
      signature: _duplicateDetector.generateSignature(sms),
      sms: sms,
      transaction: transaction,
      detectedAt: DateTime.now(),
      suggestedWallet: _walletMatcher.matchWallet(
        transaction,
        wallets,
        defaultWallet: defaultWallet,
      ),
      suggestedCategory: transaction.type == TransactionType.expense
          ? _categoryMapper.mapToExpenseCategory(transaction)
          : null,
      suggestedIncomeSource: transaction.type == TransactionType.income
          ? _categoryMapper.mapToIncomeSource(transaction)
          : null,
    );
  }

  Set<String> _normalizeSources(List<String> sources) {
    return sources
        .map((source) => source.trim().toLowerCase())
        .where((source) => source.isNotEmpty)
        .toSet();
  }

  bool _isSourceEnabled(
    ParsedTransactionSource source,
    Set<String> enabledSources,
  ) {
    if (enabledSources.isEmpty) {
      return true;
    }

    final label = source.label.toLowerCase();
    if (enabledSources.contains(label)) {
      return true;
    }

    if (source == ParsedTransactionSource.bank &&
        enabledSources.contains('banks')) {
      return true;
    }

    return false;
  }
}
