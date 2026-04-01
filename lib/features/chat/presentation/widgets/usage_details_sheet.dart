import 'package:flutter/material.dart';

import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';

class UsageOverviewData {
  const UsageOverviewData({
    required this.todayUsedTokens,
    required this.remainingTokens,
    required this.dailyTokenBudget,
    required this.requestsUsedToday,
    required this.requestsRemainingToday,
    required this.dailyRequestLimit,
    required this.localUsagePercent,
    this.liveRateLimit,
    this.lastUsage,
  });

  final int todayUsedTokens;
  final int remainingTokens;
  final int dailyTokenBudget;
  final int requestsUsedToday;
  final int requestsRemainingToday;
  final int dailyRequestLimit;
  final int localUsagePercent;
  final RateLimitSnapshot? liveRateLimit;
  final TokenUsage? lastUsage;
}

class UsageDetailsSheet extends StatelessWidget {
  const UsageDetailsSheet({super.key, required this.data});

  final UsageOverviewData data;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Token Usage',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Today\'s usage and local OpenAI estimate summary.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (data.liveRateLimit?.hasLiveData ?? false) ...[
              _LiveUsageCard(snapshot: data.liveRateLimit!),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Used today',
                    value: _formatCompactNumber(data.todayUsedTokens),
                    footer: 'local total',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Local usage',
                    value: '${data.localUsagePercent}%',
                    footer: 'est. progress',
                    accent: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Daily budget',
                    value: _formatCompactNumber(data.dailyTokenBudget),
                    footer: 'local target',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Ref. left',
                    value: data.requestsRemainingToday.toString(),
                    footer: 'of ${data.dailyRequestLimit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last response',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (data.lastUsage == null)
                      const Text(
                        'No token usage data yet.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (data.lastUsage!.isEstimated)
                            const _MiniChip(label: 'Estimated'),
                          _MiniChip(
                            label: 'Input ${data.lastUsage!.promptTokens}',
                          ),
                          _MiniChip(
                            label: 'Output ${data.lastUsage!.outputTokens}',
                          ),
                          _MiniChip(
                            label: 'Total ${data.lastUsage!.totalTokens}',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Used requests today: ${data.requestsUsedToday}',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.liveRateLimit?.hasLiveData ?? false
                  ? 'Live rate-limit numbers come from OpenAI response headers. Daily usage numbers are still local estimates for your own budgeting.'
                  : 'These numbers are local estimates. Live OpenAI remaining-limit details will appear after a successful request returns rate-limit headers.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }
}

class _LiveUsageCard extends StatelessWidget {
  const _LiveUsageCard({required this.snapshot});

  final RateLimitSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final usedPercent = snapshot.dominantUsagePercent ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OpenAI live window',
                    style: const TextStyle(
                      color: Color(0xFF312E81),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _MiniChip(label: snapshot.sourceLabel),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$usedPercent%',
              style: const TextStyle(
                color: Color(0xFF312E81),
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'used in the current OpenAI rate-limit window',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (usedPercent / 100).clamp(0, 1),
                backgroundColor: const Color(0xFFC7D2FE),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (snapshot.limitRequests != null &&
                    snapshot.remainingRequests != null)
                  _MiniChip(
                    label:
                        'Req ${snapshot.remainingRequests}/${snapshot.limitRequests}',
                  ),
                if (snapshot.limitTokens != null &&
                    snapshot.remainingTokens != null)
                  _MiniChip(
                    label:
                        'Tok ${UsageDetailsSheet._formatCompactNumber(snapshot.remainingTokens!)}'
                        '/${UsageDetailsSheet._formatCompactNumber(snapshot.limitTokens!)}',
                  ),
                if (snapshot.resetRequests != null)
                  _MiniChip(label: 'Req reset ${snapshot.resetRequests}'),
                if (snapshot.resetTokens != null)
                  _MiniChip(label: 'Tok reset ${snapshot.resetTokens}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.footer,
    this.accent = false,
  });

  final String label;
  final String value;
  final String footer;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accent
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              footer,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
