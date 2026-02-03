/// Enumeration of font weight values for typography configuration.
/// 
/// Each enum value corresponds to a specific font weight that can be used
/// in UI styling and theme configuration.
enum FontWeightEnum {
  /// Thin font weight (100)
  w100,
  
  /// Extra light font weight (200)
  w200,
  
  /// Light font weight (300)
  w300,
  
  /// Normal/Regular font weight (400)
  w400,
  
  /// Medium font weight (500)
  w500,
  
  /// Semi-bold font weight (600)
  w600,
  
  /// Bold font weight (700)
  w700,
  
  /// Extra bold font weight (800)
  w800,
  
  /// Black font weight (900)
  w900,
}

/// Extension to convert FontWeightEnum to Flutter FontWeight
extension FontWeightEnumExtension on FontWeightEnum {
  /// Returns the corresponding Flutter FontWeight value
  int get value {
    switch (this) {
      case FontWeightEnum.w100:
        return 100;
      case FontWeightEnum.w200:
        return 200;
      case FontWeightEnum.w300:
        return 300;
      case FontWeightEnum.w400:
        return 400;
      case FontWeightEnum.w500:
        return 500;
      case FontWeightEnum.w600:
        return 600;
      case FontWeightEnum.w700:
        return 700;
      case FontWeightEnum.w800:
        return 800;
      case FontWeightEnum.w900:
        return 900;
    }
  }
}