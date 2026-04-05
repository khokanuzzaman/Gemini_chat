import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_parser.dart';
import '../../../../core/ai/expense_result.dart';
import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/assets/app_icon.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/global_settings_button.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../domain/entities/message_entity.dart';
import '../../../expense/presentation/screens/analytics_screen.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/screens/manual_add_screen.dart';
import '../../../split/presentation/screens/add_edit_split_screen.dart';
import '../../../split/presentation/widgets/split_suggestion_widget.dart';
import '../providers/chat_provider.dart';
import '../utils/message_key.dart';
import '../widgets/expense_confirmation_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/multiple_expense_confirmation_widget.dart';
import '../widgets/pulsing_recording_widget.dart';
import '../widgets/receipt_confirmation_widget.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/usage_details_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  static const _maxMessageLength = 500;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ValueNotifier<int> _characterCountNotifier = ValueNotifier<int>(0);
  bool _ragBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _characterCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(chatErrorMessageProvider, (previous, next) {
      if (next == null || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next)));

      ref.read(chatErrorMessageProvider.notifier).state = null;
    });

    ref.listen<AsyncValue<List<MessageEntity>>>(chatProvider, (previous, next) {
      final previousLength = previous?.valueOrNull?.length ?? 0;
      final nextLength = next.valueOrNull?.length ?? 0;

      if (previousLength != nextLength) {
        _scrollToBottom();
      }
    });

    ref.listen<String?>(chatStreamingTextProvider, (previous, next) {
      if (next != null && next != previous) {
        _scrollToBottom();
      }
    });

    final messages = ref.watch(chatProvider);
    final isResponding = ref.watch(isRespondingProvider);
    final isRecording = ref.watch(isRecordingProvider);
    final isScanning = ref.watch(isScanningProvider);
    final recordingDuration = ref.watch(recordingDurationProvider) ?? '0:00';
    final latestStreamText = ref.watch(chatStreamingTextProvider) ?? '';
    final liveRateLimit = ref.watch(openAiRateLimitSnapshotProvider);
    final ragEnabled = ref.watch(ragEnabledProvider);
    final lastMessageUsedRag =
        ref.watch(lastMessageUsedRagProvider) && isResponding;
    final ragResponseMap = ref.watch(ragResponseMapProvider);
    final usageData = _buildUsageData(
      messages.valueOrNull ?? const [],
      liveRateLimit,
    );

    return Scaffold(
      appBar: AppBar(
        title: const SmartSpendWordmark(compact: true),
        actions: [
          IconButton(
            onPressed: isResponding || isRecording || isScanning
                ? null
                : () async {
                    ref.read(chatProvider.notifier).toggleRag();
                    await AppPreferences.setRagEnabled(
                      ref.read(ragEnabledProvider),
                    );
                  },
            icon: Icon(
              ragEnabled ? Icons.psychology_rounded : Icons.psychology_outlined,
            ),
            tooltip: ragEnabled ? 'Personal data চালু' : 'Personal data বন্ধ',
          ),
          const GlobalSettingsButton(),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OfflineBanner(onManualAdd: () => showManualAddSheet(context)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: lastMessageUsedRag && !_ragBannerDismissed
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _RagStatusBanner(
                            onDismiss: () {
                              setState(() {
                                _ragBannerDismissed = true;
                              });
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: messages.when(
                    data: (items) => _MessageList(
                      messages: items,
                      latestStreamText: latestStreamText,
                      isResponding: isResponding,
                      isStreamingWithRag: lastMessageUsedRag,
                      onCopyAiMessage: _copyAiMessage,
                      onSaveExpense: _saveExpenseData,
                      onSaveExpenseList: _saveExpenseList,
                      onSaveReceipt: _saveReceiptData,
                      onOpenAnalytics: _openAnalytics,
                      ragResponseMap: ragResponseMap,
                      scrollController: _scrollController,
                      onSuggestionTap: _handleSuggestionTap,
                    ),
                    loading: () => const Center(child: TypingIndicatorWidget()),
                    error: (error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load messages.\n$error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    border: Border(top: BorderSide(color: context.borderColor)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _characterCountNotifier,
                      builder: (context, currentCount, child) {
                        final trimmedText = _messageController.text.trim();
                        final isOverLimit = currentCount > _maxMessageLength;
                        final canSend =
                            !isResponding &&
                            !isRecording &&
                            !isScanning &&
                            trimmedText.isNotEmpty &&
                            !isOverLimit;

                        if (isRecording) {
                          return _RecordingComposer(
                            duration: recordingDuration,
                            onStop: () => ref
                                .read(chatProvider.notifier)
                                .stopAndSendVoice(),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _AttachButton(
                                  enabled: !isResponding && !isScanning,
                                  onTap: () {
                                    _showAttachOptions();
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _messageFocusNode,
                                    minLines: 1,
                                    maxLines: 6,
                                    enabled: !isScanning,
                                    textInputAction: TextInputAction.send,
                                    onChanged: (value) {
                                      _characterCountNotifier.value =
                                          value.length;
                                      if (value.isNotEmpty) {
                                        _scrollToBottom();
                                      }
                                    },
                                    onSubmitted: (_) {
                                      _submitMessage();
                                    },
                                    decoration: const InputDecoration(
                                      hintText: AppStrings.chatHint,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _ComposerActionButton(
                                  hasText: trimmedText.isNotEmpty,
                                  isResponding: isResponding || isScanning,
                                  canSend: canSend,
                                  onSend: () {
                                    _submitMessage();
                                  },
                                  onStartRecording: () {
                                    _startRecording();
                                  },
                                ),
                              ],
                            ),
                            if (currentCount > 400) ...[
                              const SizedBox(height: 6),
                              Text(
                                '$currentCount/$_maxMessageLength',
                                style: TextStyle(
                                  color: isOverLimit
                                      ? AppColors.error
                                      : context.secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Center(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => _showUsageDetails(usageData),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    AppStrings.poweredBy,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.hintTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isScanning) const _ScanningOverlay(),
        ],
      ),
    );
  }

  Future<void> _submitMessage() async {
    final text = _messageController.text.trim();
    final currentCount = _characterCountNotifier.value;
    if (text.isEmpty || currentCount > _maxMessageLength) {
      return;
    }

    if (!ref.read(connectivityProvider)) {
      await _showOfflineActionSheet();
      return;
    }

    setState(() {
      _ragBannerDismissed = false;
    });
    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
    _characterCountNotifier.value = 0;
    _messageFocusNode.requestFocus();
    _scrollToBottom();
  }

  void _handleSuggestionTap(String text) {
    _messageController.text = text;
    _characterCountNotifier.value = text.length;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _messageFocusNode.requestFocus();
  }

  Future<void> _showAttachOptions() async {
    if (!ref.read(connectivityProvider)) {
      await _showOfflineActionSheet();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Receipt scan করুন',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 14),
                _AttachmentOptionTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Camera',
                  subtitle: 'নতুন receipt তুলুন',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _startReceiptScan(fromCamera: true);
                  },
                ),
                const SizedBox(height: 8),
                _AttachmentOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Gallery',
                  subtitle: 'আগের receipt image বাছাই করুন',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _startReceiptScan(fromCamera: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    if (!ref.read(connectivityProvider)) {
      await _showOfflineActionSheet();
      return;
    }

    await ref.read(chatProvider.notifier).startRecording();
  }

  Future<void> _startReceiptScan({required bool fromCamera}) async {
    if (!ref.read(connectivityProvider)) {
      await _showOfflineActionSheet();
      return;
    }

    if (fromCamera) {
      await ref.read(chatProvider.notifier).scanFromCamera();
      return;
    }

    await ref.read(chatProvider.notifier).scanFromGallery();
  }

  Future<void> _showOfflineActionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Internet নেই', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'AI ছাড়া manual add করতে পারেন',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          showManualAddSheet(context);
                        }
                      });
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Manual expense add করুন'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('বাদ দিন'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveExpenseData(ExpenseData expenseData) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveDetectedExpense(expenseData);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? AppStrings.expenseSaved)));
  }

  Future<void> _saveExpenseList(List<ExpenseData> expenses) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveDetectedExpenses(expenses);

    if (!mounted) {
      return;
    }

    final successMessage = AppStrings.expensesSavedWithCount(
      BanglaFormatters.count(expenses.length),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? successMessage)));
  }

  Future<void> _saveReceiptData(Map<String, dynamic> receiptData) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveReceiptExpense(receiptData);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? AppStrings.expenseSaved)));
  }

  Future<void> _copyAiMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _openAnalytics() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AnalyticsScreen()));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) {
        return;
      }

      final offset = _scrollController.position.maxScrollExtent;
      try {
        await _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }

  Future<void> _showUsageDetails(UsageOverviewData data) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UsageDetailsSheet(data: data),
    );
  }

  UsageOverviewData _buildUsageData(
    List<MessageEntity> messages,
    RateLimitSnapshot? liveRateLimit,
  ) {
    final today = DateTime.now();
    var todayUsedTokens = 0;
    var requestsUsedToday = 0;
    MessageEntity? latestUsageMessage;

    for (final message in messages) {
      if (message.isUser || message.isError) {
        continue;
      }

      final usage = _resolveMessageUsage(message);

      if (_isSameDay(message.createdAt, today)) {
        todayUsedTokens += usage.totalTokens;
        requestsUsedToday += 1;
      }

      if (latestUsageMessage == null ||
          message.createdAt.isAfter(latestUsageMessage.createdAt)) {
        latestUsageMessage = message;
      }
    }

    final remainingTokens =
        todayUsedTokens >= ApiConstants.trackedDailyTokenBudget
        ? 0
        : ApiConstants.trackedDailyTokenBudget - todayUsedTokens;
    final requestsRemainingToday =
        requestsUsedToday >= ApiConstants.referenceDailyRequestLimit
        ? 0
        : ApiConstants.referenceDailyRequestLimit - requestsUsedToday;
    final localUsagePercent = ApiConstants.trackedDailyTokenBudget <= 0
        ? 0
        : ((todayUsedTokens / ApiConstants.trackedDailyTokenBudget) * 100)
              .round()
              .clamp(0, 100);

    return UsageOverviewData(
      todayUsedTokens: todayUsedTokens,
      remainingTokens: remainingTokens,
      dailyTokenBudget: ApiConstants.trackedDailyTokenBudget,
      requestsUsedToday: requestsUsedToday,
      requestsRemainingToday: requestsRemainingToday,
      dailyRequestLimit: ApiConstants.referenceDailyRequestLimit,
      localUsagePercent: localUsagePercent,
      liveRateLimit: liveRateLimit,
      lastUsage: latestUsageMessage == null
          ? null
          : _resolveMessageUsage(latestUsageMessage),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  TokenUsage _resolveMessageUsage(MessageEntity message) {
    final outputTokens =
        message.outputTokenCount ?? _estimateTextTokens(message.text);
    final promptTokens =
        message.promptTokenCount ?? _estimatePromptTokens(outputTokens);
    final totalTokens = message.totalTokenCount ?? promptTokens + outputTokens;

    return TokenUsage(
      promptTokens: promptTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      isEstimated:
          message.promptTokenCount == null ||
          message.outputTokenCount == null ||
          message.totalTokenCount == null,
    );
  }

  int _estimateTextTokens(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    final estimated = (trimmed.runes.length / 4).ceil();
    return estimated < 1 ? 1 : estimated;
  }

  int _estimatePromptTokens(int outputTokens) {
    if (outputTokens <= 0) {
      return 24;
    }

    final scaled = (outputTokens * 1.3).round();
    return scaled < 24 ? 24 : scaled;
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.messages,
    required this.latestStreamText,
    required this.isResponding,
    required this.isStreamingWithRag,
    required this.onCopyAiMessage,
    required this.onSaveExpense,
    required this.onSaveExpenseList,
    required this.onSaveReceipt,
    required this.onOpenAnalytics,
    required this.ragResponseMap,
    required this.scrollController,
    required this.onSuggestionTap,
  });

  final List<MessageEntity> messages;
  final String latestStreamText;
  final bool isResponding;
  final bool isStreamingWithRag;
  final ValueChanged<String> onCopyAiMessage;
  final Future<void> Function(ExpenseData expenseData) onSaveExpense;
  final Future<void> Function(List<ExpenseData> expenses) onSaveExpenseList;
  final Future<void> Function(Map<String, dynamic> receiptData) onSaveReceipt;
  final VoidCallback onOpenAnalytics;
  final Map<String, RagResponseData> ragResponseMap;
  final ScrollController scrollController;
  final ValueChanged<String> onSuggestionTap;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  static const _expenseParser = ExpenseParser();
  final Set<String> _dismissedCards = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isResponding) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -8 * value),
                    child: child,
                  );
                },
                child: const SmartSpendLogo(
                  size: 80,
                  showShadow: true,
                  borderRadius: BorderRadius.all(AppRadius.xl),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.welcomeTitle,
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.welcomeSubtitle,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SuggestionChip(
                    label: 'আজকের খরচ দিন',
                    onTap: () => widget.onSuggestionTap('আজকের খরচ দিন'),
                  ),
                  _SuggestionChip(
                    label: 'এই মাসের summary',
                    onTap: () =>
                        widget.onSuggestionTap('এই মাসে কত খরচ হয়েছে?'),
                  ),
                  _SuggestionChip(
                    label: 'receipt scan করুন',
                    onTap: () => widget.onSuggestionTap('receipt scan করুন'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = widget.messages.length + (widget.isResponding ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < widget.messages.length) {
          final message = widget.messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMessageItem(context, message, index),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.latestStreamText.trim().isEmpty
                  ? const TypingIndicatorWidget()
                  : MessageBubble(
                      text: widget.latestStreamText,
                      isUser: false,
                      createdAt: DateTime.now(),
                    ),
              if (widget.isStreamingWithRag) ...[
                const SizedBox(height: 6),
                const _RagIndicatorChip(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    MessageEntity message,
    int index,
  ) {
    final messageKey = _messageKey(message);
    if (!message.isUser && !message.isError) {
      final expenseResult = _expenseParser.parseExpenseFromResponse(
        message.text,
      );

      if (expenseResult.isExpense) {
        final parts = <Widget>[];
        final conversationalText =
            expenseResult.conversationalText?.trim() ?? '';

        if (conversationalText.isNotEmpty) {
          parts.add(
            MessageBubble(
              text: conversationalText,
              isUser: false,
              createdAt: message.createdAt,
              onLongPress: () => widget.onCopyAiMessage(message.text),
            ),
          );
        }

        if (!_dismissedCards.contains(messageKey)) {
          if (parts.isNotEmpty) {
            parts.add(const SizedBox(height: 8));
          }

          if (expenseResult.isReceipt && expenseResult.receiptData != null) {
            parts.add(
              ReceiptConfirmationWidget(
                receiptData: expenseResult.receiptData!,
                onSave: (editedReceiptData) async {
                  await widget.onSaveReceipt(editedReceiptData);
                  _dismissCard(messageKey);
                },
                onCancel: () => _dismissCard(messageKey),
              ),
            );
          } else if (expenseResult.isSplit &&
              expenseResult.expenses.isNotEmpty) {
            final splitExpense = expenseResult.expenses.first;
            final splitPersons =
                (expenseResult.splitPersons ?? splitExpense.splitPersons ?? 2)
                    .clamp(2, 12);
            parts.add(
              SplitSuggestionWidget(
                expense: splitExpense,
                personCount: splitPersons,
                onSaveOnly: () async {
                  await widget.onSaveExpense(splitExpense);
                  _dismissCard(messageKey);
                },
                onOpenSplit: () {
                  Navigator.of(context).push(
                    buildAppRoute(
                      AddEditSplitScreen(
                        initialTitle: splitExpense.description.trim().isEmpty
                            ? 'Split bill'
                            : splitExpense.description,
                        initialTotalAmount: splitExpense.amount,
                        initialPersonCount: splitPersons,
                        initialCategory: splitExpense.category,
                        initialDate: splitExpense.parsedDate,
                      ),
                    ),
                  );
                },
              ),
            );
          } else if (expenseResult.isMultiple) {
            parts.add(
              MultipleExpenseConfirmationWidget(
                expenses: expenseResult.expenses,
                onSave: (selectedExpenses) async {
                  await widget.onSaveExpenseList(selectedExpenses);
                  _dismissCard(messageKey);
                },
                onCancel: () => _dismissCard(messageKey),
              ),
            );
          } else if (expenseResult.expenses.isNotEmpty) {
            parts.add(
              ExpenseConfirmationWidget(
                expense: expenseResult.expenses.first,
                onSave: (editedExpense) async {
                  await widget.onSaveExpense(editedExpense);
                  _dismissCard(messageKey);
                },
                onCancel: () => _dismissCard(messageKey),
              ),
            );
          }
        }

        if (parts.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: parts,
          );
        }
      }
    }

    final bubble = MessageBubble(
      text: message.text,
      isUser: message.isUser,
      isReceipt: message.isReceipt,
      isVoice: message.isVoice,
      isError: message.isError,
      isRag: message.isRag,
      ragData: widget.ragResponseMap[messageKey],
      createdAt: message.createdAt,
      onLongPress: message.isUser || message.isError
          ? null
          : () => widget.onCopyAiMessage(message.text),
      onOpenAnalytics: widget.onOpenAnalytics,
    );

    if (message.isUser || message.isRag || !message.usedRagContext) {
      return bubble;
    }

    final children = <Widget>[
      bubble,
      const SizedBox(height: 6),
      const _RagIndicatorChip(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _dismissCard(String key) {
    setState(() {
      _dismissedCards.add(key);
    });
  }

  String _messageKey(MessageEntity message) {
    return buildChatMessageKey(message);
  }
}

class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: context.primaryTextColor.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'Receipt পড়ছি...',
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RagStatusBanner extends StatelessWidget {
  const _RagStatusBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.ragChipBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 18,
              color: context.ragChipTextColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Personal data ব্যবহার হচ্ছে',
                style: TextStyle(
                  color: context.ragChipTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: context.ragChipTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RagIndicatorChip extends StatelessWidget {
  const _RagIndicatorChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.ragChipBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_rounded,
              size: 14,
              color: context.ragChipTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              'আপনার data থেকে',
              style: TextStyle(
                color: context.ragChipTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.hasText,
    required this.isResponding,
    required this.canSend,
    required this.onSend,
    required this.onStartRecording,
  });

  final bool hasText;
  final bool isResponding;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: hasText
          ? SizedBox(
              key: const ValueKey('send-button'),
              height: 54,
              width: 54,
              child: FilledButton(
                onPressed: canSend ? onSend : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: const CircleBorder(),
                ),
                child: isResponding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            )
          : _MicIdleButton(
              key: const ValueKey('mic-button'),
              enabled: !isResponding,
              onTap: onStartRecording,
            ),
    );
  }
}

class _MicIdleButton extends StatefulWidget {
  const _MicIdleButton({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_MicIdleButton> createState() => _MicIdleButtonState();
}

class _MicIdleButtonState extends State<_MicIdleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.96,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _haloScale = Tween<double>(
    begin: 0.9,
    end: 1.18,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _haloOpacity = Tween<double>(
    begin: 0.12,
    end: 0.02,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _MicIdleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isEnabled = widget.enabled;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (isEnabled)
                Opacity(
                  opacity: _haloOpacity.value,
                  child: Transform.scale(
                    scale: _haloScale.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: isEnabled ? _scale.value : 0.94,
                child: child,
              ),
            ],
          );
        },
        child: FilledButton(
          onPressed: widget.enabled ? widget.onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor: AppColors.grey400,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(
            Icons.mic_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _RecordingComposer extends StatelessWidget {
  const _RecordingComposer({required this.duration, required this.onStop});

  final String duration;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.error.withValues(alpha: 0.14)
            : const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode
              ? AppColors.error.withValues(alpha: 0.35)
              : const Color(0xFFF6CCC8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.isDarkMode
                    ? AppColors.error.withValues(alpha: 0.25)
                    : const Color(0xFFF2D5D2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                PulsingRecordingWidget(),
                SizedBox(width: 12),
                _RecordingBars(),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ভয়েস রেকর্ড হচ্ছে',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(
                    color: AppColors.grey900,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'শেষ হলে পাশের বাটনে চাপুন',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 64,
            width: 64,
            child: FilledButton(
              onPressed: onStop,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(height: 2),
                  Text(
                    'পাঠান',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: IconButton.filledTonal(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          backgroundColor: context.mutedSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(Icons.add_rounded, color: context.primaryTextColor),
      ),
    );
  }
}

class _AttachmentOptionTile extends StatelessWidget {
  const _AttachmentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.mutedSurfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.ragChipBackgroundColor,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: context.mutedSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: context.borderColor),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: context.primaryTextColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RecordingBars extends StatefulWidget {
  const _RecordingBars();

  @override
  State<_RecordingBars> createState() => _RecordingBarsState();
}

class _RecordingBarsState extends State<_RecordingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _baseHeights = [10.0, 18.0, 12.0, 22.0, 14.0];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(_baseHeights.length, (index) {
            final phase = (_controller.value + (index * 0.14)) % 1;
            final multiplier = 0.72 + (phase * 0.56);
            final height = _baseHeights[index] * multiplier;

            return Padding(
              padding: EdgeInsets.only(
                right: index == _baseHeights.length - 1 ? 0 : 4,
              ),
              child: Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFF5B0A8),
                    AppColors.error,
                    0.35 + (phase * 0.55),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
