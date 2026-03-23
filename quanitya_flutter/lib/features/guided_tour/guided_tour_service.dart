import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../infrastructure/platform/secure_preferences.dart';

/// Manages "seen" flags for guided spotlight tours.
@lazySingleton
class GuidedTourService {
  final SecurePreferences _prefs;

  static const String homeKey = 'tour_home_seen';
  static const String designerKey = 'tour_designer_seen';

  GuidedTourService(this._prefs);

  Future<bool> shouldShowTour(String key) async {
    final seen = await _prefs.getBool(key);
    return seen != true;
  }

  Future<void> markTourSeen(String key) => _prefs.setBool(key, true);

  Future<void> resetAllTours() async {
    await _prefs.remove(homeKey);
    await _prefs.remove(designerKey);
  }
}

/// Static GlobalKeys for tour target widgets.
/// Only one instance of each target exists at a time.
class HomeTourKeys {
  static final temporalLabels = GlobalKey(debugLabel: 'tour_temporal_labels');
  static final designerButton = GlobalKey(debugLabel: 'tour_designer_button');
  static final resultsTab = GlobalKey(debugLabel: 'tour_results_tab');
}

class DesignerTourKeys {
  static final aiPrompt = GlobalKey(debugLabel: 'tour_ai_prompt');
  static final nameField = GlobalKey(debugLabel: 'tour_name_field');
  static final fieldsSection = GlobalKey(debugLabel: 'tour_fields_section');
  static final scheduleFold = GlobalKey(debugLabel: 'tour_schedule_fold');
  static final previewButton = GlobalKey(debugLabel: 'tour_preview_button');
}
