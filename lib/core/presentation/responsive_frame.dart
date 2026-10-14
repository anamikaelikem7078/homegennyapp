import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Makes the whole app work on every device size.
///
/// * Phones and small tablets (≤ [_frameBreakpoint]) use the full screen.
/// * Tablets, foldables, web and desktop get a centered app column
///   ([_maxFrameWidth] wide) on a branded backdrop. The inner [MediaQuery]
///   is rewritten so every screen, dialog and bottom sheet lays out exactly
///   as on a large phone.
/// * The system text scale is clamped so accessibility sizes stay readable
///   without breaking layouts.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  static const double _frameBreakpoint = 760;
  static const double _maxFrameWidth = 720;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.3,
    );

    if (mq.size.width <= _frameBreakpoint) {
      return MediaQuery(data: mq.copyWith(textScaler: textScaler), child: child);
    }

    final frameWidth = math.min(_maxFrameWidth, mq.size.width);
    final framed = mq.copyWith(
      textScaler: textScaler,
      size: Size(frameWidth, mq.size.height),
      padding: mq.padding.copyWith(left: 0, right: 0),
      viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
      viewInsets: mq.viewInsets.copyWith(left: 0, right: 0),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B4D), Color(0xFF1238B8), Color(0xFF1A56FF)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: frameWidth,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F8FC),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRect(
              child: MediaQuery(data: framed, child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// ScreenUtil font resolver that never scales text beyond a sane range,
  /// so small phones don't get tiny text and big screens don't get huge text.
  static double fontSizeResolver(num fontSize, ScreenUtil instance) {
    final scale = instance.scaleWidth.clamp(0.88, 1.12);
    return fontSize * scale;
  }
}
