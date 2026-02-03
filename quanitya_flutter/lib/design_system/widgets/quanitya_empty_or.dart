import 'package:flutter/material.dart';
import 'quanitya_empty_state.dart';

/// Shows [child] when [isEmpty] is false, otherwise shows [QuanityaEmptyState].
/// 
/// Usage:
/// ```dart
/// QuanityaEmptyOr(
///   isEmpty: templates.isEmpty,
///   child: TemplateList(templates),
/// )
/// 
/// QuanityaEmptyOr(
///   isEmpty: user == null,
///   child: UserProfile(user!),
/// )
/// ```
class QuanityaEmptyOr extends StatelessWidget {
  final bool isEmpty;
  final Widget child;
  final Widget? emptyState;

  const QuanityaEmptyOr({
    super.key,
    required this.isEmpty,
    required this.child,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return emptyState ?? const QuanityaEmptyState();
    }
    return child;
  }
}
