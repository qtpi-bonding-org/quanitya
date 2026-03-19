import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/repositories/fts_search_repository.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'search_state.dart';

@injectable
class SearchCubit extends QuanityaCubit<SearchState> {
  final FtsSearchRepository _searchRepo;

  SearchCubit(this._searchRepo) : super(const SearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clear();
      return;
    }

    await tryOperation(() async {
      final results = await _searchRepo.search(trimmed);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: SearchOperation.search,
        query: trimmed,
        results: results,
      );
    }, emitLoading: true);
  }

  void clear() {
    emit(const SearchState());
  }
}
