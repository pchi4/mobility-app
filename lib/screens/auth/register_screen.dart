import 'package:flutter/material.dart';

// ignore: constant_identifier_names
const String API_BASE_URL =
    'https://localhost:3000'; // Substitua pela URL real da sua API

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isMotorista =
      false; // Define se o cadastro é para Motorista ou Passageiro
  bool _isPasswordVisible = false;
  String _message = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // SIMULAÇÃO DE REQUISIÇÃO HTTP (Cadastro)
  Future<Map<String, dynamic>> _simulatedHttpRegister(
    String url,
    Map<String, dynamic> body,
  ) async {
    // print('SIMULANDO REGISTRO para $url com BODY: $body');
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simulação de erro de e-mail duplicado
    if (body['email'] == 'duplicado@teste.com') {
      throw Exception('409|Este e-mail já está em uso.');
    }

    // Retorna sucesso
    return {'message': 'Cadastro realizado com sucesso!', 'role': body['role']};
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final endpoint = _isMotorista
        ? '/motorista/cadastro'
        : '/passageiro/cadastro';
    final url = '$API_BASE_URL$endpoint';

    // O payload inclui o campo "role" para diferenciar a lógica de registro,
    // embora o endpoint já faça essa distinção.
    final payload = {
      'nome': _nameController.text,
      'email': _emailController.text,
      'senha': _passwordController.text,
      'role': _isMotorista ? 'motorista' : 'passageiro',
    };

    try {
      await _simulatedHttpRegister(url, payload);

      if (!mounted) return;

      // Mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMotorista
                ? 'Cadastro de Motorista enviado. Aguarde a aprovação!'
                : 'Cadastro de Passageiro realizado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Volta para a tela de Login
      Navigator.of(context).pop();
    } catch (e) {
      String errorMessage = 'Erro desconhecido ao cadastrar. Tente novamente.';
      if (e.toString().contains('|')) {
        final parts = e.toString().split('|');
        errorMessage = parts.last;
      }
      setState(() {
        _message = errorMessage;
      });
      // print('Erro de Cadastro: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para alternar o modo de cadastro
  void _toggleRole(bool isMotorista) {
    if (_isLoading) return;
    setState(() {
      _isMotorista = isMotorista;
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
        title: Text(
          _isMotorista ? 'Cadastro de Motorista' : 'Cadastro de Passageiro',
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
                // Subtítulo
                Text(
                  'Crie sua conta no 99Gemini. É rápido e fácil!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Card de Cadastro
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
                          color: inputFillColor,
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
                      const SizedBox(height: 30),

                      // Campo de Nome
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Nome Completo',
                        icon: Icons.person_outline,
                        gradientStart: gradientStart,
                        inputFillColor: inputFillColor,
                        borderRadius: borderRadius,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'O nome é obrigatório.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de E-mail
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.email_outlined,
                        gradientStart: gradientStart,
                        inputFillColor: inputFillColor,
                        borderRadius: borderRadius,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'E-mail inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de Senha
                      _buildPasswordFormField(
                        controller: _passwordController,
                        label: 'Senha',
                        hint: 'Mínimo 6 caracteres',
                        gradientStart: gradientStart,
                        inputFillColor: inputFillColor,
                        borderRadius: borderRadius,
                        theme: theme,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de Confirmação de Senha
                      _buildPasswordFormField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar Senha',
                        hint: 'Repita a senha',
                        gradientStart: gradientStart,
                        inputFillColor: inputFillColor,
                        borderRadius: borderRadius,
                        theme: theme,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem.';
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

                      // Botão de Cadastro
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
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
                            onTap: _isLoading ? null : _handleRegister,
                            borderRadius: BorderRadius.circular(borderRadius),
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
                                  : Text(
                                      _isMotorista
                                          ? 'CADASTRAR MOTORISTA'
                                          : 'CADASTRAR PASSAGEIRO',
                                      style: const TextStyle(
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

                // Botão para voltar ao Login
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Já tem conta? Fazer Login',
                    style: TextStyle(
                      color: theme.primaryColorLight,
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

  // Helper para o campo de texto padrão (Nome, E-mail)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color gradientStart,
    required Color inputFillColor,
    required double borderRadius,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: gradientStart),
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: gradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  // Helper para o campo de senha (com toggle de visibilidade)
  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color gradientStart,
    required Color inputFillColor,
    required double borderRadius,
    required ThemeData theme,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: gradientStart),
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: gradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: theme.primaryColorLight,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: validator,
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
    final isSelected = _isMotorista == isMotorista;
    const double borderRadius = 10.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: InkWell(
          onTap: () => _toggleRole(isMotorista),
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
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
