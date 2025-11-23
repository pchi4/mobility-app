import 'package:flutter/material.dart';

// Definindo uma estrutura simples para um item de configuração
class SettingItem {
  final String title;
  final IconData icon;
  final Widget? trailing; // Pode ser um Icon, Switch, ou texto
  final VoidCallback onTap;

  SettingItem({
    required this.title,
    required this.icon,
    this.trailing,
    required this.onTap,
  });
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Agrupando as opções de configuração por seções
    final List<Map<String, dynamic>> settingSections = [
      {
        'title': 'Geral',
        'items': [
          SettingItem(
            title: 'Editar Perfil',
            icon: Icons.person_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para Editar Perfil
            },
          ),
          SettingItem(
            title: 'Segurança e Senha',
            icon: Icons.lock_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para Segurança
            },
          ),
        ],
      },
      {
        'title': 'Preferências',
        'items': [
          SettingItem(
            title: 'Notificações',
            icon: Icons.notifications_none,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para Configurações de Notificação
            },
          ),
          SettingItem(
            title: 'Modo Escuro (Dark Mode)',
            icon: Icons.dark_mode_outlined,
            // Exemplo de como adicionar um Switch
            trailing: Switch(
              value: false, // Estado atual do modo escuro
              onChanged: (bool value) {
                // Implementar a lógica de alteração do tema
              },
              activeColor: primaryColor,
            ),
            onTap: () {}, // Sem ação se tiver um Switch
          ),
        ],
      },
      {
        'title': 'Informações',
        'items': [
          SettingItem(
            title: 'Ajuda e Suporte',
            icon: Icons.help_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para Ajuda/FAQ
            },
          ),
          SettingItem(
            title: 'Termos e Condições',
            icon: Icons.policy_outlined,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegar para Termos
            },
          ),
          SettingItem(
            title: 'Versão do Aplicativo',
            icon: Icons.info_outline,
            trailing: const Text('1.0.0'),
            onTap: () {},
          ),
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: settingSections.map((section) {
            return _buildSection(
              context,
              section['title'] as String,
              section['items'] as List<SettingItem>,
              primaryColor,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Constrói uma seção inteira (Ex: "Geral")
  Widget _buildSection(
    BuildContext context,
    String title,
    List<SettingItem> items,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 15.0,
        left: 15.0,
        right: 15.0,
        bottom: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da Seção
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),

          // Agrupamento dos Itens em um Card (Estilo Uber)
          Card(
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
                      leading: Icon(item.icon, color: Colors.black87),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing:
                          item.trailing ??
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black54,
                          ),
                      onTap: item.onTap,
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
        ],
      ),
    );
  }
}
