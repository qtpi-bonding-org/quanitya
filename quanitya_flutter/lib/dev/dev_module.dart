/// Development module - Contains all dev-only functionality
/// 
/// This module should only be used in debug builds and contains:
/// - Dev tools UI (FAB, bottom sheet)
/// - Fake data seeding service
/// - Development utilities
/// 
/// All dev functionality is isolated here to keep it separate from production code.

export 'services/dev_seeder_service.dart';
export 'widgets/dev_tools_sheet.dart';
export 'widgets/dev_fab.dart';