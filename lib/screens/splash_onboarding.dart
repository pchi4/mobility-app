import 'package:flutter/material.dart';
import 'dart:async';

class NextScreen extends StatelessWidget {
  final String title;
  const NextScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Próxima Etapa: Login/Cadastro',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class AppMobilidade extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const MaterialColor primaryColor = Colors.indigo;

    return MaterialApp(
      title: '99Gemini Mobilidade',
      debugShowCheckedModeBanner: false,

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
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),

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
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),

      themeMode: ThemeMode.system,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, Colors.indigo.shade900]
                : [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone (Placeholder)
              Icon(Icons.alt_route, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              // Título
              Text(
                '99Gemini',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 30),
              // Indicador de Carregamento
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.pin_drop,
      'title': 'Localização em Tempo Real',
      'description':
          'Acompanhe seu motorista e o trajeto com precisão milimétrica.',
    },
    {
      'icon': Icons.security,
      'title': 'Segurança Primeiro',
      'description':
          'Viagens seguras com motoristas verificados e suporte 24 horas.',
    },
    {
      'icon': Icons.monetization_on,
      'title': 'Preços Justos',
      'description':
          'As melhores tarifas e estimativas transparentes antes de confirmar.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).primaryColor
            : Colors.grey[400],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Função para navegar
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // Navega para a próxima tela A-2 (simulada)
        builder: (_) => NextScreen(title: '99Gemini Login'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botão PULAR
          if (_currentPage < _onboardingData.length - 1)
            TextButton(
              onPressed: _navigateToLogin,
              child: Text(
                'PULAR',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _onboardingData.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Ícone do Card
                      Icon(data['icon'], size: 120, color: theme.primaryColor),
                      const SizedBox(height: 50.0),
                      // Título
                      Text(
                        data['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      // Descrição
                      Text(
                        data['description'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Indicadores de Página (Dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              _buildPageIndicator,
            ),
          ),
          const SizedBox(height: 30.0),

          // Botão Próximo/Começar
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, left: 40, right: 40),
            child: Container(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _onboardingData.length - 1) {
                    // Navega para a próxima página
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeIn,
                    );
                  } else {
                    // Última página: vai para o Login/Cadastro
                    _navigateToLogin();
                  }
                },
                child: Text(
                  _currentPage == _onboardingData.length - 1
                      ? 'COMEÇAR AGORA'
                      : 'PRÓXIMO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Para simular a execução no editor:
// void main() {
//   runApp(AppMobilidade());
// }
