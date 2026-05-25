import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';
import 'screens/auth/splash_screen.dart';
import 'services/app_navigation.dart';
import 'services/app_theme_notifier.dart';
import 'services/attendance_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (!AppConstants.disableAppCheck) {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      webProvider: AppConstants.appCheckRecaptchaSiteKey.isEmpty
          ? null
          : ReCaptchaV3Provider(AppConstants.appCheckRecaptchaSiteKey),
    );
  }
  await AttendanceNotificationService.instance.initialize();
  await AppThemeNotifier.instance.loadSaved();
  runApp(const CodesapiensApp());
}

class CodesapiensApp extends StatelessWidget {
  const CodesapiensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeNotifier.instance,
      builder: (context, _) => MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Codesapiens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
