# Data Flow Consistency Pattern

## Core Principle
**Database as Single Source of Truth**

Never create dual sources of truth by both writing to database AND passing updated models simultaneously.

## Allowed Patterns

### ✅ Write-Only (Preferred)
```dart
// Save to DB, let other components read fresh
await repository.save(updatedModel);
// Don't pass updatedModel to other components
```

### ✅ Read-Only Sharing
```dart
// Multiple UI pages can read from same cubit memory
final currentModel = state.currentModel;
// Pass existing/unchanged models between components
otherComponent.display(currentModel);
```

### ✅ Fresh Database Reads
```dart
// Each component loads its own fresh data
final freshModel = await repository.getById(id);
```

## Anti-Patterns

### ❌ Write + Pass (Creates Dual Truth)
```dart
// BAD: Both saves AND passes the same updated model
await repository.save(updatedModel);
otherComponent.update(updatedModel); // ← Creates inconsistency risk
```

### ❌ Memory-to-Memory Updates
```dart
// BAD: Direct memory transfers of updated data
cubitA.updateModel(newModel);
cubitB.receiveModel(newModel); // ← Should read from DB instead
```

## Implementation Guidelines

### In Cubits
```dart
// ✅ GOOD: Save and let others read fresh
Future<void> saveModel() async {
  await tryOperation(() async {
    await repository.save(state.model);
    // Other components will read fresh from DB
    return state.copyWith(status: UiFlowStatus.success);
  });
}

// ✅ GOOD: Load fresh data
Future<void> loadModel(String id) async {
  await tryOperation(() async {
    final model = await repository.getById(id);
    return state.copyWith(model: model, status: UiFlowStatus.success);
  });
}
```

### In Repositories
```dart
// ✅ GOOD: Clear separation of concerns
Future<void> save(Model model) async {
  await dao.insert(model);
  // Don't return or cache the model
}

Future<Model?> getById(String id) async {
  return await dao.findById(id);
  // Always return fresh from DB
}
```

## Benefits

- **Consistency**: Database is always the authoritative source
- **Predictability**: Components always get fresh, consistent data
- **Debugging**: Easier to trace data flow and state changes
- **Concurrency**: Prevents race conditions from stale memory state

## Exception: UI State Sharing

Multiple UI components CAN share the same cubit memory for display purposes:

```dart
// ✅ ALLOWED: Multiple pages reading same cubit state
BlocBuilder<ModelCubit, ModelState>(
  builder: (context, state) => DisplayWidget(state.model),
)
```

This is safe because it's read-only sharing of existing state, not creating new sources of truth.