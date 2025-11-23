import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  // 💡 CHAVE: Precisamos saber o papel do usuário (Role)
  final String userRole;

  const PaymentScreen({
    super.key,
    this.userRole = 'passageiro',
  }); // Padrão: Passageiro

  @override
  Widget build(BuildContext context) {
    final isDriver = userRole == 'motorista';
    final primaryColor = Theme.of(context).primaryColor;

    // Título dinâmico
    final String title = isDriver
        ? 'Ganhos e Conta Bancária'
        : 'Formas de Pagamento';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Corpo da tela será dinâmico
      body: isDriver
          ? _buildDriverPaymentView(context, primaryColor)
          : _buildPassengerPaymentView(context, primaryColor),
    );
  }

  // --- 2. View para o Passageiro (Formas de Pagamento) ---
  Widget _buildPassengerPaymentView(BuildContext context, Color primaryColor) {
    // Dados simulados
    final List<Map<String, String>> paymentMethods = [
      {
        'icon': 'credit_card',
        'name': 'MasterCard final 4567',
        'type': 'Principal',
      },
      {'icon': 'pix', 'name': 'Pix (Chave CPF)', 'type': 'Outra'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione ou Adicione uma Forma de Pagamento',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Lista de Cartões/Métodos
          ...paymentMethods
              .map(
                (method) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      method['icon'] == 'credit_card'
                          ? Icons.credit_card_outlined
                          : Icons.qr_code,
                      color: primaryColor,
                    ),
                    title: Text(method['name']!),
                    subtitle: Text(method['type']!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Ação: editar ou definir como principal
                    },
                  ),
                ),
              )
              .toList(),

          const Divider(height: 30),

          // Botão Adicionar
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: primaryColor),
            title: Text(
              'Adicionar Cartão/Pix',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // Navegar para tela de adição de cartão
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navegar para Adicionar Pagamento'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 3. View para o Motorista (Ganhos/Saldo) ---
  Widget _buildDriverPaymentView(BuildContext context, Color primaryColor) {
    // Dados simulados
    const double currentBalance = 154.75;
    const String bankAccount = 'Banco XYZ | Ag: 0001 | C/C: 98765-4';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💰 SALDO ATUAL
          Card(
            color: primaryColor.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Disponível',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'R\$ ${currentBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Ação: Iniciar saque
                    },
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'Solicitar Saque',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 🏦 CONTA BANCÁRIA CADASTRADA
          Text(
            'Conta para Recebimento',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.account_balance, color: primaryColor),
              title: const Text('Conta Cadastrada'),
              subtitle: Text(bankAccount),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Navegar para edição da conta
              },
            ),
          ),
          const SizedBox(height: 20),
          // Link para histórico de transações/ganhos (detalhe da aba 1 da HomeScreen)
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.grey),
            title: const Text('Ver Histórico de Ganhos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Ação: Navegar para a aba de Ganhos (Aba 1 da HomeScreen)
            },
          ),
        ],
      ),
    );
  }
}
