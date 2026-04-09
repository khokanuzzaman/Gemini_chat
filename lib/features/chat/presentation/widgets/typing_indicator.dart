import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.appColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: context.appColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PocketPilot AI লিখছে',
                style: AppTextStyles.caption.copyWith(
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingDot(delay: Duration.zero),
                  SizedBox(width: 4),
                  _TypingDot(delay: Duration(milliseconds: 200)),
                  SizedBox(width: 4),
                  _TypingDot(delay: Duration(milliseconds: 400)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final Duration delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
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
