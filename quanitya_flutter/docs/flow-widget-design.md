# FlowWidget — Declarative Screen Wiring

## Problem

The cubit layer is clean — `tryOperation()`, `UiFlowState`, message mappers all work well. But every screen repeats the same wiring boilerplate:

```dart
BlocProvider(
  create: (_) => GetIt.instance<SomeCubit>()..load(),
  child: UiFlowListener<SomeCubit, SomeState>(
    mapper: GetIt.instance<SomeMessageMapper>(),
    listener: (context, state) {
      if (state.isSuccess) AppNavigation.back(context);
    },
    child: BlocBuilder<SomeCubit, SomeState>(
      builder: (context, state) => /* actual UI */,
    ),
  ),
)
```

Multi-cubit screens (like OfficePage) have 7 BlocProviders + 9 UiFlowListeners. The `MultiUiFlowListener` flattens nesting but doesn't reduce the repetition — each entry is the same shape with different types.

## Goal

One base class that eliminates wiring boilerplate. Cubits and states stay untouched. The screen declares what it needs, `FlowWidget` handles the plumbing.

## Design

### FlowWidget

```dart
class PostScreen extends FlowWidget {
  @override
  List<FlowProvider> get providers => [
    FlowProvider<PostCubit, PostState>(
      create: () => GetIt.instance<PostCubit>(),
      onSuccess: (context, state) => AppNavigation.back(context),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) => PostForm(...);
}
```

`FlowWidget.build()` internally creates:
1. `MultiBlocProvider` from all providers
2. `UiFlowListener` per provider (with auto-resolved mapper)
3. Calls `buildContent()` inside the listener tree

### FlowProvider

```dart
class FlowProvider<C extends AppCubit<S>, S extends IUiFlowState> {
  /// Creates the cubit instance. Called once.
  final C Function() create;

  /// Use BlocProvider.value instead of BlocProvider (for singletons).
  final bool isValue;

  /// Called when this cubit's state reaches success.
  final void Function(BuildContext context, S state)? onSuccess;

  /// If set, shows a confirmation dialog before the cubit's action executes.
  /// The action must be wrapped with `flowExecute()` in the UI for this to work.
  final String? confirmBefore;

  /// Whether to show toast feedback for this cubit's state changes.
  /// Default: true.
  final bool feedback;
}
```

### Loading — Not a FlowProvider Concern

Loading is controlled per-operation in the cubit via `tryOperation(emitLoading: true/false)`.
The same cubit can have fast actions (no overlay) and slow actions (overlay). Only the cubit
knows which is which — the screen doesn't know what operation is running.

Example from `ScheduleListCubit`:
```dart
toggleEnabled()    → emitLoading: false  // quick, no overlay
createSchedule()   → emitLoading: true   // network call, show overlay
updateSchedule()   → emitLoading: false  // seamless background update
deleteSchedule()   → emitLoading: true   // destructive, show overlay
```

`FlowWidget` just reacts to whatever state the cubit emits. The `UiFlowListener` shows/hides
the loading overlay based on `state.isLoading` — no configuration needed.

### Per-Cubit Behaviors

Everything that varies between cubits lives on `FlowProvider`:

| Behavior | FlowProvider param | Default |
|----------|-------------------|---------|
| Navigate on success | `onSuccess` | null (no nav) |
| Confirm before action | `confirmBefore` | null (no confirm) |
| Toast feedback | `feedback` | true |
| Loading overlay | *(cubit-owned via `emitLoading`)* | — |

### Examples

**Simple submit + navigate:**
```dart
class PostScreen extends FlowWidget {
  @override
  List<FlowProvider> get providers => [
    FlowProvider<PostCubit, PostState>(
      create: () => GetIt.instance<PostCubit>(),
      onSuccess: (context, state) => AppNavigation.back(context),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) => PostForm(
    onSubmit: () => context.read<PostCubit>().submitPost(text: '...'),
  );
}
```

**Destructive action with confirmation:**
```dart
class DeletePostScreen extends FlowWidget {
  @override
  List<FlowProvider> get providers => [
    FlowProvider<DeleteCubit, DeleteState>(
      create: () => GetIt.instance<DeleteCubit>(),
      confirmBefore: 'Delete this post? This cannot be undone.',
      onSuccess: (context, state) => AppNavigation.back(context),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) => DeleteButton(
    onPressed: () => context.read<DeleteCubit>().delete(id),
  );
}
```

**Edit form with controller lifecycle:**
```dart
class EditProfileScreen extends FlowWidget {
  @override
  List<FlowProvider> get providers => [
    FlowProvider<ProfileCubit, ProfileState>(
      create: () => GetIt.instance<ProfileCubit>()..loadOwnProfile(),
      onSuccess: (context, state) => AppNavigation.back(context),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) => EditProfileForm(...);
}
```

Note: Controller lifecycle stays in the form widget itself (StatefulWidget). FlowWidget doesn't manage controllers — that's the form's job.

**Multi-cubit settings page:**
```dart
class OfficePage extends FlowWidget {
  @override
  List<FlowProvider> get providers => [
    FlowProvider<DataExportCubit, DataExportState>(
      create: () => GetIt.instance<DataExportCubit>(),
    ),
    FlowProvider<RecoveryKeyCubit, RecoveryKeyState>(
      create: () => GetIt.instance<RecoveryKeyCubit>(),
    ),
    FlowProvider<WebhookCubit, WebhookState>(
      create: () => GetIt.instance<WebhookCubit>()..load(),
    ),
    FlowProvider<DeviceManagementCubit, DeviceManagementState>(
      create: () => GetIt.instance<DeviceManagementCubit>(),
    ),
    FlowProvider<LlmProviderCubit, LlmProviderState>(
      create: () => GetIt.instance<LlmProviderCubit>(),
      isValue: true,
    ),
    FlowProvider<AppSyncingCubit, AppSyncingState>(
      create: () => GetIt.instance<AppSyncingCubit>(),
      isValue: true,
    ),
    FlowProvider<SyncStatusCubit, SyncStatusState>(
      create: () => GetIt.instance<SyncStatusCubit>(),
      isValue: true,
    ),
    FlowProvider<PurchaseCubit, PurchaseState>(
      create: () => GetIt.instance<PurchaseCubit>(),
    ),
    FlowProvider<EntitlementCubit, EntitlementState>(
      create: () => GetIt.instance<EntitlementCubit>(),
    ),
  ];

  @override
  Widget buildContent(BuildContext context) => SwipeablePageShell(...);
}
```

That's 9 cubits wired up in ~30 lines vs the current ~70 lines of providers + listeners.

**Disable feedback for a specific cubit:**
```dart
FlowProvider<SyncStatusCubit, SyncStatusState>(
  create: () => GetIt.instance<SyncStatusCubit>(),
  isValue: true,
  feedback: false, // sync status changes silently
  // loading is cubit-owned — SyncStatusCubit uses emitLoading: false internally
),
```

## Mapper Auto-Resolution

`FlowProvider` auto-resolves the message mapper from GetIt by convention:

```dart
// FlowProvider internally does:
final mapper = GetIt.instance.isRegistered<IStateMessageMapper<S>>()
    ? GetIt.instance<IStateMessageMapper<S>>()
    : null;
```

If a mapper is registered for the state type, it's used. If not, falls back to the global `IExceptionKeyMapper`. No manual mapper injection needed.

This requires mappers to be registered by state type:
```dart
// In bootstrap or injectable module:
getIt.registerFactory<IStateMessageMapper<DataExportState>>(
  () => DataExportMessageMapper(),
);
```

This is a convention change from current code (which registers by mapper class name). The `@injectable` annotation could handle this with a custom registration.

## UiFlowListener Refactor

Separate from FlowWidget, refactor `UiFlowListener` to accept a list natively. Kill `MultiUiFlowListener`.

```dart
// Single cubit (unchanged API):
UiFlowListener<MyCubit, MyState>(
  mapper: ...,
  child: ...,
)

// Multiple cubits (new):
UiFlowListener.multi(
  flows: [
    UiFlow<DataExportCubit, DataExportState>(mapper: ...),
    UiFlow<WebhookCubit, WebhookState>(mapper: ...),
  ],
  child: ...,
)
```

`MultiUiFlowListener` becomes deprecated → removed.

## Design Decisions

### No mixins (for now)

Everything is either default-on (feedback, loading overlay) or per-cubit (`onSuccess`, `confirmBefore`, `feedback: false`). Loading is per-operation in the cubit itself (`emitLoading`).

No cross-cutting behavior has emerged that isn't handled by these two levels. If one does during migration, add a mixin then. Don't design for hypothetical needs.

### Loading is cubit-owned, not screen-owned

The cubit decides per-operation whether to emit loading state via `tryOperation(emitLoading: true/false)`. The screen just reacts. This is correct because only the cubit knows whether an operation is a quick toggle or a slow network call.

### confirmBefore — how does it intercept the action?

When a `FlowProvider` has `confirmBefore` set, the cubit action needs to be intercepted before execution. Options:

**A) Wrap at the call site:**
```dart
// In the UI:
flowExecute(
  context,
  () => context.read<DeleteCubit>().delete(id),
);
// flowExecute checks if the provider has confirmBefore, shows dialog, then calls the action
```

**B) Override in the cubit:**
The cubit's `tryOperation` checks for a confirmation requirement before executing.

**C) Wrap the button widget:**
```dart
FlowAction<DeleteCubit>(
  onPressed: () => context.read<DeleteCubit>().delete(id),
  child: Text('Delete'),
)
// FlowAction knows about confirmBefore from the nearest FlowWidget
```

Option C is cleanest — the button widget handles confirmation automatically based on the FlowProvider config.

### BlocBuilder — where does it go?

`FlowWidget.buildContent()` gives you the `BuildContext` but not the state. You still need `BlocBuilder` inside `buildContent()` to react to state:

```dart
@override
Widget buildContent(BuildContext context) {
  return BlocBuilder<PostCubit, PostState>(
    builder: (context, state) => PostForm(isLoading: state.isLoading),
  );
}
```

For single-cubit screens, could `buildContent` pass the state directly:

```dart
@override
Widget buildContent(BuildContext context, PostState state) {
  return PostForm(isLoading: state.isLoading);
}
```

But this only works for single-cubit screens. Multi-cubit screens would use `buildContent(BuildContext context)` and `BlocBuilder` internally.

Maybe two methods:
- `buildContent(BuildContext context)` — multi-cubit, manual builders
- Override `buildWithState(BuildContext context, S state)` on single-cubit FlowWidget — auto-wrapped in BlocBuilder

## Implementation Order

1. Refactor `UiFlowListener` to support `.multi()` — kill `MultiUiFlowListener`
2. Build `FlowProvider` class
3. Build `FlowWidget` base class
4. Add mapper auto-resolution convention
5. Migrate one simple screen (e.g., PostCreationScreen) as proof of concept
6. Migrate OfficePage as multi-cubit proof of concept
7. Add `confirmBefore` support
8. Evaluate if mixins are needed based on real migration experience
