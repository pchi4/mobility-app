import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'theme/theme_controller.dart';
import 'package:mobility_app/screens/home_screen.dart';
import 'package:mobility_app/screens/splash_onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = const FlutterSecureStorage();
  final onboardingDone = await storage.read(key: 'onboarding_done');
  runApp(
    ProviderScope(
      overrides: [
        onboardingProvider.overrideWithValue(onboardingDone == 'true'),
      ],
      child: const MobilityApp(),
    ),
  );
}

final onboardingProvider = Provider<bool>((ref) => false);

class MobilityApp extends ConsumerWidget {
  const MobilityApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final auth = ref.watch(authNotifierProvider);
    final onboardingDone = ref.watch(onboardingProvider);

    Widget startScreen;
    if (!onboardingDone) {
      startScreen = const OnboardingScreen();
    } else if (auth.isAuthenticated) {
      startScreen = const HomeScreen();
    } else {
      startScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Mobility App (Starter)',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
      ),
      home: startScreen,
    );
  }
}
