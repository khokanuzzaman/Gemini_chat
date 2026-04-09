import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/assets/app_icon.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showIcon = false;
  bool _showName = false;
  bool _showTagline = false;
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();
    unawaited(_scheduleAnimations());
    Timer(const Duration(milliseconds: 2000), widget.onFinished);
  }

  Future<void> _scheduleAnimations() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _showIcon = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showName = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showTagline = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showLoader = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.primaryGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _showIcon ? 1 : 0.85,
                      duration: AppMotion.normal,
                      curve: AppMotion.emphasized,
                      child: AnimatedOpacity(
                        opacity: _showIcon ? 1 : 0,
                        duration: AppMotion.normal,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: context.cardBackgroundColor.withValues(
                              alpha: context.isDarkMode ? 0.5 : 0.65,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: context.elevationLevel(3),
                          ),
                          alignment: Alignment.center,
                          child: const PocketPilotLogo(
                            size: 72,
                            showShadow: false,
                            borderRadius: BorderRadius.all(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_showName)
                      AppFadeSlideIn(
                        offset: const Offset(0, 0.15),
                        child: Text(
                          AppStrings.appName,
                          style: AppTextStyles.heroAmount.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_showTagline) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppFadeSlideIn(
                        offset: const Offset(0, 0.15),
                        child: Text(
                          AppStrings.tagline,
                          style: AppTextStyles.heroLabel.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: AnimatedOpacity(
                  opacity: _showLoader ? 1 : 0,
                  duration: AppMotion.fast,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'লোড হচ্ছে...',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
