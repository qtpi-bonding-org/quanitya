// Template Logic Barrel Export
// Commonly used template types and services

// Core Models
export 'models/shared/tracker_template.dart';
export 'models/shared/template_field.dart';
export 'models/shared/template_aesthetics.dart';
export 'models/shared/field_validator.dart';

// Enums
export 'enums/field_enum.dart';
export 'enums/ui_element_enum.dart';
export 'enums/measurement_dimension.dart';
export 'enums/measurement_unit.dart';
export 'enums/ai/allowed_font.dart';
export 'enums/ai/color_palette_color.dart';

// Key Services
// export 'services/engine/widget_template_generator.dart'; // File doesn't exist
export 'services/engine/unified_schema_generator.dart';
export 'services/shared/dynamic_field_builder.dart';

// Interfaces
export 'interfaces/template_widget_factory.dart';
export 'interfaces/widget_builder.dart';
export 'interfaces/wcag_compliance_validator.dart';

// Accessibility
export 'services/shared/wcag_compliance_validator.dart';