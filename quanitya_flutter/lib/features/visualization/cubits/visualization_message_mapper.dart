import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'visualization_state.dart';

/// Message mapper for visualization operations
@injectable
class VisualizationMessageMapper
    implements IStateMessageMapper<VisualizationState> {
  @override
  MessageKey? map(VisualizationState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        VisualizationOperation.load =>
          MessageKey.info(L10nKeys.visualizationLoaded),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
