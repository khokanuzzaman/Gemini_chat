import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/ai/expense_parser.dart';
import '../../../../core/ai/expense_result.dart';
import '../../../../core/ai/income_data.dart';
import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import '../../../split/presentation/screens/add_edit_split_screen.dart';
import '../../../split/presentation/widgets/split_suggestion_widget.dart';
import '../utils/message_key.dart';
import 'chat_empty_state.dart';
import 'chat_status_widgets.dart';
import 'expense_confirmation_widget.dart';
import 'income_confirmation_widget.dart';
import 'message_bubble.dart';
import 'multiple_expense_confirmation_widget.dart';
import 'multiple_income_confirmation_widget.dart';
import 'receipt_confirmation_widget.dart';
import 'typing_indicator.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
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
    required this.showAiGuidePrompt,
    required this.onOpenAiGuide,
    required this.onDismissAiGuidePrompt,
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
  final bool showAiGuidePrompt;
  final VoidCallback onOpenAiGuide;
  final VoidCallback onDismissAiGuidePrompt;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static const _expenseParser = ExpenseParser();
  final Set<String> _dismissedCards = <String>{};

  @override
  void initState() {
    super.initState();
    _loadDismissedCards();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isResponding) {
      return ChatEmptyState(
        showAiGuidePrompt: widget.showAiGuidePrompt,
        onOpenAiGuide: widget.onOpenAiGuide,
        onDismissAiGuidePrompt: widget.onDismissAiGuidePrompt,
      );
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
    final visibleStreamingText = streamingText == null
        ? ''
        : _expenseParser.extractVisibleStreamingText(streamingText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        visibleStreamingText.isEmpty
            ? const TypingIndicatorWidget()
            : MessageBubble(
                key: const ValueKey('streaming-message-bubble'),
                text: visibleStreamingText,
                isUser: false,
                createdAt: DateTime.now(),
                isStreaming: true,
                animationIdentity: 'streaming-message-bubble',
              ),
        if (widget.isStreamingWithRag) ...[
          const SizedBox(height: 6),
          const ChatRagIndicatorChip(),
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
        final conversationalText = _expenseParser.extractVisibleReplyText(
          expenseResult.conversationalText ?? '',
        );
        final hasSplitExpense =
            expenseResult.isSplit ||
            expenseResult.expenses.any((expense) => expense.isSplit);
        var resolvedSplitPersons = expenseResult.splitPersons;
        if (resolvedSplitPersons == null) {
          for (final expense in expenseResult.expenses) {
            if (expense.splitPersons != null) {
              resolvedSplitPersons = expense.splitPersons;
              break;
            }
          }
        }

        if (conversationalText.isNotEmpty) {
          parts.add(
            MessageBubble(
              key: ValueKey('conversational-$messageKey'),
              text: conversationalText,
              isUser: false,
              createdAt: message.createdAt,
              onLongPress: () => widget.onCopyAiMessage(conversationalText),
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
                  await _dismissCard(messageKey);
                },
                onCancel: () {
                  unawaited(_dismissCard(messageKey));
                },
              ),
            );
          } else if (hasSplitExpense && expenseResult.expenses.isNotEmpty) {
            final splitExpense = expenseResult.expenses.first;
            final splitPersons =
                (resolvedSplitPersons ?? splitExpense.splitPersons ?? 2)
                    .clamp(2, 12);
            parts.add(
              SplitSuggestionWidget(
                expense: splitExpense,
                personCount: splitPersons,
                onSaveOnly: () async {
                  await widget.onSaveExpense(splitExpense);
                  await _dismissCard(messageKey);
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
                  await _dismissCard(messageKey);
                },
                onCancel: () {
                  unawaited(_dismissCard(messageKey));
                },
              ),
            );
          } else if (expenseResult.expenses.isNotEmpty) {
            parts.add(
              ExpenseConfirmationWidget(
                expense: expenseResult.expenses.first,
                onSave: (editedExpense, walletId) async {
                  await widget.onSaveExpense(editedExpense, walletId);
                  await _dismissCard(messageKey);
                },
                onCancel: () {
                  unawaited(_dismissCard(messageKey));
                },
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
                    await _dismissCard(messageKey);
                  },
                  onCancel: () {
                    unawaited(_dismissCard(messageKey));
                  },
                ),
              );
            } else {
              parts.add(
                IncomeConfirmationWidget(
                  income: expenseResult.incomes.first,
                  onSave: (editedIncome, walletId) async {
                    await widget.onSaveIncome(editedIncome, walletId);
                    await _dismissCard(messageKey);
                  },
                  onCancel: () {
                    unawaited(_dismissCard(messageKey));
                  },
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

    final visibleText = message.isUser || message.isError
        ? message.text
        : _expenseParser.extractVisibleReplyText(message.text);
    if (!message.isUser && !message.isError && visibleText.isEmpty) {
      return const SizedBox.shrink();
    }

    final bubble = MessageBubble(
      key: ValueKey(message.id ?? message.createdAt.microsecondsSinceEpoch),
      text: visibleText,
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
          : () => widget.onCopyAiMessage(visibleText),
      onOpenAnalytics: widget.onOpenAnalytics,
    );

    if (message.isUser || message.isRag || !message.usedRagContext) {
      return bubble;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bubble,
        const SizedBox(height: 6),
        const ChatRagIndicatorChip(),
      ],
    );
  }

  Future<void> _loadDismissedCards() async {
    final storedKeys = await AppPreferences.handledChatCardKeys();
    if (!mounted || storedKeys.isEmpty) {
      return;
    }
    setState(() {
      _dismissedCards.addAll(storedKeys);
    });
  }

  Future<void> _dismissCard(String key) async {
    setState(() {
      _dismissedCards.add(key);
    });
    await AppPreferences.addHandledChatCardKey(key);
  }

  String _messageKey(MessageEntity message) {
    return buildChatMessageKey(message);
  }
}
