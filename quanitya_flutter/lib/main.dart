import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/bootstrap.dart';
import 'app/app.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ignore: avoid_print
  print('Quanitya build: ${const String.fromEnvironment('GIT_COMMIT_HASH', defaultValue: 'dev')}');

  await bootstrap();

  FlutterNativeSplash.remove();

  runApp(const QuanityaApp());
}
