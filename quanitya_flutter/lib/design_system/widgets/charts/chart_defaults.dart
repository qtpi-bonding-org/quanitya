import 'dart:ui';
import 'package:graphic/graphic.dart';

/// Themed axis guides that use the app's body font (Noto Sans Mono).
///
/// The graphic library's [Defaults.horizontalAxis] and [Defaults.verticalAxis]
/// create TextStyle without a fontFamily, which falls back to the platform
/// default. These replacements ensure chart labels render in the app font.
class ChartDefaults {
  static const _fontFamily = 'Noto Sans Mono';

  static AxisGuide get horizontalAxis => AxisGuide(
        line: Defaults.strokeStyle,
        label: LabelStyle(
          textStyle: Defaults.textStyle.copyWith(fontFamily: _fontFamily),
          offset: const Offset(0, 7.5),
        ),
      );

  static AxisGuide get verticalAxis => AxisGuide(
        label: LabelStyle(
          textStyle: Defaults.textStyle.copyWith(fontFamily: _fontFamily),
          offset: const Offset(-7.5, 0),
        ),
        grid: Defaults.strokeStyle,
      );
}
