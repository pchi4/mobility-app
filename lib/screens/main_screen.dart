import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobility_app/main.dart';
// Importações reais dos seus arquivos:

import 'package:mobility_app/screens/home/home_screen.dart';
import 'package:mobility_app/screens/onboarding/onboarding_screen.dart';
import 'package:mobility_app/theme/theme_controller.dart';
import 'package:mobility_app/features/auth/auth_service.dart';
import 'package:mobility_app/screens/splash/splash_screen.dart';

class MobilityApp extends ConsumerWidget {
  const MobilityApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observa os estados necessários
    final themeMode = ref.watch(themeControllerProvider);

    const MaterialColor primaryColor = Colors.indigo;

    return MaterialApp(
      title: 'Mobility App (Configurado)',
      debugShowCheckedModeBanner: false,

      // Usa o themeMode observado pelo Riverpod
      themeMode: themeMode,

      // Tema Claro
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: primaryColor,
        scaffoldBackgroundColor: Colors.grey[50],
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // Tema Escuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: primaryColor,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
        appBarTheme: const AppBarTheme(color: Colors.black, elevation: 0),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
        ),
      ),

      // Define a tela inicial baseada na lógica condicionaal
      home: SplashScreen(),
    );
  }
}
