import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/security/biometric_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                '৳',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'SmartSpend',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'খুলতে verify করুন',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          ElevatedButton.icon(
                            onPressed: _isAuthenticating ? null : _authenticate,
                            icon: Icon(_getBiometricIcon()),
                            label: Text(_getBiometricLabel()),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(220, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_showError)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                _errorMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'PIN দিয়েও unlock করা যাবে',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
      return 'Face ID দিয়ে খুলুন';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint) ||
        _availableBiometrics.contains(BiometricType.strong) ||
        _availableBiometrics.contains(BiometricType.weak)) {
      return 'Fingerprint দিয়ে খুলুন';
    }
    return 'Unlock করুন';
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
        _setError('Verify করা যায়নি');
        break;
      case BiometricAuthResult.notAvailable:
        _setError('Biometric available নেই');
        break;
      case BiometricAuthResult.notEnrolled:
        _setError('Device এ biometric set করুন');
        break;
      case BiometricAuthResult.lockedOut:
        _setError('অনেকবার fail — পরে চেষ্টা করুন');
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
