import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';
import 'package:quanitya_flutter/features/guided_tour/guided_tour_service.dart';

/// Minimal fake — 3 methods, no crypto baggage.
class FakeSecurePreferences implements SecurePreferences {
  final Map<String, dynamic> _store = {};

  @override
  Future<bool?> getBool(String key) async => _store[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);
}

void main() {
  late FakeSecurePreferences prefs;
  late GuidedTourService service;

  setUp(() {
    prefs = FakeSecurePreferences();
    service = GuidedTourService(prefs);
  });

  test('shouldShowTour returns true when tour has not been seen', () async {
    expect(await service.shouldShowTour(GuidedTourService.homeKey), isTrue);
  });

  test('shouldShowTour returns false after markTourSeen', () async {
    await service.markTourSeen(GuidedTourService.homeKey);
    expect(await service.shouldShowTour(GuidedTourService.homeKey), isFalse);
  });

  test('resetAllTours clears all seen flags', () async {
    await service.markTourSeen(GuidedTourService.homeKey);
    await service.markTourSeen(GuidedTourService.designerKey);

    await service.resetAllTours();

    expect(await service.shouldShowTour(GuidedTourService.homeKey), isTrue);
    expect(await service.shouldShowTour(GuidedTourService.designerKey), isTrue);
  });

  test('tours are independent — marking one does not affect the other', () async {
    await service.markTourSeen(GuidedTourService.homeKey);
    expect(await service.shouldShowTour(GuidedTourService.designerKey), isTrue);
  });
}
