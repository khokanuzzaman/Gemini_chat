import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/assets/app_icon.dart';
import '../../core/theme/app_theme.dart';

/// In-app splash: the brand mark (icon_rounded) centred on the canvas — #F3F1FA
/// light, #14121F dark. It is deliberately static and the same size as the native
/// pre-Android-12 / iOS launch screen, so hand-off from the system splash to this
/// one does not jump.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  /// Matches the native launch icon (120dp / 120pt).
  static const markSize = 120.0;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.canvas,
      body: const Center(child: PocketPilotLogo(size: SplashScreen.markSize)),
    );
  }
}
