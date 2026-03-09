import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../infrastructure/platform/platform_local_auth.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/log_entries/services/log_entry_service.dart';
import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import 'template_list_state.dart';

@injectable
class TemplateListCubit extends QuanityaCubit<TemplateListState> {
  final TemplateWithAestheticsRepository _repository;
  final LogEntryService _logEntryService;
  final PlatformLocalAuth _localAuthService;
  StreamSubscription? _subscription;

  TemplateListCubit(
    this._repository,
    this._logEntryService,
    this._localAuthService,
  ) : super(const TemplateListState());

  void load() {
    _subscription?.cancel();
    // When showingHidden is true, show all (null filter includes hidden)
    // When false, explicitly exclude hidden
    _subscription = _repository.watch(
      isArchived: false,
      isHidden: state.showingHidden ? null : false,
    ).listen((templates) {
      emit(
        state.copyWith(
          templates: templates,
          status: UiFlowStatus.success,
          lastOperation: TemplateListOperation.load,
        ),
      );
    });
  }

  /// Toggle visibility of hidden templates (requires local auth).
  Future<void> toggleShowHidden() async {
    if (state.showingHidden) {
      // Locking doesn't require auth
      emit(state.copyWith(showingHidden: false));
      load();
      return;
    }

    // Unlocking requires authentication
    final result = await _localAuthService.authenticate(
      reason: 'Authenticate to view hidden templates',
    );

    if (result) {
      emit(state.copyWith(
        showingHidden: true,
        status: UiFlowStatus.success,
        lastOperation: TemplateListOperation.toggleHiddenView,
      ));
      load();
    }
    // If auth failed/cancelled, do nothing - stay locked
  }

  /// Hide a template (requires auth to view again).
  Future<void> hideTemplate(String templateId) async {
    await tryOperation(() async {
      await _repository.hide(templateId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateListOperation.hide,
      );
    }, emitLoading: true);
  }

  /// Unhide a template (make visible in normal list).
  Future<void> unhideTemplate(String templateId) async {
    await tryOperation(() async {
      await _repository.unhide(templateId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateListOperation.unhide,
      );
    }, emitLoading: true);
  }

  Future<void> archive(String templateId) async {
    await tryOperation(() async {
      await _repository.archive(templateId);
      analytics?.trackTemplateDeleted();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateListOperation.archive,
      );
    }, emitLoading: true);
  }

  /// Instantly logs an entry with default values for all fields.
  Future<void> instantLog(TrackerTemplateModel template) async {
    await tryOperation(() async {
      final data = _buildDefaultValues(template);
      final entry = LogEntryModel.logNow(
        templateId: template.id,
        data: data,
      );
      await _logEntryService.saveLogEntry(entry);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateListOperation.instantLog,
      );
    }, emitLoading: false); // Don't show loading overlay for quick action
  }

  /// Builds default values map from template fields.
  /// Uses field.defaultValue if set, otherwise type-based fallback.
  Map<String, dynamic> _buildDefaultValues(TrackerTemplateModel template) {
    final defaults = <String, dynamic>{};
    for (final field in template.fields) {
      if (field.isDeleted) continue;
      defaults[field.id] = field.defaultValue ?? _typeDefault(field);
    }
    return defaults;
  }

  /// Returns type-based default value for a field.
  dynamic _typeDefault(TemplateField field) {
    return switch (field.type) {
      FieldEnum.integer => 0,
      FieldEnum.float => 0.0,
      FieldEnum.boolean => false,
      FieldEnum.text => '',
      FieldEnum.datetime => DateTime.now().toIso8601String(),
      FieldEnum.enumerated =>
        field.options?.isNotEmpty == true ? field.options!.first : null,
      FieldEnum.dimension => 0.0,
      FieldEnum.reference => null,
      FieldEnum.location => null,
    };
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
