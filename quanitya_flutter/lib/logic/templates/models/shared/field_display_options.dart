/// Configuration class for UI presentation of template fields.
/// 
/// This class stores UI-specific settings that control how a field
/// is displayed and interacted with in the user interface.
/// 
/// Note: This is distinct from [UiElementEnum] which defines widget types.
/// This class configures display options like order, placeholder text, etc.
class FieldDisplayOptions {
  /// The display order/position of this field in the form
  final int? order;
  
  /// Whether this field should be displayed in a compact format
  final bool isCompact;
  
  /// Custom placeholder text for input fields
  final String? placeholder;
  
  /// Custom help text or description for the field
  final String? helpText;
  
  /// Whether this field should be displayed prominently
  final bool isProminent;
  
  /// Custom icon identifier for the field (optional)
  final String? iconName;
  
  /// Custom color theme for the field (optional)
  final String? colorTheme;
  
  /// Whether this field should span the full width of the form
  final bool isFullWidth;
  
  /// Custom CSS class or style identifier (for future extensibility)
  final String? customStyle;
  
  /// Additional metadata for UI customization
  final Map<String, dynamic>? metadata;
  
  const FieldDisplayOptions({
    this.order,
    this.isCompact = false,
    this.placeholder,
    this.helpText,
    this.isProminent = false,
    this.iconName,
    this.colorTheme,
    this.isFullWidth = false,
    this.customStyle,
    this.metadata,
  });
  
  /// Creates a copy of this FieldDisplayOptions with updated values
  FieldDisplayOptions copyWith({
    int? order,
    bool? isCompact,
    String? placeholder,
    String? helpText,
    bool? isProminent,
    String? iconName,
    String? colorTheme,
    bool? isFullWidth,
    String? customStyle,
    Map<String, dynamic>? metadata,
  }) {
    return FieldDisplayOptions(
      order: order ?? this.order,
      isCompact: isCompact ?? this.isCompact,
      placeholder: placeholder ?? this.placeholder,
      helpText: helpText ?? this.helpText,
      isProminent: isProminent ?? this.isProminent,
      iconName: iconName ?? this.iconName,
      colorTheme: colorTheme ?? this.colorTheme,
      isFullWidth: isFullWidth ?? this.isFullWidth,
      customStyle: customStyle ?? this.customStyle,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Creates a FieldDisplayOptions from JSON map
  factory FieldDisplayOptions.fromJson(Map<String, dynamic> json) {
    return FieldDisplayOptions(
      order: json['order'] as int?,
      isCompact: json['isCompact'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      isProminent: json['isProminent'] as bool? ?? false,
      iconName: json['iconName'] as String?,
      colorTheme: json['colorTheme'] as String?,
      isFullWidth: json['isFullWidth'] as bool? ?? false,
      customStyle: json['customStyle'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// Converts this FieldDisplayOptions to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'isCompact': isCompact,
      'placeholder': placeholder,
      'helpText': helpText,
      'isProminent': isProminent,
      'iconName': iconName,
      'colorTheme': colorTheme,
      'isFullWidth': isFullWidth,
      'customStyle': customStyle,
      'metadata': metadata,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FieldDisplayOptions &&
        other.order == order &&
        other.isCompact == isCompact &&
        other.placeholder == placeholder &&
        other.helpText == helpText &&
        other.isProminent == isProminent &&
        other.iconName == iconName &&
        other.colorTheme == colorTheme &&
        other.isFullWidth == isFullWidth &&
        other.customStyle == customStyle &&
        _mapEquals(other.metadata, metadata);
  }
  
  @override
  int get hashCode {
    return Object.hash(
      order,
      isCompact,
      placeholder,
      helpText,
      isProminent,
      iconName,
      colorTheme,
      isFullWidth,
      customStyle,
      metadata,
    );
  }
  
  @override
  String toString() {
    return 'FieldDisplayOptions('
        'order: $order, '
        'isCompact: $isCompact, '
        'placeholder: $placeholder, '
        'helpText: $helpText, '
        'isProminent: $isProminent, '
        'iconName: $iconName, '
        'colorTheme: $colorTheme, '
        'isFullWidth: $isFullWidth, '
        'customStyle: $customStyle, '
        'metadata: $metadata'
        ')';
  }
  
  /// Helper method to compare maps for equality
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Factory constructor for creating a default FieldDisplayOptions
  factory FieldDisplayOptions.defaultElement() {
    return const FieldDisplayOptions();
  }
  
  /// Factory constructor for creating a compact FieldDisplayOptions
  factory FieldDisplayOptions.compact({String? placeholder}) {
    return FieldDisplayOptions(
      isCompact: true,
      placeholder: placeholder,
    );
  }
  
  /// Factory constructor for creating a prominent FieldDisplayOptions
  factory FieldDisplayOptions.prominent({
    String? iconName,
    String? colorTheme,
  }) {
    return FieldDisplayOptions(
      isProminent: true,
      iconName: iconName,
      colorTheme: colorTheme,
      isFullWidth: true,
    );
  }
}