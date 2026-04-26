import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../core/premium/premium_providers.dart';
import '../../core/premium/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bangla_formatters.dart';
import '../../core/widgets/widgets.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _selectedProductId;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final premiumService = ref.read(premiumServiceProvider);
    final premiumStatusAsync = ref.watch(premiumStatusProvider);
    final premiumStatus = premiumStatusAsync.valueOrNull;
    final isPremium = premiumStatus?.isPremium ?? false;
    final offeringsAsync = ref.watch(premiumOfferingsProvider);
    final configurationWarning = premiumService.configurationWarningBn;
    final isTestStore = premiumService.isUsingTestStore;

    return AppPageScaffold(
      title: 'Premium',
      useGradientBackground: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        child: AppStaggeredList(
          children: [
            const AppHeroCard(
              label: 'PocketPilot AI Premium',
              amount: 'সীমাহীন AI',
              subtitle: 'সব বাধা দূর করুন',
              icon: Icons.star_rounded,
              gradient: AppGradients.primary,
              height: 188,
            ),
            if (configurationWarning != null) ...[
              const SizedBox(height: AppSpacing.md),
              _RevenueCatWarningCard(
                message: configurationWarning,
                isTestStore: isTestStore,
              ),
            ],
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'কী পাবেন'),
            const SizedBox(height: AppSpacing.md),
            const _FeatureComparisonCard(),
            const SizedBox(height: AppSpacing.sectionGap),
            if (isPremium && premiumStatus != null)
              _ActivePremiumCard(status: premiumStatus)
            else ...[
              const AppSectionHeader(title: 'মূল্য তালিকা'),
              const SizedBox(height: AppSpacing.md),
              offeringsAsync.when(
                loading: () => const _PricingLoadingState(),
                error: (error, stackTrace) => _OfferingsErrorCard(
                  onRetry: () => ref.invalidate(premiumOfferingsProvider),
                ),
                data: (packages) {
                  if (packages.isEmpty) {
                    return _OfferingsEmptyCard(
                      warningMessage: configurationWarning,
                      onRetry: () => ref.invalidate(premiumOfferingsProvider),
                    );
                  }

                  final selectedPackage = _resolveSelectedPackage(packages);
                  final monthlyPackage = _findPackage(
                    packages,
                    isYearly: false,
                  );
                  final yearlyPackage = _findPackage(packages, isYearly: true);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useColumn = constraints.maxWidth < 420;
                          final cards = [
                            if (monthlyPackage != null)
                              _PricingCard(
                                package: monthlyPackage,
                                isSelected:
                                    selectedPackage?.productId ==
                                    monthlyPackage.productId,
                                recommended: false,
                                onTap: () => _selectPackage(monthlyPackage),
                              ),
                            if (yearlyPackage != null)
                              _PricingCard(
                                package: yearlyPackage,
                                isSelected:
                                    selectedPackage?.productId ==
                                    yearlyPackage.productId,
                                recommended: true,
                                onTap: () => _selectPackage(yearlyPackage),
                              ),
                          ];

                          if (useColumn) {
                            return Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < cards.length;
                                  index++
                                ) ...[
                                  cards[index],
                                  if (index != cards.length - 1)
                                    const SizedBox(height: AppSpacing.md),
                                ],
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                var index = 0;
                                index < cards.length;
                                index++
                              ) ...[
                                Expanded(child: cards[index]),
                                if (index != cards.length - 1)
                                  const SizedBox(width: AppSpacing.md),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AppActionButton(
                        label: 'Premium শুরু করুন',
                        icon: Icons.star_rounded,
                        fullWidth: true,
                        isLoading: _isPurchasing,
                        onPressed: selectedPackage == null || _isRestoring
                            ? null
                            : () => _purchase(selectedPackage),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: TextButton(
                          onPressed: _isPurchasing || _isRestoring
                              ? null
                              : _restore,
                          child: _isRestoring
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('আগের purchase রিস্টোর করুন'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Subscription Google Play দ্বারা পরিচালিত। যেকোনো সময় cancel করা যাবে।',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  PremiumPackage? _resolveSelectedPackage(List<PremiumPackage> packages) {
    for (final package in packages) {
      if (package.productId == _selectedProductId) {
        return package;
      }
    }
    return _findPackage(packages, isYearly: true) ??
        (packages.isEmpty ? null : packages.first);
  }

  PremiumPackage? _findPackage(
    List<PremiumPackage> packages, {
    required bool isYearly,
  }) {
    for (final package in packages) {
      if (package.isYearly == isYearly) {
        return package;
      }
    }
    return null;
  }

  void _selectPackage(PremiumPackage package) {
    setState(() {
      _selectedProductId = package.productId;
    });
  }

  Future<void> _purchase(PremiumPackage _) async {
    setState(() {
      _isPurchasing = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded('premium');
      if (!mounted) {
        return;
      }

      switch (result) {
        case PaywallResult.purchased:
        case PaywallResult.restored:
          await ref.read(premiumStatusProvider.notifier).refresh();
          if (!mounted) {
            return;
          }
          messenger.showSnackBar(
            const SnackBar(content: Text('🎉 Premium সক্রিয় হয়েছে!')),
          );
          Navigator.of(context).pop();
          break;
        case PaywallResult.notPresented:
          messenger.showSnackBar(
            const SnackBar(content: Text('আপনি ইতিমধ্যে Premium সদস্য')),
          );
          break;
        case PaywallResult.cancelled:
          break;
        case PaywallResult.error:
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Paywall খোলা যায়নি, আবার চেষ্টা করুন'),
            ),
          );
          break;
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Paywall খোলা যায়নি, আবার চেষ্টা করুন'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(premiumStatusProvider.notifier).restore();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRestoring = false;
    });

    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchase রিস্টোর হয়েছে')),
      );
      return;
    }
    if (result.isCancelled) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(result.errorMessage ?? 'রিস্টোর ব্যর্থ হয়েছে'),
      ),
    );
  }
}

class _FeatureComparisonCard extends StatelessWidget {
  const _FeatureComparisonCard();

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ('AI চ্যাট', '২০/দিন', '✓ সীমাহীন'),
      ('রিসিট স্ক্যান', '৫/দিন', '✓ সীমাহীন'),
      ('ভয়েস ইনপুট', '১০/দিন', '✓ সীমাহীন'),
      ('AI বাজেট', '৩/মাস', '✓ সীমাহীন'),
      ('ক্লাউড ব্যাকআপ', 'ম্যানুয়াল', '✓ স্বয়ংক্রিয়'),
    ];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 72,
                child: Text(
                  'ফ্রি',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 92,
                child: Text(
                  'Premium ⭐',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < rows.length; index++) ...[
            _FeatureComparisonRow(
              name: rows[index].$1,
              freeValue: rows[index].$2,
              premiumValue: rows[index].$3,
            ),
            if (index != rows.length - 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: context.borderColor.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _FeatureComparisonRow extends StatelessWidget {
  const _FeatureComparisonRow({
    required this.name,
    required this.freeValue,
    required this.premiumValue,
  });

  final String name;
  final String freeValue;
  final String premiumValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            freeValue,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 92,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  premiumValue.replaceFirst('✓ ', ''),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingLoadingState extends StatelessWidget {
  const _PricingLoadingState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < 420;
        if (useColumn) {
          return const Column(
            children: [
              AppLoadingState.card(height: 180),
              SizedBox(height: AppSpacing.md),
              AppLoadingState.card(height: 196),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(child: AppLoadingState.card(height: 180)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: AppLoadingState.card(height: 196)),
          ],
        );
      },
    );
  }
}

class _RevenueCatWarningCard extends StatelessWidget {
  const _RevenueCatWarningCard({
    required this.message,
    required this.isTestStore,
  });

  final String message;
  final bool isTestStore;

  @override
  Widget build(BuildContext context) {
    final accent = isTestStore ? AppColors.warning : AppColors.error;
    return AppCard(
      gradient: LinearGradient(
        colors: [
          accent.withValues(alpha: context.isDarkMode ? 0.22 : 0.12),
          context.cardBackgroundColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isTestStore ? Icons.science_rounded : Icons.error_outline_rounded,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
                height: 1.4,
                fontWeight: isTestStore ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferingsErrorCard extends StatelessWidget {
  const _OfferingsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: AppErrorState(
        compact: true,
        message: 'মূল্য তালিকা এখন লোড করা যাচ্ছে না',
        onRetry: onRetry,
      ),
    );
  }
}

class _OfferingsEmptyCard extends StatelessWidget {
  const _OfferingsEmptyCard({required this.onRetry, this.warningMessage});

  final VoidCallback onRetry;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 30,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'এই মুহূর্তে কোনো প্যাকেজ পাওয়া যাচ্ছে না',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            warningMessage ??
                'Play Store বা RevenueCat সংযোগ ঠিক থাকলে আবার চেষ্টা করুন',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppActionButton(
            label: 'আবার চেষ্টা করুন',
            variant: AppActionButtonVariant.ghost,
            fullWidth: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.package,
    required this.isSelected,
    required this.recommended,
    required this.onTap,
  });

  final PremiumPackage package;
  final bool isSelected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? context.appColors.primary
        : context.borderColor.withValues(alpha: 0.45);

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: recommended && isSelected ? AppGradients.primary : null,
        color: recommended && !isSelected
            ? context.appColors.primary.withValues(alpha: 0.06)
            : null,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
      ),
      child: AppCard(
        elevation: 0,
        onTap: onTap,
        gradient: recommended
            ? LinearGradient(
                colors: [
                  context.appColors.primary.withValues(
                    alpha: context.isDarkMode ? 0.28 : 0.16,
                  ),
                  context.cardBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.period,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                if (recommended)
                  const AppChip(
                    label: 'সেরা মূল্য',
                    color: AppColors.success,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              package.priceString,
              style: AppTextStyles.displayMedium.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (package.currencyCode.toUpperCase() != 'BDT') ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'স্টোর মুদ্রা: ${package.currencyCode}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              package.isYearly ? 'প্রতি বছরে' : 'প্রতি মাসে',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            if (recommended) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'দীর্ঘমেয়াদে বেশি সাশ্রয়ী',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivePremiumCard extends StatelessWidget {
  const _ActivePremiumCard({required this.status});

  final PremiumStatus status;

  @override
  Widget build(BuildContext context) {
    final expiryText = status.isLifetime
        ? 'মেয়াদ: আজীবন'
        : status.expiryDate != null
        ? 'মেয়াদ: ${BanglaFormatters.fullDate(status.expiryDate!)}'
        : 'মাসিক নবায়নযোগ্য';

    return AppCard(
      gradient: LinearGradient(
        colors: [
          AppColors.success.withValues(alpha: context.isDarkMode ? 0.22 : 0.14),
          context.cardBackgroundColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'আপনি Premium সদস্য',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            expiryText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Google Play থেকে subscription manage করুন',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
