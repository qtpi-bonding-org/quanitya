import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_state.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/models/app_syncing_mode.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/widgets/mode_indicator.dart';

class MockAppSyncingCubit extends MockCubit<AppSyncingState>
    implements AppSyncingCubit {}

void main() {
  late MockAppSyncingCubit mockCubit;

  setUp(() {
    mockCubit = MockAppSyncingCubit();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AppSyncingCubit>.value(
        value: mockCubit,
        child: const Scaffold(body: ModeIndicator()),
      ),
    );
  }

  testWidgets('hidden in local mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppSyncingState(mode: AppSyncingMode.local),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('shows cloud icon when in cloud mode connected', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppSyncingState(
        mode: AppSyncingMode.cloud,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.cloud), findsOneWidget);
  });

  testWidgets('shows dns icon when in selfHosted mode', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const AppSyncingState(
        mode: AppSyncingMode.selfHosted,
        isConnected: true,
      ),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.dns), findsOneWidget);
  });
}
