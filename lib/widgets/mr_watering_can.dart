import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

enum WateringCanVariant { defaultMode, beggingToTap, pulsing, pauseMode }

class MrWateringCan extends StatelessWidget {
  final WateringCanVariant variant;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const MrWateringCan({
    super.key,
    this.variant = WateringCanVariant.defaultMode,
    this.onTap,
    required this.width,
    required this.height,
  });

  String _getAssetPath() {
    switch (variant) {
      case WateringCanVariant.defaultMode:
        return 'assets/images/watering_can_default.svg';
      case WateringCanVariant.beggingToTap:
        return 'assets/images/tap_begging.svg';
      case WateringCanVariant.pulsing:
        return 'assets/images/pusling.svg';
      case WateringCanVariant.pauseMode:
        return 'assets/images/pause_mode.svg';
    }
  }

  bool _hasBlurEffect() {
    return variant == WateringCanVariant.beggingToTap ||
        variant == WateringCanVariant.pulsing;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SvgPicture.asset(
      _getAssetPath(),
      width: width,
      height: height,
      fit: BoxFit.contain,
    );

    // Apply shadow/glow effect for begging and pulsing variants
    if (_hasBlurEffect()) {
      content = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 34.5,
              spreadRadius: 3,
              offset: const Offset(-12, 17),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: width, height: height, child: content),
    );
  }
}
