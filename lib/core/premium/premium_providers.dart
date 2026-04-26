import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'premium_service.dart';

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService();
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref
      .watch(premiumStatusProvider)
      .maybeWhen(data: (status) => status.isPremium, orElse: () => false);
});

final premiumStatusProvider =
    AsyncNotifierProvider<PremiumNotifier, PremiumStatus>(PremiumNotifier.new);

final premiumOfferingsProvider = FutureProvider<List<PremiumPackage>>((
  ref,
) async {
  return ref.read(premiumServiceProvider).getOfferings();
});

class PremiumNotifier extends AsyncNotifier<PremiumStatus> {
  @override
  Future<PremiumStatus> build() async {
    try {
      return await ref.read(premiumServiceProvider).getStatus();
    } catch (_) {
      return const PremiumStatus.free();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(premiumServiceProvider).getStatus());
    } catch (_) {
      state = const AsyncData(PremiumStatus.free());
    }
  }

  Future<PurchaseResult> purchase(PremiumPackage package) async {
    final result = await ref.read(premiumServiceProvider).purchase(package);
    if (result.success) {
      await refresh();
    }
    return result;
  }

  Future<PurchaseResult> restore() async {
    final result = await ref.read(premiumServiceProvider).restorePurchases();
    if (result.success) {
      await refresh();
    }
    return result;
  }

  Future<void> syncUser(String? userId) async {
    await ref.read(premiumServiceProvider).syncUserId(userId);
    if (userId != null) {
      await refresh();
      return;
    }
    state = const AsyncData(PremiumStatus.free());
  }
}
