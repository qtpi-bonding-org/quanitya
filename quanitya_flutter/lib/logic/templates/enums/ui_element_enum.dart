/// Enumeration of UI widget types available for template field rendering.
/// 
/// Each enum value corresponds to a specific UI widget that can be used
/// to display and interact with template fields in the user interface.
enum UiElementEnum {
  /// Numeric input with draggable slider control
  slider,
  
  /// Single-line text input field
  textField,
  
  /// Multi-line text input area
  textArea,
  
  /// Numeric input with increment/decrement buttons
  stepper,
  
  /// Multiple selection chips for enumerated values
  chips,
  
  /// Dropdown selection menu for enumerated values
  dropdown,
  
  /// Radio button selection for enumerated values
  radio,
  
  /// Toggle switch for boolean values
  toggleSwitch,
  
  /// Checkbox for boolean values
  checkbox,
  
  /// Date picker widget for date selection
  datePicker,
  
  /// Time picker widget for time selection
  timePicker,
  
  /// Combined date and time picker widget
  datetimePicker,
  
  /// Search field with autocomplete functionality
  searchField,

  /// Location capture button (grabs current GPS coordinates on tap)
  locationPicker,
}