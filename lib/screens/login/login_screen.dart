import 'package:flutter/material.dart';
import 'package:mobility_app/screens/home/home_screen.dart';

// ignore: constant_identifier_names
const String API_BASE_URL =
    'https://localhost:3000'; // Substitua pela URL real da sua API

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'passageiro@teste.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '123456',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isMotoristaLogin = false;
  bool _isPasswordVisible = false; // Novo estado para visibilidade da senha
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // SIMULAÇÃO DE REQUISIÇÃO HTTP (Substitui a importação http real)
  Future<Map<String, dynamic>> _simulatedHttpCall(
    String url,
    Map<String, dynamic> body,
  ) async {
    // print('SIMULANDO POST para $url com BODY: $body');
    await Future.delayed(const Duration(milliseconds: 800));

    const PASSAGEIRO_EMAIL = 'passageiro@teste.com';
    const MOTORISTA_EMAIL = 'motorista@teste.com';

    if (body['senha'] != '123456') {
      throw Exception('401|Credenciais inválidas.');
    }

    if (url.contains('passageiro/login')) {
      if (body['email'] == PASSAGEIRO_EMAIL) {
        return {'accessToken': 'jwt-token-pass-1', 'role': 'passageiro'};
      }
    } else if (url.contains('motorista/login')) {
      if (body['email'] == MOTORISTA_EMAIL) {
        return {'accessToken': 'jwt-token-mot-1', 'role': 'motorista'};
      } else {
        throw Exception(
          '403|Sua conta está no status: PENDENTE. Aguarde a aprovação.',
        );
      }
    }

    throw Exception('404|Usuário não encontrado ou Rota inválida.');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final endpoint = _isMotoristaLogin
        ? '/motorista/login'
        : '/passageiro/login';
    final url = '$API_BASE_URL$endpoint';
    final payload = {
      'email': _emailController.text,
      'senha': _passwordController.text,
    };

    try {
      final responseBody = await _simulatedHttpCall(url, payload);

      final token = responseBody['accessToken'];
      final role = responseBody['role'] as String;

      // TODO: Armazenar o token usando flutter_secure_storage
      // print('LOGIN SUCESSO. Token: $token, Role: $role');

      if (!mounted) return;
      // Navega para a tela Home (A-3 simulada)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(userRole: role, userId: token.split('-').last),
        ),
      );
    } catch (e) {
      String errorMessage = 'Erro desconhecido. Tente novamente.';
      if (e.toString().contains('|')) {
        final parts = e.toString().split('|');
        errorMessage = parts.last;
      }
      setState(() {
        _message = errorMessage;
      });
      // print('Erro de Login: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para alternar o modo de login
  void _toggleRole(bool isMotorista) {
    if (_isLoading) return; // Não permite trocar durante o loading
    setState(() {
      _isMotoristaLogin = isMotorista;
      // Preenche automaticamente o e-mail de teste para conveniência
      _emailController.text = isMotorista
          ? 'motorista@teste.com'
          : 'passageiro@teste.com';
      _passwordController.text = '123456';
      _message = ''; // Limpa a mensagem de erro ao trocar de papel
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cor de fundo leve (indigo 50 no light, grey 900 no dark)
    final backgroundColor = theme.brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.indigo.shade50;

    // Cores do Gradiente Principal
    final gradientStart = theme.primaryColor;
    final gradientEnd = theme.primaryColor.withOpacity(0.7);

    // Cor de preenchimento dos campos de texto
    final inputFillColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]
        : Colors.grey[100];

    // Raio de borda padrão para todos os containers e botões
    const double borderRadius = 15.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _isMotoristaLogin ? 'Motorista' : 'Passageiro',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Título e Ícone
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.near_me, size: 40, color: gradientStart),
                    const SizedBox(width: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        '99Gemini',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, // Dummy color for ShaderMask
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtítulo de Boas-vindas
                Text(
                  'Bem-vindo(a)! Escolha seu perfil para continuar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Card de Login
                Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(
                      25,
                    ), // Raio maior para o card
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          theme.brightness == Brightness.dark ? 0.4 : 0.1,
                        ),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Botão de Toggle Motorista/Passageiro
                      Container(
                        decoration: BoxDecoration(
                          color:
                              inputFillColor, // Usa a mesma cor de preenchimento do input
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildRoleButton(
                              context,
                              false,
                              'Passageiro',
                              Icons.person_outline,
                            ),
                            _buildRoleButton(
                              context,
                              true,
                              'Motorista',
                              Icons.drive_eta_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Campo de E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu.email@exemplo.com', // Adiciona hint
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: gradientStart,
                          ),
                          // ESTILO MODERNIZADO
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide:
                                BorderSide.none, // Borda padrão invisível
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: gradientStart,
                              width: 2,
                            ), // Borda destacada no foco
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'O e-mail é obrigatório.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Mínimo 6 caracteres', // Adiciona hint
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: gradientStart,
                          ),
                          // ESTILO MODERNIZADO
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: gradientStart,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: theme.primaryColorLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'A senha é obrigatória.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Mensagem de Erro/Sucesso
                      if (_message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Botão de Login com Efeito de Pressionar
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            borderRadius,
                          ), // Raio padronizado
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientStart.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _handleLogin,
                            borderRadius: BorderRadius.circular(
                              borderRadius,
                            ), // Raio padronizado
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'ENTRAR',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botão de Cadastro (Texto mais discreto, mas ainda destacável)
                TextButton(
                  onPressed: () {
                    // TODO: Implementar navegação para a tela de Cadastro
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navegar para a tela de Cadastro...'),
                      ),
                    );
                  },
                  child: Text(
                    'Não tem conta? Cadastre-se aqui',
                    style: TextStyle(
                      color: theme
                          .primaryColorLight, // Usa a cor clara para ser discreto, mas visível
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para os botões de função (Motorista/Passageiro) com animação
  Widget _buildRoleButton(
    BuildContext context,
    bool isMotorista,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _isMotoristaLogin == isMotorista;
    const double borderRadius = 10.0; // Raio interno dos botões

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: InkWell(
          onTap: () => _toggleRole(isMotorista),
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            // Usamos AnimatedContainer para transição suave de cor
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                ),
                const SizedBox(width: 8),
                // Envolver o Text com Flexible para evitar overflow
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
