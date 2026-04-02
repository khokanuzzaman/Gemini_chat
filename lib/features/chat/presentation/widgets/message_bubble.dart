import 'package:flutter/material.dart';

import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import 'rag/rag_category_widget.dart';
import 'rag/rag_comparison_widget.dart';
import 'rag/rag_summary_widget.dart';
import 'rag/rag_today_widget.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isReceipt = false,
    this.isVoice = false,
    this.isError = false,
    this.isRag = false,
    this.ragData,
    this.onLongPress,
    this.onOpenAnalytics,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isReceipt;
  final bool isVoice;
  final bool isError;
  final bool isRag;
  final RagResponseData? ragData;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    if (!isUser && isRag && ragData != null) {
      final widget = _buildRagWidget();
      if (widget != null) {
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.92,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget,
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      color: context.secondaryTextColor.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final bubbleColor = isError
        ? context.errorBubbleColor
        : isUser
        ? context.userBubbleColor
        : context.aiBubbleColor;
    final textColor = isError
        ? context.errorBubbleTextColor
        : isUser
        ? context.userBubbleTextColor
        : context.aiBubbleTextColor;

    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isError
                  ? Border(
                      left: BorderSide(
                        color: context.errorBubbleBorderColor,
                        width: 3,
                      ),
                    )
                  : null,
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isError) ...[
                    Padding(
                      padding: EdgeInsets.only(right: 8, top: 2),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: context.errorBubbleBorderColor,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isReceipt)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_camera_rounded,
                                    size: 16,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.receiptScanned,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      height: 1.45,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.receiptSource,
                                style: AppTextStyles.caption.copyWith(
                                  color: isUser
                                      ? context.userBubbleTextColor.withValues(
                                          alpha: 0.72,
                                        )
                                      : context.secondaryTextColor,
                                ),
                              ),
                            ],
                          )
                        else if (isVoice)
                          _buildVoiceContent(context, textColor)
                        else if (isUser)
                          Text(
                            text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          )
                        else
                          SelectableText(
                            text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final content = (!isRag || isUser)
        ? bubble
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bubble,
              const SizedBox(height: 6),
              const _RagIndicatorChip(),
            ],
          );

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        content,
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(_formatTime(createdAt), style: AppTextStyles.caption),
        ),
      ],
    );
  }

  Widget? _buildRagWidget() {
    final data = ragData!;
    if (onOpenAnalytics == null) {
      return null;
    }

    return switch (data.type) {
      RagResponseType.monthlySummary => RagSummaryWidget(
        data: data,
        onOpenAnalytics: onOpenAnalytics!,
      ),
      RagResponseType.categoryBreakdown => RagCategoryWidget(
        data: data,
        onOpenAnalytics: onOpenAnalytics!,
      ),
      RagResponseType.comparison => RagComparisonWidget(
        data: data,
        onOpenAnalytics: onOpenAnalytics!,
      ),
      RagResponseType.todaySummary => RagTodayWidget(
        data: data,
        onOpenAnalytics: onOpenAnalytics!,
      ),
      RagResponseType.general => null,
    };
  }

  String _formatTime(DateTime dateTime) {
    return BanglaFormatters.time(dateTime).toUpperCase();
  }

  Widget _buildVoiceContent(BuildContext context, Color textColor) {
    final transcript = _voiceTranscriptText(text);
    final labelColor = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.9)
        : context.primaryTextColor;
    final captionColor = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.72)
        : context.secondaryTextColor;
    final iconBackground = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.18)
        : context.cardBackgroundColor;
    final iconColor = isUser
        ? context.userBubbleTextColor
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.voiceMessageLabel,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transcript.isNotEmpty)
          Text(
            transcript,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            AppStrings.transcriptHidden,
            style: AppTextStyles.caption.copyWith(color: captionColor),
          ),
      ],
    );
  }

  String _voiceTranscriptText(String rawText) {
    final cleaned = rawText.replaceFirst(RegExp(r'^🎤\s*'), '').trim();

    if (cleaned.isEmpty ||
        cleaned == 'Voice message' ||
        cleaned == 'ভয়েস মেসেজ') {
      return '';
    }

    return cleaned;
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
