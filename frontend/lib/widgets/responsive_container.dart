import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Responsive wrapper that constrains content width on web/desktop
/// while keeping full width on mobile
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool applyPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.padding,
    this.applyPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 768;

    if (!isWide) {
      return child;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: applyPadding ? (padding ?? const EdgeInsets.symmetric(horizontal: 24)) : null,
        child: child,
      ),
    );
  }
}

/// Returns true if the screen is wide enough for desktop layout
bool isDesktopLayout(BuildContext context) {
  return MediaQuery.of(context).size.width > 768;
}

/// Returns true if running on web
bool get isWeb => kIsWeb;
