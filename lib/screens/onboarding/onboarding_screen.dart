import 'package:flutter/material.dart';
import 'package:mobility_app/screens/login/login_screen.dart';

  

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
      'description': 'Acompanhe seu motorista e o trajeto com precisão milimétrica.',
    },
    {
      'icon': Icons.security,
      'title': 'Segurança Primeiro',
      'description': 'Viagens seguras com motoristas verificados e suporte 24 horas.',
    },
    {
      'icon': Icons.monetization_on,
      'title': 'Preços Justos',
      'description': 'As melhores tarifas e estimativas transparentes antes de confirmar.',
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
        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey[400],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Função para navegar para a Tela de Login (A-2)
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // Navega para a tela de Login
        builder: (_) => LoginScreen(),
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
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
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
                      Icon(data['icon'], size: 120, color: theme.primaryColor),
                      const SizedBox(height: 50.0),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingData.length, _buildPageIndicator),
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
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeIn,
                    );
                  } else {
                    _navigateToLogin();
                  }
                },
                child: Text(
                  _currentPage == _onboardingData.length - 1 ? 'COMEÇAR AGORA' : 'PRÓXIMO',
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