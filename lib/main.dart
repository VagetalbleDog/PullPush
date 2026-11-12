import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/workout_repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Manrope', 'NotoSansSC']) {
      final license =
          await rootBundle.loadString('assets/fonts/$family-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], license);
    }
  });
  runApp(const PullPushApp());
}

class PullPushApp extends StatelessWidget {
  const PullPushApp({super.key, this.repository, this.clock});

  final WorkoutRepository? repository;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PullPush',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeScreen(
        repository: repository ?? PreferencesWorkoutRepository(),
        clock: clock ?? DateTime.now,
      ),
    );
  }
}
