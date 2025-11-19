import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobility_app/screens/main_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

final onboardingProvider = Provider<bool>(
  (ref) => false,
); 

class AuthState {
  final bool isAuthenticated;
  const AuthState({this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  void checkAuthStatus() {
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier();
});

final themeControllerProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.system,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado com sucesso!');
  } catch (e) {
    print('❌ Erro ao inicializar o Firebase: $e');
  }

  const storage = FlutterSecureStorage();
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
