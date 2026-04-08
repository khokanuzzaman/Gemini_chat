import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'offline_banner.dart';

/// A standardized page scaffold with consistent padding and backgrounds.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.useGradientBackground = false,
    this.centerTitle = false,
    this.showOfflineBanner = true,
    this.onManualAdd,
    this.refreshIndicator,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool useGradientBackground;
  final bool centerTitle;
  final bool showOfflineBanner;
  final VoidCallback? onManualAdd;
  final Future<void> Function()? refreshIndicator;

  @override
  Widget build(BuildContext context) {
    Widget content = padding != null
        ? Padding(padding: padding!, child: body)
        : body;

    if (refreshIndicator != null) {
      content = RefreshIndicator(
        onRefresh: refreshIndicator!,
        color: context.appColors.primary,
        backgroundColor: context.cardBackgroundColor,
        child: content,
      );
    }

    if (showOfflineBanner && onManualAdd != null) {
      content = Column(
        children: [
          OfflineBanner(onManualAdd: onManualAdd!),
          Expanded(child: content),
        ],
      );
    }

    final scaffold = Scaffold(
      appBar: (title != null || titleWidget != null || actions != null)
          ? AppBar(
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: context.primaryTextColor,
                          ),
                        )
                      : null),
              centerTitle: centerTitle,
              automaticallyImplyLeading: showBackButton,
              leading: leading,
              actions: actions,
              backgroundColor: useGradientBackground
                  ? Colors.transparent
                  : null,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: useGradientBackground ? Colors.transparent : null,
    );

    if (useGradientBackground) {
      return Container(
        decoration: BoxDecoration(gradient: context.shellBackgroundGradient),
        child: scaffold,
      );
    }

    return scaffold;
  }
}
