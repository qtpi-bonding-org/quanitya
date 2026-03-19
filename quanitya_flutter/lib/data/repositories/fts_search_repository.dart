import 'package:injectable/injectable.dart';

import '../dao/fts_search_dao.dart';
import '../dao/log_entry_query_dao.dart';

/// Repository that composes FTS5 full-text search with context-enriched
/// log entry hydration.
///
/// Bridges [FtsSearchDao] (relevance-ranked ID matching) and
/// [LogEntryQueryDao] (batch context loading) so callers get
/// [LogEntryWithContext] results ordered by BM25 relevance.
@lazySingleton
class FtsSearchRepository {
  final FtsSearchDao _ftsDao;
  final LogEntryQueryDao _queryDao;

  FtsSearchRepository(this._ftsDao, this._queryDao);

  /// Search log entries by [query], returning results with full context
  /// ordered by relevance (BM25 ranking).
  ///
  /// Supports FTS5 syntax: phrases ("exact match"),
  /// prefix queries (word*), boolean operators (AND, OR, NOT).
  ///
  /// Returns an empty list if [query] is empty or whitespace.
  Future<List<LogEntryWithContext>> search(String query) async {
    final entryIds = await _ftsDao.search(query);
    if (entryIds.isEmpty) return [];
    return _queryDao.findByIdsWithContext(entryIds);
  }
}
