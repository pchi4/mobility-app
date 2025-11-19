import 'package:flutter/material.dart';
import 'package:mobility_app/screens/login/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 🔄 Voltamos para 'icon', mas mantemos as cores de fundo
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.pin_drop, // Ícone original
      'title': 'Localização em Tempo Real',
      'description':
          'Acompanhe seu motorista e o trajeto com precisão milimétrica.',
      'backgroundColor': const Color(0xFFF96291), // Rosa vibrante
    },
    {
      'icon': Icons.security, // Ícone original
      'title': 'Segurança Primeiro',
      'description':
          'Viagens seguras com motoristas verificados e suporte 24 horas.',
      'backgroundColor': const Color(0xFFEFE8D8), // Bege claro
    },
    {
      'icon': Icons.monetization_on, // Ícone original
      'title': 'Preços Justos',
      'description':
          'As melhores tarifas e estimativas transparentes antes de confirmar.',
      'backgroundColor': const Color(0xFF3B5B57), // Verde escuro
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  // Indicador de Página (agora branco para maior contraste com os fundos coloridos)
  Widget _buildPageIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pegamos a cor da página atual
    final data = _onboardingData[_currentPage];

    return Scaffold(
      // 🎨 Fundo dinâmico
      backgroundColor: data['backgroundColor'],

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botão PULAR sempre visível
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'PULAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ), // Branco para contraste
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
                final pageData = _onboardingData[index];
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // 💡 Usando o Ícone com um tamanho maior
                      Icon(
                        pageData['icon'],
                        size: 150, // Ícone grande para destaque
                        color: Colors.white, // Ícone branco
                      ),
                      const SizedBox(height: 50.0),

                      // Título
                      Text(
                        pageData['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15.0),

                      // Descrição
                      Text(
                        pageData['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18.0,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Indicadores de Página e Botão Flutuante (FAB)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Indicadores
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    _buildPageIndicator,
                  ),
                ),

                // Botão Flutuante (FAB) para Navegar
                FloatingActionButton(
                  // Fundo do FAB é branco
                  backgroundColor: Colors.white,
                  child: Icon(
                    _currentPage == _onboardingData.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    // Cor do ícone é a cor de fundo da página (contraste!)
                    color: data['backgroundColor'],
                  ),
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeIn,
                      );
                    } else {
                      _navigateToLogin();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
