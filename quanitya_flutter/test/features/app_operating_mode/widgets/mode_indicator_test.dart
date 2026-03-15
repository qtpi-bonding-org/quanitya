import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/features/app_operating_mode/cubits/app_operating_cubit.dart';
import 'package:quanitya_flutter/features/app_operating_mode/cubits/app_operating_state.dart';
import 'package:quanitya_flutter/features/app_operating_mode/models/app_operating_mode.dart';
import 'package:quanitya_flutter/features/app_operating_mode/widgets/mode_indicator.dart';

class MockAppOperatingCubit extends MockCubit<AppOperatingState>
    implements AppOperatingCubit {}

void main() {
  late MockAppOperatingCubit mockCubit;

  setUp(() {
    mockCubit = MockAppOperatingCubit();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AppOperatingCubit>.value(
        value: mockCubit,
        child: const Scaffold(body: ModeIndicator()),
      ),
    );
  }

  testWidgets('hidden in local mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(mode: AppOperatingMode.local),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('shows cloud icon when in cloud mode connected', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(
        mode: AppOperatingMode.cloud,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.cloud), findsOneWidget);
  });

  testWidgets('shows dns icon when in selfHosted mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppOperatingState(
        mode: AppOperatingMode.selfHosted,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.dns), findsOneWidget);
  });
}
