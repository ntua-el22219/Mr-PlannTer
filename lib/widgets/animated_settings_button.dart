import 'package:flutter/material.dart';
import '../services/sound_effect_service.dart';

class AnimatedSettingsButton extends StatefulWidget {
  final Future<void> Function() onTap;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final bool isExiting;

  const AnimatedSettingsButton({
    super.key,
    required this.onTap,
    this.size = 40.0,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.isExiting = false,
  });

  @override
  State<AnimatedSettingsButton> createState() => AnimatedSettingsButtonState();
}

class AnimatedSettingsButtonState extends State<AnimatedSettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.black,
      end: const Color(0xFF671A1A),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Auto-play forward if exiting (shows enlarged/red state immediately in settings)
    if (widget.isExiting) {
      _controller.value = 1.0; // Start at end state
    }
  }

  @override
  void didUpdateWidget(AnimatedSettingsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExiting != oldWidget.isExiting) {
      if (widget.isExiting) {
        _controller.value = 1.0;
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset animation when returning from navigation (if not in exiting mode)
    if (!widget.isExiting && _controller.isCompleted) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    SoundEffectService.playPopSound();
    
    if (widget.isExiting) {
      // This shouldn't be used anymore
      await _controller.reverse();
      if (mounted) {
        widget.onTap();
      }
    } else {
      // Forward animation when entering
      await _controller.forward();
      // Navigate and wait for return
      await widget.onTap();
      // When we return, play reverse animation
      if (mounted && _controller.isCompleted) {
        await _controller.reverse();
      }
    }
  }

  /// Public method to trigger reverse animation and exit (called by X button)
  void reverseAndExit() async {
    SoundEffectService.playPopSound();
    await _controller.reverse();
    if (mounted) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GestureDetector(
            onTap: _handleTap,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159, // 180 degrees
                child: Icon(
                  Icons.settings,
                  size: widget.size,
                  color: _colorAnimation.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
