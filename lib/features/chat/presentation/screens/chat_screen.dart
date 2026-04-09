import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_parser.dart';
import '../../../../core/ai/expense_result.dart';
import '../../../../core/ai/income_data.dart';
import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/message_entity.dart';
import '../../../expense/presentation/screens/analytics_screen.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/screens/manual_add_screen.dart';
import '../../../income/domain/entities/income_entity.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../split/presentation/screens/add_edit_split_screen.dart';
import '../../../split/presentation/widgets/split_suggestion_widget.dart';
import '../providers/chat_provider.dart';
import '../utils/message_key.dart';
import '../widgets/expense_confirmation_widget.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/income_confirmation_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/multiple_income_confirmation_widget.dart';
import '../widgets/multiple_expense_confirmation_widget.dart';
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
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_syncAutoScrollState);
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_syncAutoScrollState);
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
    final latestStreamText = ref.watch(chatStreamingTextProvider);
    final liveRateLimit = ref.watch(openAiRateLimitSnapshotProvider);
    final ragEnabled = ref.watch(ragEnabledProvider);
    final lastMessageUsedRag =
        ref.watch(lastMessageUsedRagProvider) && isResponding;
    final ragResponseMap = ref.watch(ragResponseMapProvider);
    final parsedExpenseMap = ref.watch(parsedExpenseResultMapProvider);
    final usageData = _buildUsageData(
      messages.valueOrNull ?? const [],
      liveRateLimit,
    );

    return AppPageScaffold(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'চ্যাট',
            style: AppTextStyles.titleLarge.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ragEnabled ? '🧠 স্মার্ট মোড চালু' : 'সাধারণ মোড',
            style: AppTextStyles.caption.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
      showBackButton: false,
      showOfflineBanner: true,
      onManualAdd: () => showManualAddSheet(context),
      useGradientBackground: true,
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
            color: ragEnabled
                ? context.appColors.primary
                : context.secondaryTextColor,
          ),
          tooltip: 'স্মার্ট মোড',
        ),
        IconButton(
          onPressed: isResponding || isRecording || isScanning
              ? null
              : () => _confirmClearChat(context),
          icon: Icon(
            Icons.delete_sweep_outlined,
            color: context.secondaryTextColor,
          ),
          tooltip: 'চ্যাট মুছুন',
        ),
      ],
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: lastMessageUsedRag && !_ragBannerDismissed
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.sm,
                          AppSpacing.screenPadding,
                          0,
                        ),
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
                    onSaveIncome: _saveIncomeData,
                    onSaveIncomeList: _saveIncomeList,
                    onOpenAnalytics: _openAnalytics,
                    ragResponseMap: ragResponseMap,
                    parsedExpenseMap: parsedExpenseMap,
                    scrollController: _scrollController,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                    ),
                    child: AppLoadingState.list(),
                  ),
                  error: (error, stackTrace) => AppErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(chatProvider),
                  ),
                ),
              ),
              ChatInputArea(
                messageController: _messageController,
                messageFocusNode: _messageFocusNode,
                characterCountNotifier: _characterCountNotifier,
                maxMessageLength: _maxMessageLength,
                isResponding: isResponding,
                isRecording: isRecording,
                isScanning: isScanning,
                recordingDuration: recordingDuration,
                onMessageChanged: (value) {
                  _characterCountNotifier.value = value.length;
                  if (value.isNotEmpty) {
                    _scrollToBottom();
                  }
                },
                onSubmitMessage: _submitMessage,
                onScanFromCamera: () => _startReceiptScan(fromCamera: true),
                onScanFromGallery: () => _startReceiptScan(fromCamera: false),
                onStartRecording: _startRecording,
                onStopRecording: () =>
                    ref.read(chatProvider.notifier).stopAndSendVoice(),
                onShowUsageDetails: () => _showUsageDetails(usageData),
              ),
            ],
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
    _shouldAutoScroll = true;
    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
    _characterCountNotifier.value = 0;
    _messageFocusNode.requestFocus();
    _scrollToBottom(force: true);
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
    await AppBottomSheet.show<void>(
      context: context,
      title: 'Internet নেই',
      subtitle: 'AI ছাড়া manual add করতে পারেন',
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppActionButton(
            label: 'Manual expense add করুন',
            icon: Icons.edit_note_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  showManualAddSheet(context);
                }
              });
            },
            fullWidth: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppActionButton(
            label: 'বাদ দিন',
            variant: AppActionButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpenseData(
    ExpenseData expenseData, [
    int? walletId,
  ]) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveDetectedExpense(expenseData, walletId: walletId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? AppStrings.expenseSaved)));
  }

  Future<void> _saveExpenseList(
    List<ExpenseData> expenses, [
    int? walletId,
  ]) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveDetectedExpenses(expenses, walletId: walletId);

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

  Future<void> _saveReceiptData(
    Map<String, dynamic> receiptData, [
    int? walletId,
  ]) async {
    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveReceiptExpense(receiptData, walletId: walletId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? AppStrings.expenseSaved)));
  }

  Future<void> _saveIncomeData(IncomeData incomeData, [int? walletId]) async {
    final income = IncomeEntity(
      amount: incomeData.amount,
      source: incomeData.source,
      description: incomeData.description.trim(),
      date: incomeData.parsedDate,
      walletId: walletId,
      isRecurring: incomeData.isRecurring,
      isManual: false,
      createdAt: DateTime.now(),
    );
    final error = await ref
        .read(incomeMutationControllerProvider)
        .saveDetectedIncome(income, walletId: walletId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'আয় সংরক্ষণ হয়েছে')));
  }

  Future<void> _saveIncomeList(
    List<IncomeData> incomes, [
    int? walletId,
  ]) async {
    final incomeEntities = incomes
        .map(
          (income) => IncomeEntity(
            amount: income.amount,
            source: income.source,
            description: income.description.trim(),
            date: income.parsedDate,
            walletId: walletId,
            isRecurring: income.isRecurring,
            isManual: false,
            createdAt: DateTime.now(),
          ),
        )
        .toList(growable: false);
    final error = await ref
        .read(incomeMutationControllerProvider)
        .saveDetectedIncomeBatch(incomeEntities, walletId: walletId);

    if (!mounted) {
      return;
    }

    final successMessage =
        'আয় ${BanglaFormatters.count(incomes.length)}টি সংরক্ষণ হয়েছে';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? successMessage)));
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

  void _syncAutoScrollState() {
    if (!_scrollController.hasClients) {
      return;
    }

    _shouldAutoScroll = _isNearBottom();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;
    return position.pixels <= position.minScrollExtent + 56;
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) {
        return;
      }

      if (!force && !_shouldAutoScroll) {
        return;
      }

      final offset = _scrollController.position.minScrollExtent;
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

  Future<void> _confirmClearChat(BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('চ্যাট মুছে ফেলবেন?'),
          content: const Text('সব বার্তা মুছে যাবে। এটি অপরিবর্তনীয়।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            SizedBox(
              width: 92,
              child: AppActionButton(
                label: 'মুছুন',
                variant: AppActionButtonVariant.danger,
                size: AppActionButtonSize.small,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(chatProvider.notifier).clearChat();
    }
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
    required this.onSaveIncome,
    required this.onSaveIncomeList,
    required this.onOpenAnalytics,
    required this.ragResponseMap,
    required this.parsedExpenseMap,
    required this.scrollController,
  });

  final List<MessageEntity> messages;
  final String? latestStreamText;
  final bool isResponding;
  final bool isStreamingWithRag;
  final ValueChanged<String> onCopyAiMessage;
  final Future<void> Function(ExpenseData expenseData, [int? walletId])
  onSaveExpense;
  final Future<void> Function(List<ExpenseData> expenses, [int? walletId])
  onSaveExpenseList;
  final Future<void> Function(Map<String, dynamic> receiptData, [int? walletId])
  onSaveReceipt;
  final Future<void> Function(IncomeData incomeData, [int? walletId])
  onSaveIncome;
  final Future<void> Function(List<IncomeData> incomes, [int? walletId])
  onSaveIncomeList;
  final VoidCallback onOpenAnalytics;
  final Map<String, RagResponseData> ragResponseMap;
  final Map<String, ExpenseResult> parsedExpenseMap;
  final ScrollController scrollController;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  static const _expenseParser = ExpenseParser();
  final Set<String> _dismissedCards = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isResponding) {
      return const _ChatEmptyState();
    }

    final reversedMessages = widget.messages.reversed.toList(growable: false);
    final hasStreamingSlot = widget.isResponding;
    final itemCount = reversedMessages.length + (hasStreamingSlot ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasStreamingSlot && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildStreamingItem(),
          );
        }

        final messageIndex = index - (hasStreamingSlot ? 1 : 0);
        if (messageIndex >= 0 && messageIndex < reversedMessages.length) {
          final message = reversedMessages[messageIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildMessageItem(context, message),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStreamingItem() {
    final streamingText = widget.latestStreamText?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        streamingText == null || streamingText.isEmpty
            ? const TypingIndicatorWidget()
            : MessageBubble(
                key: const ValueKey('streaming-message-bubble'),
                text: streamingText,
                isUser: false,
                createdAt: DateTime.now(),
                isStreaming: true,
                animationIdentity: 'streaming-message-bubble',
              ),
        if (widget.isStreamingWithRag) ...[
          const SizedBox(height: 6),
          const _RagIndicatorChip(),
        ],
      ],
    );
  }

  Widget _buildMessageItem(BuildContext context, MessageEntity message) {
    final messageKey = _messageKey(message);
    if (!message.isUser && !message.isError) {
      final expenseResult =
          widget.parsedExpenseMap[messageKey] ??
          _expenseParser.parseExpenseFromResponse(message.text);

      if (expenseResult.isExpense || expenseResult.isIncome) {
        final parts = <Widget>[];
        final conversationalText =
            expenseResult.conversationalText?.trim() ?? '';

        if (conversationalText.isNotEmpty) {
          parts.add(
            MessageBubble(
              key: ValueKey('conversational-$messageKey'),
              text: conversationalText,
              isUser: false,
              createdAt: message.createdAt,
              onLongPress: () => widget.onCopyAiMessage(message.text),
              promptTokenCount: message.promptTokenCount,
              outputTokenCount: message.outputTokenCount,
              totalTokenCount: message.totalTokenCount,
              animationIdentity: 'conversational-$messageKey',
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
                onSave: (editedReceiptData, walletId) async {
                  await widget.onSaveReceipt(editedReceiptData, walletId);
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
                onSave: (selectedExpenses, walletId) async {
                  await widget.onSaveExpenseList(selectedExpenses, walletId);
                  _dismissCard(messageKey);
                },
                onCancel: () => _dismissCard(messageKey),
              ),
            );
          } else if (expenseResult.expenses.isNotEmpty) {
            parts.add(
              ExpenseConfirmationWidget(
                expense: expenseResult.expenses.first,
                onSave: (editedExpense, walletId) async {
                  await widget.onSaveExpense(editedExpense, walletId);
                  _dismissCard(messageKey);
                },
                onCancel: () => _dismissCard(messageKey),
              ),
            );
          }

          if (expenseResult.incomes.isNotEmpty) {
            if (parts.isNotEmpty) {
              parts.add(const SizedBox(height: 12));
              if (expenseResult.hasMixedEntries) {
                parts.add(
                  MessageBubble(
                    key: ValueKey('income-hint-$messageKey'),
                    text: 'আয়ের তথ্যও পাওয়া গেছে। দেখুন:',
                    isUser: false,
                    createdAt: message.createdAt,
                    animationIdentity: 'income-hint-$messageKey',
                  ),
                );
                parts.add(const SizedBox(height: 8));
              } else {
                parts.add(Divider(height: 1, color: context.borderColor));
                parts.add(const SizedBox(height: 12));
              }
            }

            if (expenseResult.incomes.length > 1) {
              parts.add(
                MultipleIncomeConfirmationWidget(
                  incomes: expenseResult.incomes,
                  onSave: (selectedIncomes, walletId) async {
                    await widget.onSaveIncomeList(selectedIncomes, walletId);
                  },
                  onCancel: () => _dismissCard(messageKey),
                ),
              );
            } else {
              parts.add(
                IncomeConfirmationWidget(
                  income: expenseResult.incomes.first,
                  onSave: (editedIncome, walletId) async {
                    await widget.onSaveIncome(editedIncome, walletId);
                  },
                  onCancel: () => _dismissCard(messageKey),
                ),
              );
            }
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
      key: ValueKey(message.id ?? message.createdAt.microsecondsSinceEpoch),
      text: message.text,
      isUser: message.isUser,
      isReceipt: message.isReceipt,
      isVoice: message.isVoice,
      isError: message.isError,
      isRag: message.isRag,
      ragData: widget.ragResponseMap[messageKey],
      createdAt: message.createdAt,
      promptTokenCount: message.promptTokenCount,
      outputTokenCount: message.outputTokenCount,
      totalTokenCount: message.totalTokenCount,
      animationIdentity: message.id ?? message.createdAt.microsecondsSinceEpoch,
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

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'চ্যাট শুরু করুন',
      subtitle: 'আপনার খরচ লিখুন, বলুন বা রিসিট স্ক্যান করুন',
    );
  }
}

class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: context.primaryTextColor.withValues(alpha: 0.56),
          child: Center(
            child: AppCard(
              elevation: 4,
              borderRadius: const BorderRadius.all(AppRadius.heroCard),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'Receipt পড়ছি...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
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
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: const BorderRadius.all(AppRadius.card),
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
              style: AppTextStyles.caption.copyWith(
                color: context.ragChipTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: context.ragChipTextColor,
              ),
            ),
          ),
        ],
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
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              style: AppTextStyles.caption.copyWith(
                color: context.ragChipTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
