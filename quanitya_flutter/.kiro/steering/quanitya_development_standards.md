# Quanitya Development Standards

## Required Libraries

- **Freezed**: `@freezed` for all data classes
- **Drift**: Database operations
- **Cubits**: State management (not Blocs)
- **Injectable**: `@injectable`, `@singleton`, `@lazySingleton`
- **GetIt**: `getIt<Service>()` for retrieval
- **JSON Serializable**: `@JsonSerializable()` for API models

## Usage

### State
```dart
@freezed
class MyState with _$MyState implements IUiFlowState {
  const factory MyState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
  }) = _MyState;
}
```

### Cubit
```dart
@injectable
class MyCubit extends QuanityaCubit<MyState> {
  final IRepository _repo;
  MyCubit(this._repo) : super(const MyState());
  
  Future<void> load() async {
    await tryOperation(() async {
      await _repo.load();
      return state.copyWith(status: UiFlowStatus.success);
    }, emitLoading: true);
  }
}
```

### Model
```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({required String id}) = _MyModel;
  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

### Service
```dart
@lazySingleton
class MyService {
  final IDependency _dep;
  MyService(this._dep);
}
```

## Build
```bash
dart run build_runner build --delete-conflicting-outputs
```