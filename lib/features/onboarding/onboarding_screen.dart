import 'package:flutter/material.dart';

import '../../core/navigation/app_page_route.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../wallet/presentation/screens/wallet_management_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingData(
      emoji: '💰',
      gradient: AppGradients.primary,
      title: 'স্বাগতম!',
      subtitle:
          'PocketPilot AI দিয়ে খরচ হিসাব রাখুন। Chat help থেকে AI Guide দেখুন',
      bullets: const [
        (emoji: '🤖', text: 'AI দিয়ে খরচ যোগ করুন'),
        (emoji: '🎤', text: 'ভয়েস দিয়ে খরচ যোগ করুন'),
        (emoji: '📸', text: 'রিসিট স্ক্যান করে খরচ যোগ করুন'),
      ],
    ),
    _OnboardingData(
      emoji: '📊',
      gradient: AppGradients.success,
      title: 'স্মার্ট ইনসাইট',
      subtitle: 'আপনার খরচের প্যাটার্ন বুঝে সিদ্ধান্ত নিন',
      bullets: const [
        (emoji: '📈', text: 'মাসিক বিশ্লেষণ দেখুন'),
        (emoji: '🎯', text: 'লক্ষ্য নির্ধারণ করুন'),
        (emoji: '⚠️', text: 'অস্বাভাবিক খরচ সনাক্ত করুন'),
      ],
    ),
    _OnboardingData(
      emoji: '🔒',
      gradient: AppGradients.walletTeal,
      title: 'আপনার ডেটা, আপনার নিয়ন্ত্রণে',
      subtitle: 'সব ডেটা আপনার ফোনে সুরক্ষিত থাকে',
      bullets: const [
        (emoji: '🔐', text: 'লোকাল স্টোরেজ'),
        (emoji: '👆', text: 'বায়োমেট্রিক লক'),
        (emoji: '📤', text: 'যেকোনো সময় এক্সপোর্ট করুন'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (value) {
                          setState(() {
                            _currentPage = value;
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return _OnboardingPage(
                            data: page,
                            isActive: index == _currentPage,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final active = index == _currentPage;
                        return AnimatedContainer(
                          duration: AppMotion.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? context.appColors.primary
                                : context.borderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: isLastPage
                              ? const SizedBox.shrink(
                                  key: ValueKey('skip-hidden'),
                                )
                              : TextButton(
                                  key: const ValueKey('skip-visible'),
                                  onPressed: () => _complete(),
                                  child: const Text('এড়িয়ে যান'),
                                ),
                        ),
                        const Spacer(),
                        AppActionButton(
                          label: isLastPage ? 'শুরু করুন' : 'পরবর্তী',
                          icon: isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          onPressed: isLastPage
                              ? () => _complete(showWalletPrompt: true)
                              : _nextPage,
                          variant: AppActionButtonVariant.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _complete({bool showWalletPrompt = false}) async {
    await AppPreferences.setOnboardingComplete(true);
    final shouldShowWalletPrompt =
        showWalletPrompt && !await AppPreferences.isFirstWalletPromptSeen();
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    widget.onComplete();
    if (!shouldShowWalletPrompt) {
      return;
    }

    final action = await showDialog<_WalletPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('প্রথম ওয়ালেট যোগ করবেন?'),
          content: const Text(
            'শুরু করার আগে একটি ওয়ালেট যোগ করলে খরচ ট্র্যাক করা সহজ হবে।',
          ),
          actions: [
            AppActionButton(
              label: 'পরে করব',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_WalletPromptAction.skip),
            ),
            AppActionButton(
              label: 'এখন যোগ করুন',
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_WalletPromptAction.addNow),
            ),
          ],
        );
      },
    );

    await AppPreferences.setFirstWalletPromptSeen(true);
    if (!navigator.mounted || action != _WalletPromptAction.addNow) {
      return;
    }

    await navigator.push(
      AppSlideRoute(builder: (_) => const WalletManagementScreen()),
    );
  }

  Future<void> _nextPage() async {
    await _pageController.nextPage(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.isActive});

  final _OnboardingData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: AppStaggeredList(
          key: ValueKey('${data.title}_$isActive'),
          initialDelay: const Duration(milliseconds: 50),
          children: [
            AppFadeSlideIn(
              offset: const Offset(0, 0.12),
              child: Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: data.gradient,
                    shape: BoxShape.circle,
                    boxShadow: context.elevationLevel(3),
                  ),
                  child: Center(
                    child: Text(
                      data.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppFadeSlideIn(
              offset: const Offset(0, 0.12),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heroAmount.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFadeSlideIn(
              offset: const Offset(0, 0.12),
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionSubtitle.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppStaggeredList(
              initialDelay: const Duration(milliseconds: 100),
              staggerDelay: const Duration(milliseconds: 80),
              children: [
                for (final bullet in data.bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.appColors.primary.withValues(
                              alpha: context.isDarkMode ? 0.18 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(bullet.emoji),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bullet.text,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final LinearGradient gradient;
  final List<({String emoji, String text})> bullets;
}

enum _WalletPromptAction { addNow, skip }
