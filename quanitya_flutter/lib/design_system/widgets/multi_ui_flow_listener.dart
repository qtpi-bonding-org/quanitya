import 'package:flutter/material.dart';

/// Reduces deeply nested [UiFlowListener] pyramids into a flat list.
///
/// Each entry in [listeners] is a builder that wraps its argument in a
/// [UiFlowListener]. They are nested inside-out so the first entry in the
/// list is the outermost listener.
///
/// ```dart
/// MultiUiFlowListener(
///   listeners: [
///     (child) => UiFlowListener<FooCubit, FooState>(
///       mapper: GetIt.instance<FooMessageMapper>(),
///       child: child,
///     ),
///     (child) => UiFlowListener<BarCubit, BarState>(
///       mapper: GetIt.instance<BarMessageMapper>(),
///       child: child,
///     ),
///   ],
///   child: const MyContent(),
/// )
/// ```
class MultiUiFlowListener extends StatelessWidget {
  final List<Widget Function(Widget child)> listeners;
  final Widget child;

  const MultiUiFlowListener({
    super.key,
    required this.listeners,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    for (final listener in listeners.reversed) {
      result = listener(result);
    }
    return result;
  }
}
