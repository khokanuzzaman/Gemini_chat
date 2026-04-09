import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import 'recording_indicator.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.messageFocusNode,
    required this.characterCountNotifier,
    required this.maxMessageLength,
    required this.isResponding,
    required this.isRecording,
    required this.isScanning,
    required this.recordingDuration,
    required this.onMessageChanged,
    required this.onSubmitMessage,
    required this.onScanFromCamera,
    required this.onScanFromGallery,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onShowUsageDetails,
  });

  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final ValueNotifier<int> characterCountNotifier;
  final int maxMessageLength;
  final bool isResponding;
  final bool isRecording;
  final bool isScanning;
  final String recordingDuration;
  final ValueChanged<String> onMessageChanged;
  final VoidCallback onSubmitMessage;
  final Future<void> Function() onScanFromCamera;
  final Future<void> Function() onScanFromGallery;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onShowUsageDetails;

  @override
  Widget build(BuildContext context) {
    final actionDisabled = isResponding || isRecording || isScanning;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        boxShadow: context.elevationLevel(2),
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: characterCountNotifier,
            builder: (context, currentCount, child) {
              final trimmedText = messageController.text.trim();
              final isOverLimit = currentCount > maxMessageLength;
              final canSend =
                  !actionDisabled && trimmedText.isNotEmpty && !isOverLimit;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _AttachButton(
                        enabled: !actionDisabled,
                        onTap: () => _showAttachmentSheet(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: isRecording
                            ? RecordingIndicator(duration: recordingDuration)
                            : TextField(
                                controller: messageController,
                                focusNode: messageFocusNode,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                enabled: !actionDisabled,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: context.primaryTextColor,
                                ),
                                onChanged: onMessageChanged,
                                decoration: InputDecoration(
                                  hintText: 'একটি বার্তা লিখুন...',
                                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                                    color: context.hintTextColor,
                                  ),
                                  filled: true,
                                  fillColor: context.mutedSurfaceColor,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      AppRadius.input,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      AppRadius.input,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      AppRadius.input,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  disabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      AppRadius.input,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ComposerActionButton(
                        hasText: trimmedText.isNotEmpty,
                        isResponding: isResponding || isScanning,
                        isRecording: isRecording,
                        canSend: canSend,
                        onSend: onSubmitMessage,
                        onStartRecording: onStartRecording,
                        onStopRecording: onStopRecording,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: onShowUsageDetails,
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.mutedSurfaceColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: context.borderColor.withValues(
                                  alpha: context.isDarkMode ? 0.4 : 0.75,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: context.appColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.poweredBy,
                                  style: AppTextStyles.caption.copyWith(
                                    color: context.secondaryTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: currentCount == 0 ? 0.6 : 1,
                        duration: AppMotion.fast,
                        child: Text(
                          '$currentCount/$maxMessageLength',
                          style: AppTextStyles.caption.copyWith(
                            color: isOverLimit
                                ? AppColors.error
                                : context.secondaryTextColor,
                            fontWeight: currentCount > 0 || isOverLimit
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAttachmentSheet(BuildContext context) async {
    await AppBottomSheet.show<void>(
      context: context,
      title: 'সংযুক্ত করুন',
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            leadingIcon: Icons.camera_alt_rounded,
            leadingColor: context.appColors.primary,
            title: 'ক্যামেরা দিয়ে রিসিট স্ক্যান',
            onTap: () async {
              Navigator.of(context).pop();
              await onScanFromCamera();
            },
          ),
          AppListTile(
            leadingIcon: Icons.image_outlined,
            leadingColor: context.appColors.primary,
            title: 'গ্যালারি থেকে রিসিট',
            onTap: () async {
              Navigator.of(context).pop();
              await onScanFromGallery();
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.hasText,
    required this.isResponding,
    required this.isRecording,
    required this.canSend,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  final bool hasText;
  final bool isResponding;
  final bool isRecording;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isResponding
          ? SizedBox(
              key: const ValueKey('progress-indicator'),
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: context.appColors.primary,
                  ),
                ),
              ),
            )
          : isRecording
          ? _ActionButton(
              key: const ValueKey('stop-button'),
              backgroundColor: AppColors.error,
              icon: Icons.stop_rounded,
              onTap: onStopRecording,
            )
          : hasText
          ? _ActionButton(
              key: const ValueKey('send-button'),
              backgroundColor: context.appColors.primary,
              icon: Icons.arrow_upward_rounded,
              onTap: canSend ? onSend : null,
            )
          : _MicIdleButton(
              key: const ValueKey('mic-button'),
              enabled: true,
              onTap: onStartRecording,
            ),
    );
  }
}

class _MicIdleButton extends StatefulWidget {
  const _MicIdleButton({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_MicIdleButton> createState() => _MicIdleButtonState();
}

class _MicIdleButtonState extends State<_MicIdleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.96,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _haloScale = Tween<double>(
    begin: 0.9,
    end: 1.18,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _haloOpacity = Tween<double>(
    begin: 0.12,
    end: 0.02,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _MicIdleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isEnabled = widget.enabled;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (isEnabled)
              Opacity(
                opacity: _haloOpacity.value,
                child: Transform.scale(
                  scale: _haloScale.value,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.appColors.primary.withValues(
                        alpha: context.isDarkMode ? 0.24 : 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Transform.scale(
              scale: isEnabled ? _scale.value : 0.94,
              child: child,
            ),
          ],
        );
      },
      child: _ActionButton(
        backgroundColor: context.appColors.primary,
        icon: Icons.mic_rounded,
        onTap: widget.enabled ? widget.onTap : null,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  final Color backgroundColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: enabled
            ? backgroundColor
            : backgroundColor.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(
          Icons.add_rounded,
          color: context.appColors.primary.withValues(
            alpha: enabled ? 1 : 0.38,
          ),
        ),
      ),
    );
  }
}
