import 'package:flutter/material.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../features/error_reporting/pages/error_box_page.dart';

/// Quanitya-styled error box page builder
/// 
/// Creates the error box page using Quanitya's design system
/// and navigation patterns.
class QuanityaErrorBoxPageBuilder extends ErrorBoxPageBuilder {
  const QuanityaErrorBoxPageBuilder();

  @override
  Widget build(BuildContext context) {
    return const ErrorBoxPage();
  }
}