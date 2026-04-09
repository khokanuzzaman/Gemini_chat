import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/security/biometric_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  List<BiometricType> _availableBiometrics = const [];
  bool _isAuthenticating = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
    Future<void>.delayed(const Duration(milliseconds: 300), _authenticate);
  }

  Future<void> _loadBiometrics() async {
    final biometrics = await ref
        .read(biometricServiceProvider)
        .getAvailableBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _availableBiometrics = biometrics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.primaryGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: AppFadeSlideIn(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '৳',
                              style: TextStyle(
                                fontSize: 44,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'PocketPilot AI',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'আনলক করতে ফিঙ্গারপ্রিন্ট ব্যবহার করুন',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getBiometricIcon(),
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AppActionButton(
                            label: _getBiometricLabel(),
                            icon: _getBiometricIcon(),
                            fullWidth: true,
                            isLoading: _isAuthenticating,
                            onPressed: _isAuthenticating ? null : _authenticate,
                          ),
                        ),
                        if (_showError) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _errorMessage,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppActionButton(
                          label: 'আবার চেষ্টা করুন',
                          variant: AppActionButtonVariant.ghost,
                          onPressed: _isAuthenticating ? null : _authenticate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face_rounded;
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint) ||
        _availableBiometrics.contains(BiometricType.strong) ||
        _availableBiometrics.contains(BiometricType.weak)) {
      return Icons.fingerprint_rounded;
    }
    return Icons.lock_open_rounded;
  }

  String _getBiometricLabel() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID দিয়ে আনলক করুন';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint) ||
        _availableBiometrics.contains(BiometricType.strong) ||
        _availableBiometrics.contains(BiometricType.weak)) {
      return 'Fingerprint দিয়ে আনলক করুন';
    }
    return 'আনলক করুন';
  }

  Future<void> _authenticate() async {
    if (!mounted || _isAuthenticating) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _showError = false;
      _errorMessage = '';
    });

    final result = await ref.read(biometricProvider.notifier).unlock();
    if (!mounted) {
      return;
    }

    switch (result) {
      case BiometricAuthResult.success:
        widget.onUnlocked();
        break;
      case BiometricAuthResult.failed:
        _setError('ভেরিফাই করা যায়নি');
        break;
      case BiometricAuthResult.notAvailable:
        _setError('Biometric available নেই');
        break;
      case BiometricAuthResult.notEnrolled:
        _setError('Device এ biometric set করুন');
        break;
      case BiometricAuthResult.lockedOut:
        _setError('অনেকবার fail হয়েছে, পরে চেষ্টা করুন');
        break;
    }
  }

  void _setError(String message) {
    setState(() {
      _isAuthenticating = false;
      _showError = true;
      _errorMessage = message;
    });
  }
}
