import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/ai/income_data.dart';
import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/premium/premium_providers.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usage/usage_limits.dart';
import '../../../../core/usage/usage_providers.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/message_entity.dart';
import '../../../ai_guide/presentation/screens/ai_guide_screen.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/screens/analytics_screen.dart';
import '../../../expense/presentation/screens/manual_add_screen.dart';
import '../../../income/domain/entities/income_entity.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_suggestion_provider.dart';
import '../utils/chat_suggestion_engine.dart';
import '../../../../core/widgets/limit_reached_sheet.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_mode_toggle_chip.dart';
import '../widgets/chat_status_widgets.dart';
import '../widgets/usage_details_sheet.dart';
import '../../../settings/premium_screen.dart';

class ChatScreenContent extends ConsumerStatefulWidget {
  const ChatScreenContent({super.key});

  @override
  ConsumerState<ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends ConsumerState<ChatScreenContent>
    with WidgetsBindingObserver {
  static const _maxMessageLength = 500;
  static const _suggestionEngine = ChatSuggestionEngine();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ValueNotifier<int> _characterCountNotifier = ValueNotifier<int>(0);
  bool _ragBannerDismissed = false;
  bool _chatLimitBannerDismissed = false;
  bool _aiGuidePromptSeen = false;
  bool _isInputFocused = false;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_handleMessageInputChanged);
    _scrollController.addListener(_syncAutoScrollState);
    _messageFocusNode.addListener(_syncInputFocusState);
    _loadAiGuidePromptState();
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_handleMessageInputChanged);
    _scrollController.removeListener(_syncAutoScrollState);
    _messageFocusNode.removeListener(_syncInputFocusState);
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

    ref.listen(limitReachedStatusProvider, (previous, next) {
      if (next == null || !mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        LimitReachedSheet.show(context: context, status: next);
      });

      ref.read(limitReachedStatusProvider.notifier).state = null;
    });

    final messages = ref.watch(chatProvider);
    final isResponding = ref.watch(isRespondingProvider);
    final isRecording = ref.watch(isRecordingProvider);
    final isScanning = ref.watch(isScanningProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final chatUsageStatus = ref.watch(usageStatusProvider(UsageLimits.aiChat));
    final recordingDuration = ref.watch(recordingDurationProvider) ?? '0:00';
    final latestStreamText = ref.watch(chatStreamingTextProvider);
    final liveRateLimit = ref.watch(openAiRateLimitSnapshotProvider);
    final ragEnabled = ref.watch(ragEnabledProvider);
    final lastMessageUsedRag =
        ref.watch(lastMessageUsedRagProvider) && isResponding;
    final ragResponseMap = ref.watch(ragResponseMapProvider);
    final parsedExpenseMap = ref.watch(parsedExpenseResultMapProvider);
    final categories = ref.watch(categoryProvider);
    final recentSuggestionExpenses =
        ref.watch(chatSuggestionHistoryProvider).valueOrNull ?? const [];
    final usageData = _buildUsageData(
      messages.valueOrNull ?? const [],
      liveRateLimit,
    );
    final nearLimitStatus = chatUsageStatus.valueOrNull;
    final showNearLimitBanner =
        !isPremium &&
        !_chatLimitBannerDismissed &&
        nearLimitStatus != null &&
        nearLimitStatus.isNearLimit &&
        !nearLimitStatus.hasReachedLimit;
    final actionsDisabled = isResponding || isRecording || isScanning;

    return AppPageScaffold(
      title: 'চ্যাট',
      showBackButton: false,
      showOfflineBanner: true,
      onManualAdd: () => showManualAddSheet(context),
      useGradientBackground: true,
      actions: [
        IconButton(
          onPressed: () => _openAiGuide(),
          icon: Icon(
            Icons.help_outline_rounded,
            color: context.secondaryTextColor,
          ),
          tooltip: 'AI গাইড',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ChatModeToggleChip(
            enabled: !actionsDisabled,
            isActive: ragEnabled,
            onTap: () async {
              ref.read(chatProvider.notifier).toggleRag();
              await AppPreferences.setRagEnabled(
                ref.read(ragEnabledProvider),
              );
            },
          ),
        ),
        IconButton(
          onPressed: actionsDisabled ? null : () => _confirmClearChat(context),
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
                        child: Dismissible(
                          key: const ValueKey('rag-status-banner'),
                          direction: DismissDirection.up,
                          onDismissed: (_) => _dismissRagBanner(),
                          child: ChatRagStatusBanner(
                            onDismiss: _dismissRagBanner,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: messages.when(
                  data: (items) => ChatMessageList(
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
                    showAiGuidePrompt: !_aiGuidePromptSeen,
                    onOpenAiGuide: () => _openAiGuide(),
                    onDismissAiGuidePrompt: () => _dismissAiGuidePrompt(),
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
              if (showNearLimitBanner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: Dismissible(
                    key: const ValueKey('chat-near-limit-banner'),
                    direction: DismissDirection.down,
                    onDismissed: (_) => _dismissNearLimitBanner(),
                    child: NearLimitBanner(
                      status: nearLimitStatus,
                      onUpgrade: () {
                        Navigator.of(context).push(
                          AppSlideRoute(builder: (_) => const PremiumScreen()),
                        );
                      },
                      onDismiss: _dismissNearLimitBanner,
                    ),
                  ),
                ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, _) {
                  final currentInputText = value.text;
                  final suggestions = _suggestionEngine.build(
                    input: currentInputText,
                    categoryNames: categories
                        .map((category) => category.name)
                        .toList(growable: false),
                    recentExpenses: recentSuggestionExpenses,
                    ragEnabled: ragEnabled,
                  );
                  final showSuggestions =
                      (_isInputFocused || currentInputText.trim().isNotEmpty) &&
                      currentInputText.length <= _maxMessageLength &&
                      !isResponding &&
                      !isRecording &&
                      !isScanning;

                  return ChatInputArea(
                    messageController: _messageController,
                    messageFocusNode: _messageFocusNode,
                    characterCountNotifier: _characterCountNotifier,
                    maxMessageLength: _maxMessageLength,
                    isResponding: isResponding,
                    isRecording: isRecording,
                    isScanning: isScanning,
                    recordingDuration: recordingDuration,
                    suggestions: suggestions,
                    showSuggestions: showSuggestions,
                    onSuggestionSelected: _applySuggestion,
                    onSubmitMessage: _submitMessage,
                    onScanFromCamera: () => _startReceiptScan(fromCamera: true),
                    onScanFromGallery: () =>
                        _startReceiptScan(fromCamera: false),
                    onStartRecording: _startRecording,
                    onStopRecording: () =>
                        ref.read(chatProvider.notifier).stopAndSendVoice(),
                    onShowUsageDetails: () => _showUsageDetails(usageData),
                  );
                },
              ),
            ],
          ),
          if (isScanning) const ChatScanningOverlay(),
        ],
      ),
    );
  }

  Future<void> _loadAiGuidePromptState() async {
    final seen = await AppPreferences.isAiGuidePromptSeen();
    if (!mounted) {
      return;
    }

    setState(() {
      _aiGuidePromptSeen = seen;
    });
  }

  Future<void> _openAiGuide() async {
    await _markAiGuidePromptSeen();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(buildAppRoute(const AiGuideScreen()));
  }

  Future<void> _dismissAiGuidePrompt() async {
    await _markAiGuidePromptSeen();
  }

  Future<void> _markAiGuidePromptSeen() async {
    if (_aiGuidePromptSeen) {
      return;
    }

    await AppPreferences.setAiGuidePromptSeen(true);
    if (!mounted) {
      return;
    }

    setState(() {
      _aiGuidePromptSeen = true;
    });
  }

  void _syncInputFocusState() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isInputFocused = _messageFocusNode.hasFocus;
    });
  }

  void _handleMessageInputChanged() {
    final text = _messageController.text;
    _characterCountNotifier.value = text.length;
    if (text.isNotEmpty) {
      _scrollToBottom();
    }
  }

  void _dismissRagBanner() {
    setState(() {
      _ragBannerDismissed = true;
    });
  }

  void _dismissNearLimitBanner() {
    setState(() {
      _chatLimitBannerDismissed = true;
    });
  }

  void _applySuggestion(ChatSuggestion suggestion) {
    final draft = suggestion.draftText;
    _messageController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    _messageFocusNode.requestFocus();
    _scrollToBottom(force: true);
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
