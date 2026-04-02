import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/assets/app_icon.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);

    unawaited(_controller.forward());
    Timer(const Duration(milliseconds: 2000), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    children: [
                      const SmartSpendLogo(
                        size: 88,
                        showShadow: true,
                        borderRadius: BorderRadius.all(AppRadius.xl),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(AppStrings.appName, style: textTheme.displayMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(AppStrings.tagline, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(AppStrings.poweredBy, style: textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
