import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final flutterSecureStorage = const FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _roleKey = 'auth_role';

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? role; // "passenger" or "driver"
  final String? userName;

  AuthState({
    required this.isAuthenticated,
    this.token,
    this.role,
    this.userName,
  });

  AuthState.unauth()
    : isAuthenticated = false,
      token = null,
      role = null,
      userName = null;
  AuthState.authenticated(String token, String role, String userName)
    : isAuthenticated = true,
      this.token = token,
      this.role = role,
      this.userName = userName;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauth()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final token = await flutterSecureStorage.read(key: _tokenKey);
    final role = await flutterSecureStorage.read(key: _roleKey);
    final userName = await flutterSecureStorage.read(key: 'user_name');
    if (token != null && role != null) {
      state = AuthState.authenticated(token, role, userName ?? 'Usuário');
    }
  }

  /// Mock login: in real app call API and persist tokens
  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    // mock validation
    await Future.delayed(const Duration(milliseconds: 700));
    final fakeToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
    await flutterSecureStorage.write(key: _tokenKey, value: fakeToken);
    await flutterSecureStorage.write(key: _roleKey, value: role);
    await flutterSecureStorage.write(
      key: 'user_name',
      value: email.split('@').first,
    );
    state = AuthState.authenticated(fakeToken, role, email.split('@').first);
  }

  Future<void> logout() async {
    await flutterSecureStorage.delete(key: _tokenKey);
    await flutterSecureStorage.delete(key: _roleKey);
    await flutterSecureStorage.delete(key: 'user_name');
    state = AuthState.unauth();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
