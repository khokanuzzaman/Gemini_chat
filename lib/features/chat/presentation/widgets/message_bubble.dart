import 'package:flutter/material.dart';

import '../../../../core/ai/rag_response_parser.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import 'rag/rag_category_widget.dart';
import 'rag/rag_comparison_widget.dart';
import 'rag/rag_summary_widget.dart';
import 'rag/rag_today_widget.dart';
import 'usage_details_sheet.dart';

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
    this.isStreaming = false,
    this.ragData,
    this.onLongPress,
    this.onOpenAnalytics,
    this.promptTokenCount,
    this.outputTokenCount,
    this.totalTokenCount,
    this.animationIdentity,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isReceipt;
  final bool isVoice;
  final bool isError;
  final bool isRag;
  final bool isStreaming;
  final RagResponseData? ragData;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenAnalytics;
  final int? promptTokenCount;
  final int? outputTokenCount;
  final int? totalTokenCount;
  final Object? animationIdentity;

  @override
  Widget build(BuildContext context) {
    final content = _buildBody(context);

    return AppFadeSlideIn(
      key: ValueKey<Object>(_resolvedAnimationIdentity()),
      duration: AppMotion.fast,
      child: content,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!isUser && isRag && ragData != null) {
      final ragWidget = _buildRagWidget();
      if (ragWidget != null) {
        return _buildAiLayout(
          context,
          bubbleChild: ragWidget,
          maxWidthFactor: 0.92,
        );
      }
    }

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: _bubbleDecoration(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildBubbleContent(context),
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

    return isUser
        ? _buildUserLayout(context, bubbleChild: content)
        : _buildAiLayout(context, bubbleChild: content);
  }

  Widget _buildUserLayout(BuildContext context, {required Widget bubbleChild}) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bubbleChild,
            if (!isStreaming && _shouldShowMeta) ...[
              const SizedBox(height: 6),
              _MessageMeta(
                isUser: true,
                timestamp: _formatTime(createdAt),
                timestampColor: _timestampColor(context),
                tokenCount: totalTokenCount,
                onTokenTap: totalTokenCount == null
                    ? null
                    : () => _showUsageDetails(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiLayout(
    BuildContext context, {
    required Widget bubbleChild,
    double maxWidthFactor = 0.78,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiAvatar(isError: isError),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bubbleChild,
                if (!isStreaming && _shouldShowMeta) ...[
                  const SizedBox(height: 6),
                  _MessageMeta(
                    timestamp: _formatTime(createdAt),
                    timestampColor: _timestampColor(context),
                    tokenCount: totalTokenCount,
                    onTokenTap: totalTokenCount == null
                        ? null
                        : () => _showUsageDetails(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _bubbleDecoration(BuildContext context) {
    if (isError) {
      return BoxDecoration(
        color: context.errorBubbleColor,
        borderRadius: const BorderRadius.only(
          topLeft: AppRadius.lg,
          topRight: AppRadius.lg,
          bottomLeft: AppRadius.sm,
          bottomRight: AppRadius.lg,
        ),
        border: Border.all(
          color: context.errorBubbleBorderColor.withValues(alpha: 0.55),
          width: 0.8,
        ),
      );
    }

    if (isUser) {
      return BoxDecoration(
        color: context.userBubbleColor,
        borderRadius: const BorderRadius.only(
          topLeft: AppRadius.lg,
          topRight: AppRadius.lg,
          bottomLeft: AppRadius.lg,
          bottomRight: AppRadius.sm,
        ),
        boxShadow: context.elevationLevel(1),
      );
    }

    return BoxDecoration(
      color: context.aiBubbleColor,
      borderRadius: const BorderRadius.only(
        topLeft: AppRadius.lg,
        topRight: AppRadius.lg,
        bottomLeft: AppRadius.sm,
        bottomRight: AppRadius.lg,
      ),
      border: Border.all(
        color: context.borderColor.withValues(alpha: 0.4),
        width: 0.5,
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    final textColor = isError
        ? context.errorBubbleTextColor
        : isUser
        ? context.userBubbleTextColor
        : context.aiBubbleTextColor;

    if (isReceipt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withValues(alpha: 0.14)
                  : context.ragChipBackgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_rounded, size: 14, color: textColor),
                const SizedBox(width: 6),
                Text(
                  AppStrings.receiptScanned,
                  style: AppTextStyles.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.receiptSource,
            style: AppTextStyles.caption.copyWith(
              color: isUser
                  ? context.userBubbleTextColor.withValues(alpha: 0.72)
                  : context.secondaryTextColor,
            ),
          ),
        ],
      );
    }

    if (isVoice) {
      return _buildVoiceContent(context, textColor);
    }

    final textStyle = AppTextStyles.bodyLarge.copyWith(color: textColor);
    if (isStreaming && !isUser) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(text, style: textStyle),
          const _StreamingCursor(),
        ],
      );
    }

    if (isUser) {
      return Text(text, style: textStyle);
    }

    return SelectableText(text, style: textStyle);
  }

  Widget _buildVoiceContent(BuildContext context, Color textColor) {
    final transcript = _voiceTranscriptText(text);
    final labelColor = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.92)
        : context.aiBubbleTextColor;
    final captionColor = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.72)
        : context.secondaryTextColor;
    final iconBackground = isUser
        ? context.userBubbleTextColor.withValues(alpha: 0.16)
        : context.appColors.primary.withValues(alpha: 0.12);
    final iconColor = isUser
        ? context.userBubbleTextColor
        : context.appColors.primary;

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
              style: AppTextStyles.caption.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transcript.isNotEmpty)
          Text(
            transcript,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor,
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

  Future<void> _showUsageDetails(BuildContext context) {
    final total = totalTokenCount;
    if (total == null) {
      return Future.value();
    }

    final prompt = promptTokenCount ?? 0;
    final output = outputTokenCount ?? (total - prompt).clamp(0, total);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UsageDetailsSheet(
        data: UsageOverviewData(
          todayUsedTokens: total,
          remainingTokens: 0,
          dailyTokenBudget: total,
          requestsUsedToday: 1,
          requestsRemainingToday: 0,
          dailyRequestLimit: 1,
          localUsagePercent: 100,
          lastUsage: TokenUsage(
            promptTokens: prompt,
            outputTokens: output,
            totalTokens: total,
            isEstimated: promptTokenCount == null || outputTokenCount == null,
          ),
        ),
      ),
    );
  }

  Color _timestampColor(BuildContext context) {
    return context.secondaryTextColor.withValues(alpha: 0.72);
  }

  bool get _shouldShowMeta => totalTokenCount != null || !isStreaming;

  String _formatTime(DateTime dateTime) {
    return BanglaFormatters.time(dateTime).toUpperCase();
  }

  Object _resolvedAnimationIdentity() {
    if (animationIdentity != null) {
      return animationIdentity!;
    }

    if (isStreaming) {
      return 'streaming-message-bubble';
    }

    return createdAt.microsecondsSinceEpoch;
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

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? AppColors.error.withValues(alpha: 0.12)
        : context.appColors.primary.withValues(alpha: 0.12);
    final iconColor = isError ? AppColors.error : context.appColors.primary;
    final icon = isError
        ? Icons.warning_amber_rounded
        : Icons.auto_awesome_rounded;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({
    required this.timestamp,
    required this.timestampColor,
    this.tokenCount,
    this.onTokenTap,
    this.isUser = false,
  });

  final String timestamp;
  final Color timestampColor;
  final int? tokenCount;
  final VoidCallback? onTokenTap;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (tokenCount != null)
          AppChip(
            label: '$tokenCount tokens',
            icon: Icons.token_outlined,
            compact: true,
            onTap: onTokenTap,
            color: context.appColors.primary,
          ),
        Text(
          timestamp,
          style: AppTextStyles.caption.copyWith(color: timestampColor),
        ),
      ],
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.3,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: context.appColors.primary,
          shape: BoxShape.circle,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_rounded,
              size: 12,
              color: context.ragChipTextColor,
            ),
            const SizedBox(width: 5),
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
