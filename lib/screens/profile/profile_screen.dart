import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../documents/documentos_screen.dart';
import 'history_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userRole;
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isDriver = userRole == 'motorista';
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final List<List<Map<String, dynamic>>> menuSections = [
      // Seção 1: Financeiro / Pagamento
      [
        {
          'title': isDriver ? 'Ganhos e Saldo' : 'Forma de Pagamento',
          'icon': Icons.wallet_outlined,
          'onTap': () =>
              _navigateTo(context, PaymentScreen(userRole: userRole)),
        },
      ],
      [
        {
          'title': 'Histórico de Viagens',
          'icon': Icons.history,
          'onTap': () => _navigateTo(context, const HistoryScreen()),
        },
        if (isDriver)
          {
            'title': 'Documentos e Veículo',
            'icon': Icons.description_outlined,
            'onTap': () => _navigateTo(context, const DocumentosScreen()),
          },
      ],
      [
        {
          'title': 'Configurações',
          'icon': Icons.settings_outlined,
          'onTap': () => _navigateTo(context, const SettingsScreen()),
        },
        {'title': 'Ajuda', 'icon': Icons.help_outline, 'onTap': () {}},
      ],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleHeader(context, isDriver, primaryColor, userId),

              for (final section in menuSections)
                _buildMenuSectionCard(context, section, primaryColor),

              _buildLogoutSection(context, primaryColor),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(
    BuildContext context,
    bool isDriver,
    Color primaryColor,
    String userId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuário Teste',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    isDriver ? 'Motorista Parceiro' : 'Passageiro',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: primaryColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ID: ${userId.length >= 8 ? userId.substring(0, 8) : userId}...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const Divider(height: 30, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildMenuSectionCard(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 15.0, right: 15.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: items.map((item) {
            final isLast = item == items.last;
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  leading: Icon(item['icon'], color: Colors.black87),
                  title: Text(
                    item['title'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.black54,
                  ),
                  onTap: item['onTap'] as void Function(),
                ),
                if (!isLast)
                  Divider(
                    height: 0,
                    indent: 15,
                    endIndent: 15,
                    color: Colors.grey.shade200,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Sair da Conta',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
          ),
          onTap: () => _showLogoutDialog(context),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Cancelar',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
