/// Enumeration of font family options for typography configuration.
/// 
/// Each enum value corresponds to a specific font family that can be used
/// in UI styling and theme configuration.
enum FontFamilyEnum {
  /// Roboto font family (Google's default Android font)
  roboto,
  
  /// Open Sans font family (popular web font)
  openSans,
  
  /// Lato font family (humanist sans-serif)
  lato,
  
  /// Montserrat font family (geometric sans-serif)
  montserrat,
  
  /// Poppins font family (geometric sans-serif)
  poppins,
  
  /// Inter font family (designed for UI)
  inter,
}

/// Extension to convert FontFamilyEnum to font family string
extension FontFamilyEnumExtension on FontFamilyEnum {
  /// Returns the font family name as a string
  String get fontFamily {
    switch (this) {
      case FontFamilyEnum.roboto:
        return 'Roboto';
      case FontFamilyEnum.openSans:
        return 'Open Sans';
      case FontFamilyEnum.lato:
        return 'Lato';
      case FontFamilyEnum.montserrat:
        return 'Montserrat';
      case FontFamilyEnum.poppins:
        return 'Poppins';
      case FontFamilyEnum.inter:
        return 'Inter';
    }
  }
  
  /// Returns a display name for the font family
  String get displayName {
    switch (this) {
      case FontFamilyEnum.roboto:
        return 'Roboto';
      case FontFamilyEnum.openSans:
        return 'Open Sans';
      case FontFamilyEnum.lato:
        return 'Lato';
      case FontFamilyEnum.montserrat:
        return 'Montserrat';
      case FontFamilyEnum.poppins:
        return 'Poppins';
      case FontFamilyEnum.inter:
        return 'Inter';
    }
  }
}