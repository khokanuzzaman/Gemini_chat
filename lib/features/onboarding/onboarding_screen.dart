import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/assets/app_icon.dart';
import '../../core/navigation/app_page_route.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/sms/sms_permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../wallet/presentation/screens/wallet_management_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _smsPageIndex = 1;

  final _pages = [
    _OnboardingData(
      emoji: '💰',
      showLogo: true,
      gradient: AppGradients.primary,
      title: 'বাংলায় টাকার হিসাব,\nপ্রায় নিজে নিজেই',
      subtitle: 'কষ্ট ছাড়াই খরচ ও আয় ট্র্যাক করুন — বাংলায়।',
      bullets: const [
        (emoji: '📥', text: 'bKash/নগদ/ব্যাংক SMS থেকে স্বয়ংক্রিয় হিসাব'),
        (emoji: '✍️', text: 'ম্যানুয়ালি দ্রুত খরচ ও আয় যোগ'),
        (emoji: '👛', text: 'একাধিক ওয়ালেট ও ব্যালেন্স একসাথে'),
      ],
    ),
    _OnboardingData(
      emoji: '📩',
      gradient: AppGradients.success,
      title: 'SMS পড়ে হিসাব —\nনিজে নিজেই',
      subtitle:
          'bKash, নগদ, রকেট ও ব্যাংকের SMS পড়ে আমরা লেনদেন স্বয়ংক্রিয়ভাবে ধরি। টাইপ করার ঝামেলা নেই।',
      privacyNote:
          'আপনার SMS ফোনেই পড়া হয়; মেসেজের লেখা সংরক্ষণ বা আপলোড করা হয় না।',
      bullets: const [
        (emoji: '⚡', text: 'নতুন লেনদেন সাথে সাথে ধরা পড়ে'),
        (emoji: '🏦', text: 'bKash · নগদ · রকেট · ব্যাংক'),
      ],
    ),
    _OnboardingData(
      emoji: '👛',
      gradient: AppGradients.walletTeal,
      title: 'আপনার ওয়ালেট সেট করুন',
      subtitle: 'ক্যাশ, বিকাশ, নগদ বা ব্যাংক — ব্যালেন্স যোগ করে শুরু করুন।',
      bullets: const [
        (emoji: '💵', text: 'ক্যাশ ও মোবাইল ব্যাংকিং একসাথে'),
        (emoji: '⚖️', text: 'ব্যালেন্স সবসময় মিলে যায়'),
        (emoji: '📱', text: 'সব ডেটা আপনার ফোনেই থাকে'),
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
                    _buildActionRow(isLastPage: isLastPage),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({required bool isLastPage}) {
    final isSmsPage = _currentPage == _smsPageIndex;

    // Secondary (left): a clearly-visible skip that always reaches a fully
    // working app — never a dark pattern. "পরে করব" on the SMS page advances
    // without granting; "এড়িয়ে যান" on info pages finishes onboarding.
    final Widget secondary;
    if (isSmsPage) {
      secondary = TextButton(
        onPressed: _nextPage,
        child: const Text('পরে করব'),
      );
    } else if (!isLastPage) {
      secondary = TextButton(
        onPressed: () => _complete(),
        child: const Text('এড়িয়ে যান'),
      );
    } else {
      secondary = const SizedBox.shrink();
    }

    return Row(
      children: [
        secondary,
        const Spacer(),
        AppActionButton(
          label: isSmsPage
              ? 'SMS অ্যাক্সেস দিন'
              : (isLastPage ? 'শুরু করুন' : 'পরবর্তী'),
          icon: isSmsPage
              ? Icons.sms_rounded
              : (isLastPage
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded),
          onPressed: isSmsPage
              ? _requestSmsThenNext
              : (isLastPage
                    ? () => _complete(showWalletPrompt: true)
                    : _nextPage),
          variant: AppActionButtonVariant.primary,
        ),
      ],
    );
  }

  Future<void> _requestSmsThenNext() async {
    // Inline activation moment: fire the native READ_SMS dialog here. Whatever
    // the user chooses, we advance — denial is fully graceful (the app works via
    // manual entry, and SMS import can be granted later from its own screen).
    final granted = await const SmsPermissionHandler().requestPermission();
    ref.read(usageAnalyticsProvider).smsPermissionResult(granted: granted);
    if (!mounted) {
      return;
    }
    await _nextPage();
  }

  Future<void> _complete({bool showWalletPrompt = false}) async {
    await AppPreferences.setOnboardingComplete(true);
    ref.read(usageAnalyticsProvider).onboardingComplete();
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
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_WalletPromptAction.skip),
            ),
            AppActionButton(
              label: 'এখন যোগ করুন',
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_WalletPromptAction.addNow),
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
                child: data.showLogo
                    ? const PocketPilotLogo(size: 160, showShadow: true)
                    : Container(
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
            if (data.privacyNote != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppFadeSlideIn(
                offset: const Offset(0, 0.12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.appColors.primary.withValues(
                      alpha: context.isDarkMode ? 0.16 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.appColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 20,
                        color: context.appColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.privacyNote!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    this.showLogo = false,
    required this.bullets,
    this.privacyNote,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final LinearGradient gradient;

  /// The welcome page shows the app mark instead of an emoji.
  final bool showLogo;
  final List<({String emoji, String text})> bullets;

  /// Optional prominent on-device privacy line (used on the SMS pitch screen).
  final String? privacyNote;
}

enum _WalletPromptAction { addNow, skip }
