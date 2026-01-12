import 'package:flutter/material.dart';

/// AAY Bottom Navigation component
/// - Supports variants per design: primary, secondary, outline
/// - Items can override the variant
/// - Simple, theme-aware defaults so it fits the app

enum AayNavVariant { primary, secondary, outline }

class AayBottomNavigationItem {
  final IconData icon;
  final String label;
  final bool isDisabled;
  final AayNavVariant? variant;

  const AayBottomNavigationItem({
    required this.icon,
    required this.label,
    this.isDisabled = false,
    this.variant,
  });
}

class AayBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AayBottomNavigationItem> items;
  final AayNavVariant variant;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  const AayBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.variant = AayNavVariant.primary,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
  }) : assert(
         items.length >= 2,
         'AayBottomNavigationBar requires at least 2 items',
       );

  @override
  Widget build(BuildContext context) {
    // Map variant -> primary color
    Color resolveSelectedColor(AayNavVariant v) {
      switch (v) {
        case AayNavVariant.primary:
          return selectedColor ?? Colors.green.shade700;
        case AayNavVariant.secondary:
          return selectedColor ?? Colors.blueGrey.shade700;
        case AayNavVariant.outline:
          return selectedColor ?? Colors.green.shade700;
      }
    }

    final bg = backgroundColor ?? const Color(0xFFFFD866);
    final unsel = unselectedColor ?? Colors.black.withOpacity(0.6);

    final centerIndex = items.length ~/ 2;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              final effectiveVariant = item.variant ?? variant;
              final selColor = resolveSelectedColor(effectiveVariant);
              final isCenter = i == centerIndex;

              final iconSize = isCenter ? 28.0 : 20.0;
              final circleSize = isCenter ? (selected ? 58.0 : 52.0) : 44.0;

              final iconContainer = AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: selected
                      ? (effectiveVariant == AayNavVariant.outline
                            ? Colors.transparent
                            : selColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(circleSize / 2),
                  border: selected
                      ? (effectiveVariant == AayNavVariant.outline
                            ? Border.all(color: selColor, width: 2)
                            : null)
                      : Border.all(color: unsel.withOpacity(0.35)),
                  boxShadow: isCenter && selected
                      ? [
                          BoxShadow(
                            color: selColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: iconSize,
                  color: selected
                      ? (effectiveVariant == AayNavVariant.outline
                            ? selColor
                            : Colors.white)
                      : unsel,
                ),
              );

              final widget = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Elevate center item slightly
                  if (isCenter)
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: iconContainer,
                    )
                  else
                    iconContainer,
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? (effectiveVariant == AayNavVariant.primary
                                ? selColor
                                : (effectiveVariant == AayNavVariant.secondary
                                      ? Colors.white
                                      : selColor))
                          : unsel,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              );

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.isDisabled ? null : () => onTap(i),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCenter ? 6 : 8,
                        vertical: 4,
                      ),
                      child: widget,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
