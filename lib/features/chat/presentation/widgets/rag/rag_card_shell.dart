import 'package:flutter/material.dart';

class RagAnimatedCard extends StatefulWidget {
  const RagAnimatedCard({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  State<RagAnimatedCard> createState() => _RagAnimatedCardState();
}

class _RagAnimatedCardState extends State<RagAnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.borderColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.24);
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).cardColor;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class RagCardHeader extends StatelessWidget {
  const RagCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final iconBackground = primary.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.12,
    );

    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RagFooter extends StatelessWidget {
  const RagFooter({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storage_rounded, size: 14, color: primary),
            const SizedBox(width: 6),
            Text(
              'আপনার data থেকে',
              style: TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
          ],
        ),
      ),
    );
  }
}

class AnimatedCategoryBar extends StatelessWidget {
  const AnimatedCategoryBar({
    super.key,
    required this.label,
    required this.amountLabel,
    required this.percentLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String amountLabel;
  final String percentLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountLabel,
              style: TextStyle(
                color: onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentLabel,
              style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.1,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }
}
