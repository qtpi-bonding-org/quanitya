// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_data.freezed.dart';
part 'catalog_data.g.dart';

@freezed
abstract class CatalogData with _$CatalogData {
  const CatalogData._();
  const factory CatalogData({
    required int version,
    required List<CatalogCategory> categories,
    required List<CatalogEntry> templates,
  }) = _CatalogData;

  factory CatalogData.fromJson(Map<String, dynamic> json) =>
      _$CatalogDataFromJson(json);
}

@freezed
abstract class CatalogCategory with _$CatalogCategory {
  const CatalogCategory._();
  const factory CatalogCategory({
    required String id,
    required String name,
  }) = _CatalogCategory;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      _$CatalogCategoryFromJson(json);
}

@freezed
abstract class CatalogEntry with _$CatalogEntry {
  const CatalogEntry._();
  const factory CatalogEntry({
    required String slug,
    required String name,
    required String description,
    required String emoji,
    String? icon,
    required String category,
    required List<String> tags,
    @JsonKey(name: 'fields_count') required int fieldsCount,
    required String author,
    @Default(false) bool featured,
  }) = _CatalogEntry;

  factory CatalogEntry.fromJson(Map<String, dynamic> json) =>
      _$CatalogEntryFromJson(json);
}
