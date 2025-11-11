import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Importações reais dos seus arquivos:
import 'package:mobility_app/screens/main_screen.dart';

final onboardingProvider = Provider<bool>(
  (ref) => false,
); // Será sobrescrito no main()

class AuthState {
  final bool isAuthenticated;
  const AuthState({this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  // Simule a autenticação do usuário.
  void checkAuthStatus() {
    // Lógica real aqui (ex: verificar token)
    // Para fins de teste, vamos definir como não autenticado inicialmente.
    // state = const AuthState(isAuthenticated: true);
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

  const storage = FlutterSecureStorage();
  final onboardingDone = await storage.read(key: 'onboarding_done');

  runApp(
    ProviderScope(
      overrides: [
        // Sobrescreve o valor inicial do provedor de Onboarding
        onboardingProvider.overrideWithValue(onboardingDone == 'true'),
      ],
      child: const MobilityApp(),
    ),
  );
}
