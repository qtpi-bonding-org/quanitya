# Service & Repository Exception Handling Pattern

## Core Rules

### 1. Never Use `!` Operator
Use explicit null checks with typed exceptions instead.

```dart
// ❌ BAD
final key = await _repo.getKey()!;

// ✅ GOOD
final key = await _repo.getKey();
if (key == null) {
  throw MyException('Key not found');
}

// ✅ ALSO GOOD - using requireNonNull helper
final key = requireNonNull(
  await _repo.getKey(),
  'key',
  MyException.new,
);
```

### 2. Use `?.` and `??` for Valid Null States
When null is a valid state (not an error), use null-aware operators.

```dart
// ✅ GOOD - null is valid, use default
final name = user?.name ?? 'Anonymous';

// ✅ GOOD - optional chaining
final email = account?.profile?.email;
```

### 3. Wrap All Public Methods with tryMethod
Every public method in services and repositories must use the `tryMethod` helper.

```dart
import '../core/try_operation.dart';

Future<Account> createAccount() {
  return tryMethod(
    () async {
      final key = await _repo.getKey();
      if (key == null) {
        throw AccountException('Key not found');
      }
      return await _client.create(key);
    },
    AccountException.new,
    'createAccount',
  );
}
```

## Exception Flow

```
Repository throws KeyException
  → Service catches via tryMethod, wraps in AccountException
  → Cubit's tryOperation catches, sets status.failure + error
  → UiFlowListener maps to user message
```

## Helper Location

```dart
import 'package:quanitya/infrastructure/core/try_operation.dart';
```

## Benefits

- **Consistent error handling** across all layers
- **Better debugging** - always know where failures originate
- **Typed exceptions** - cubit_ui_flow can map to user messages
- **Extensible** - easy to add logging/metrics later in one place
- **No `!` risks** - explicit null handling with meaningful errors
