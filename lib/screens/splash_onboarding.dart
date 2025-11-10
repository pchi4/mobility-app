import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobility_app/features/auth/login_screen.dart';

final _storage = const FlutterSecureStorage();
const _onboardingKey = 'onboarding_done';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  final pages = [
    {
      'title': 'Bem-vindo ao Mobility',
      'text': 'Seu novo app de mobilidade urbana. Rápido, seguro e moderno.',
      'icon': Icons.directions_car,
    },
    {
      'title': 'Motoristas próximos',
      'text': 'Encontre motoristas em tempo real com apenas um toque.',
      'icon': Icons.map,
    },
    {
      'title': 'Viaje com confiança',
      'text': 'Avalie corridas, acompanhe o trajeto e curta sua viagem.',
      'icon': Icons.verified_user,
    },
  ];

  Future<void> _finish() async {
    await _storage.write(key: _onboardingKey, value: 'true');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final page = pages[i];
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(page['icon'] as IconData, size: 100, color: Colors.indigo),
                const SizedBox(height: 40),
                Text(
                  page['title'] as String,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  page['text'] as String,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                if (i == pages.length - 1)
                  ElevatedButton(
                    onPressed: _finish,
                    child: const Text('Começar'),
                  )
                else
                  TextButton(onPressed: _finish, child: const Text('Pular')),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pages.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _index ? Colors.indigo : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
