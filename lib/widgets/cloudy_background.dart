import 'package:flutter/material.dart';

/// Cloudy sky background using the provided GIF + radial gradient fallback.
class CloudyBackground extends StatelessWidget {
  const CloudyBackground({
    super.key,
    required this.child,
    this.drift = Alignment.center,
    this.assetPath = _defaultBackgroundImage,
  });

  final Widget child;
  final Alignment drift;
  final String assetPath;

  static const String _defaultBackgroundImage = 'assets/images/clouds_bg.gif';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Radial gradient base (Figma: radial-gradient(50% 50% at 50% 50%, #A9C6FD 0%, #E4F2FF 100%))
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, 0.0),
              radius: 0.8,
              colors: [Color(0xFFA9C6FD), Color(0xFFE4F2FF)],
              stops: [0.0, 1.0],
            ),
          ),
        ),

        // Top glow overlay to match the lighter cap in the Figma background.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.35, 1.0],
              colors: [
                Color(0x55FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00000000),
              ],
            ),
          ),
        ),

        // GIF layer (cover, no-repeat) με opacity 0.35
        IgnorePointer(
          child: AnimatedAlign(
            alignment: drift,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: SizedBox.expand(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

/// Drop-in animated variant so individual screens do not need to manage controllers.
class CloudyAnimatedBackground extends StatefulWidget {
  const CloudyAnimatedBackground({super.key, required this.child});

  final Widget child;

  @override
  State<CloudyAnimatedBackground> createState() => _CloudyAnimatedBackgroundState();
}

class _CloudyAnimatedBackgroundState extends State<CloudyAnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  late final Animation<Alignment> _drift = AlignmentTween(
    begin: const Alignment(-0.02, -0.02),
    end: const Alignment(0.02, 0.02),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        return CloudyBackground(drift: _drift.value, child: child!);
      },
      child: widget.child,
    );
  }
}
