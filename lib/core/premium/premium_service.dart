import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const String _premiumEntitlement = 'premium';
const String _revenueCatPublicKeyEnv = 'REVENUECAT_PUBLIC_SDK_KEY';
const String _revenueCatPublicApiKeyEnv = 'REVENUECAT_PUBLIC_API_KEY';

// TODO: Replace with your own RevenueCat Test Store key if needed.
// TODO: Never ship production builds with a `test_` key.
const String _debugTestStoreApiKey = 'test_wzOkcFUUlkfQsbqShnXcniiXlXX';

enum RevenueCatKeyMode { production, testStore, missing, invalid }

class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    this.expiryDate,
    this.activeProductId,
    this.isLifetime = false,
  });

  const PremiumStatus.free()
    : isPremium = false,
      expiryDate = null,
      activeProductId = null,
      isLifetime = false;

  final bool isPremium;
  final DateTime? expiryDate;
  final String? activeProductId;
  final bool isLifetime;
}

class PremiumPackage {
  const PremiumPackage({
    required this.productId,
    required this.title,
    required this.priceString,
    required this.currencyCode,
    required this.period,
    required this.isYearly,
    required this.rcPackage,
  });

  final String productId;
  final String title;
  final String priceString;
  final String currencyCode;
  final String period;
  final bool isYearly;
  final Package rcPackage;
}

class PurchaseResult {
  const PurchaseResult.success()
    : success = true,
      isCancelled = false,
      errorMessage = null;

  const PurchaseResult.cancelled()
    : success = false,
      isCancelled = true,
      errorMessage = null;

  const PurchaseResult.error(String message)
    : success = false,
      isCancelled = false,
      errorMessage = message;

  final bool success;
  final bool isCancelled;
  final String? errorMessage;
}

class PremiumService {
  PremiumService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  late final String _apiKey = _resolveApiKey();

  bool _didInitialize = false;

  RevenueCatKeyMode get keyMode => _classifyApiKey(_apiKey);
  bool get isUsingTestStore => keyMode == RevenueCatKeyMode.testStore;
  bool get hasUsableSdkKey =>
      keyMode == RevenueCatKeyMode.production ||
      keyMode == RevenueCatKeyMode.testStore;
  String? get configurationWarningBn => _configurationWarningFor(keyMode);

  void setMockPremium(bool enabled) {
    // TODO: Restore RevenueCat before production
    // Kept as no-op to avoid breaking test stubs that implement this interface.
  }

  Future<void> initialize({String? userId}) async {
    try {
      if (!hasUsableSdkKey) {
        debugPrint(
          'RevenueCat initialize skipped: ${configurationWarningBn ?? 'SDK key missing'}',
        );
        return;
      }

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final isConfigured = await _isConfigured();
      if (!isConfigured) {
        await Purchases.configure(PurchasesConfiguration(_apiKey));
      }

      _didInitialize = true;
      if (userId != null && userId.isNotEmpty) {
        await Purchases.logIn(userId);
      }
    } catch (error, stackTrace) {
      debugPrint('RevenueCat initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<PremiumStatus> getStatus() async {
    if (!hasUsableSdkKey) {
      return const PremiumStatus.free();
    }

    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.active[_premiumEntitlement];
      if (entitlement == null) {
        return const PremiumStatus.free();
      }

      final expiryDate = entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!);

      return PremiumStatus(
        isPremium: true,
        expiryDate: expiryDate,
        activeProductId: entitlement.productIdentifier,
        isLifetime: entitlement.expirationDate == null,
      );
    } catch (_) {
      return const PremiumStatus.free();
    }
  }

  Future<bool> isPremium() async {
    try {
      return (await getStatus()).isPremium;
    } catch (_) {
      return false;
    }
  }

  Future<List<PremiumPackage>> getOfferings() async {
    if (!hasUsableSdkKey) {
      return const [];
    }

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        return const [];
      }

      return current.availablePackages
          .map((package) {
            final isYearly = package.packageType == PackageType.annual;
            return PremiumPackage(
              productId: package.storeProduct.identifier,
              title: package.storeProduct.title,
              priceString: _effectivePriceString(
                productId: package.storeProduct.identifier,
                isYearly: isYearly,
                rawPrice: package.storeProduct.priceString,
              ),
              currencyCode: _effectiveCurrencyCode(
                productId: package.storeProduct.identifier,
                isYearly: isYearly,
                rawCurrency: package.storeProduct.currencyCode,
              ),
              period: isYearly ? 'বার্ষিক' : 'মাসিক',
              isYearly: isYearly,
              rcPackage: package,
            );
          })
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<PurchaseResult> purchase(PremiumPackage package) async {
    if (!hasUsableSdkKey) {
      return PurchaseResult.error(
        configurationWarningBn ?? 'RevenueCat কনফিগার করা নেই',
      );
    }

    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package.rcPackage),
      );
      await _syncCustomerInfo(result.customerInfo);
      return const PurchaseResult.success();
    } on PlatformException catch (error) {
      final code = _errorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult.cancelled();
      }
      return PurchaseResult.error(
        _purchasesMessage(error) ?? 'কেনা সম্পন্ন হয়নি',
      );
    } catch (_) {
      return const PurchaseResult.error('কেনা সম্পন্ন হয়নি');
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    if (!hasUsableSdkKey) {
      return PurchaseResult.error(
        configurationWarningBn ?? 'RevenueCat কনফিগার করা নেই',
      );
    }

    try {
      final info = await Purchases.restorePurchases();
      final entitlement = info.entitlements.active[_premiumEntitlement];
      if (entitlement == null) {
        return const PurchaseResult.error(
          'কোনো active subscription পাওয়া যায়নি',
        );
      }

      await _syncCustomerInfo(info);
      return const PurchaseResult.success();
    } catch (_) {
      return const PurchaseResult.error('রিস্টোর ব্যর্থ হয়েছে');
    }
  }

  Future<void> syncUserId(String? userId) async {
    if (!hasUsableSdkKey) {
      return;
    }

    try {
      if (!_didInitialize) {
        await initialize(userId: userId);
        return;
      }

      if (userId != null && userId.isNotEmpty) {
        await Purchases.logIn(userId);
      } else {
        await Purchases.logOut();
      }
    } catch (_) {}
  }

  Future<void> _syncCustomerInfo(CustomerInfo info) async {
    final entitlement = info.entitlements.active[_premiumEntitlement];
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    await _syncToFirestore(
      user.uid,
      entitlement != null,
      entitlement?.productIdentifier,
    );
  }

  Future<void> _syncToFirestore(
    String uid,
    bool isPremium,
    String? productId,
  ) async {
    try {
      await _firestore.doc('users/$uid/subscription/status').set({
        'isPremium': isPremium,
        'activeProductId': productId,
        'entitlement': _premiumEntitlement,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<bool> _isConfigured() async {
    try {
      return await Purchases.isConfigured;
    } catch (_) {
      return false;
    }
  }

  PurchasesErrorCode _errorCode(PlatformException error) {
    try {
      return PurchasesErrorHelper.getErrorCode(error);
    } catch (_) {
      return PurchasesErrorCode.unknownError;
    }
  }

  String? _purchasesMessage(PlatformException error) {
    final details = error.details;
    if (details is Map) {
      try {
        final purchasesError = PurchasesError.fromJson(
          Map<String, dynamic>.from(details),
        );
        if (purchasesError.message.trim().isNotEmpty) {
          return purchasesError.message;
        }
      } catch (_) {}
    }

    final message = error.message;
    if (message == null || message.trim().isEmpty) {
      return null;
    }
    return message;
  }

  String _resolveApiKey() {
    const fromDefine = String.fromEnvironment(_revenueCatPublicKeyEnv);
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim();
    }

    final fromEnv = dotenv.env[_revenueCatPublicKeyEnv]?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    final fallbackEnv = dotenv.env[_revenueCatPublicApiKeyEnv]?.trim();
    if (fallbackEnv != null && fallbackEnv.isNotEmpty) {
      return fallbackEnv;
    }

    if (kDebugMode) {
      return _debugTestStoreApiKey;
    }

    return '';
  }

  RevenueCatKeyMode _classifyApiKey(String key) {
    if (key.trim().isEmpty) {
      return RevenueCatKeyMode.missing;
    }
    if (key.startsWith('test_')) {
      return RevenueCatKeyMode.testStore;
    }
    if (key.startsWith('goog_') ||
        key.startsWith('appl_') ||
        key.startsWith('amzn_') ||
        key.startsWith('strp_')) {
      return RevenueCatKeyMode.production;
    }
    return RevenueCatKeyMode.invalid;
  }

  String? _configurationWarningFor(RevenueCatKeyMode mode) {
    return switch (mode) {
      RevenueCatKeyMode.production => null,
      RevenueCatKeyMode.testStore =>
        '🧪 Test Store key চলছে। এখানে template paywall test হবে, real billing না।',
      RevenueCatKeyMode.missing =>
        '`REVENUECAT_PUBLIC_SDK_KEY` সেট করা নেই। Public SDK key দিন।',
      RevenueCatKeyMode.invalid =>
        'RevenueCat key ভুল। client app-এ শুধুই public SDK key দিন (test_/goog_/appl_)।',
    };
  }

  String _effectivePriceString({
    required String productId,
    required bool isYearly,
    required String rawPrice,
  }) {
    if (!isUsingTestStore) {
      return rawPrice;
    }

    final normalized = productId.toLowerCase();
    if (normalized == 'monthly_premium' || normalized.contains('month')) {
      return '৳৯৯/মাস';
    }
    if (normalized == 'yearly_premium' || normalized.contains('year')) {
      return '৳৭৯৯/বছর';
    }

    return isYearly ? '৳৭৯৯/বছর' : '৳৯৯/মাস';
  }

  String _effectiveCurrencyCode({
    required String productId,
    required bool isYearly,
    required String rawCurrency,
  }) {
    if (!isUsingTestStore) {
      return rawCurrency;
    }

    final normalized = productId.toLowerCase();
    if (normalized == 'monthly_premium' ||
        normalized == 'yearly_premium' ||
        normalized.contains('month') ||
        normalized.contains('year')) {
      return 'BDT';
    }

    return isYearly ? 'BDT' : rawCurrency;
  }
}
