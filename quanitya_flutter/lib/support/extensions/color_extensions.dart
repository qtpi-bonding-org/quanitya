import 'dart:ui';

extension HexColorExtension on String {
  Color toColor() {
    final cleanHex = replaceFirst('#', '');
    return Color(int.parse(cleanHex, radix: 16) + 0xFF000000);
  }
}
