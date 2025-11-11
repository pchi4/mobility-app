import 'package:flutter/material.dart';
import 'dart:async'; // Necessário para a função de mapa (async)

// ======================================================================
// ESTE CÓDIGO TEM UM PLACEHOLDER DE MAPA.
// PARA USAR O MAPA REAL, VOCÊ DEVE DESCOMENTAR AS IMPORTAÇÕES ABAIXO
// APÓS CORRIGIR O ERRO NATIVO DO iOS/Android E ADICIONAR AS CHAVES DE API.
//
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// Tipos reais que você usaria:
// class LatLng { final double latitude; final double longitude; const LatLng(this.latitude, this.longitude); }
// class Marker { }
// class GoogleMapController { }
// class Position { }
//
// ======================================================================

// Coordenadas mockadas para o placeholder
const _kInitialPosition = {'latitude': -23.55052, 'longitude': -46.633308};
const _mockDriverPosition = {'latitude': -23.555, 'longitude': -46.640};

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String userId;

  const HomeScreen({super.key, required this.userRole, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Variáveis mockadas para a lógica de mapa
  dynamic _mapController; // GoogleMapController?
  Map<String, double> _currentPosition = _kInitialPosition;

  // ESTADO ESPECÍFICO DO PASSAGEIRO
  final TextEditingController _searchController = TextEditingController();
  String? _destinationAddress;
  bool _isSearchFocused = false;
  bool _isPriceEstimated = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Em um projeto real, você chamaria _getCurrentLocation() aqui.
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isPriceEstimated) return;

    setState(() {
      _isSearchFocused = _searchController.text.isNotEmpty;
    });
  }

  void _onSelectDestination(String address) {
    setState(() {
      _destinationAddress = address;
      _searchController.text = address.split(',').first;
      _isSearchFocused = false;
      _isPriceEstimated = true;

      // TODO: Em um projeto real, você moveria a câmera do mapa aqui.
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 0) {
        _searchController.clear();
        _destinationAddress = null;
        _isPriceEstimated = false;
        _isSearchFocused = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassenger = widget.userRole == 'passageiro';
    final primaryColor = theme.primaryColor;

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: Icon(isPassenger ? Icons.map_outlined : Icons.drive_eta_outlined),
        label: isPassenger ? 'Viagem' : 'Dirigir',
      ),
      BottomNavigationBarItem(
        icon: Icon(isPassenger ? Icons.history : Icons.receipt_long),
        label: isPassenger ? 'Histórico' : 'Ganhos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];

    Widget content;
    String appBarTitle;

    switch (_selectedIndex) {
      case 0:
        appBarTitle = isPassenger ? 'Pedir Viagem' : 'Modo Motorista';
        content = _buildMapSection(context, isPassenger);
        break;
      case 1:
        appBarTitle = isPassenger
            ? 'Histórico de Viagens'
            : 'Ganhos e Relatórios';
        content = Center(
          child: Text(
            isPassenger
                ? 'Lista de viagens passadas (Em Breve)'
                : 'Seus ganhos aqui (Em Breve)',
            style: theme.textTheme.titleMedium,
          ),
        );
        break;
      case 2:
        appBarTitle = 'Meu Perfil';
        content = _buildProfileSection(context);
        break;
      default:
        content = const Center(child: Text('Tela Desconhecida'));
        appBarTitle = 'Erro';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
          0.6,
        ),
        onTap: _onItemTapped,
        backgroundColor: theme.cardColor,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  // Seção principal do Mapa (Aba 0) - Implementação A-3 Home Passageiro
  Widget _buildMapSection(BuildContext context, bool isPassenger) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // ======================================================================
    // PLACEHOLDER TEMPORÁRIO PARA O GOOGLE MAPS
    // Remova este bloco e use o widget GoogleMap real após a correção nativa.
    // ======================================================================
    final Widget googleMapPlaceholder = Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B1B1B)
          : Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 120,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Mapa em Carregamento...',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
    // ======================================================================

    // Lógica para Motorista (A-4) - MODO MOTORISTA
    if (!isPassenger) {
      return Stack(
        children: [
          // MAPA REAL (Fundo)
          googleMapPlaceholder,

          // Painel Flutuante na parte inferior (Para Motorista)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status do Motorista: OFFLINE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Lógica para Motorista ficar ONLINE
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Você ficou ONLINE! Aguardando pedidos...',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text(
                        'FICAR ONLINE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Lógica para Passageiro (A-3 Home) - MODO PASSAGEIRO
    // ======================================================================

    final List<Map<String, String>> mockResults = [
      {'name': 'Aeroporto (GRU)', 'address': 'Guarulhos, São Paulo'},
      {'name': 'Casa', 'address': 'Rua das Flores, 101'},
      {'name': 'Trabalho', 'address': 'Av. Paulista, 900'},
    ];

    return Stack(
      children: [
        // 1. MAPA REAL (Fundo)
        googleMapPlaceholder,

        // 2. Barra de Busca com Autocomplete (Topo)
        Positioned(
          top: 50,
          left: 15,
          right: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de Busca
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                shadowColor: Colors.black.withOpacity(0.3),
                child: TextField(
                  controller: _searchController,
                  onTap: () {
                    if (!_isPriceEstimated) {
                      setState(() {
                        _isSearchFocused = true;
                      });
                    }
                  },
                  readOnly: _isPriceEstimated,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Para onde vamos?',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _destinationAddress = null;
                                _isPriceEstimated = false;
                                _isSearchFocused = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),

              // Resultados de Autocomplete/Sugestões (Flutuante)
              if (_isSearchFocused && !_isPriceEstimated)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: mockResults
                        .map(
                          (result) => ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: primaryColor.withOpacity(0.7),
                            ),
                            title: Text(
                              result['name']!,
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              result['address']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            onTap: () => _onSelectDestination(
                              '${result['name']}, ${result['address']}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),

        // 3. Camada: Estação de Preço Estimado (Exibição Condicional)
        if (_isPriceEstimated && _destinationAddress != null)
          Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              color: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white, width: 4),
              ),
              elevation: 15,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    const Text(
                      'Estação de Preço Estimado',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const Text(
                      'R\$ 35.90',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Destino: ${_destinationAddress!.split(',').first}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isPriceEstimated = false;
                            _destinationAddress = null;
                            _searchController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Viagem solicitada! Aguardando motorista...',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'SOLICITAR VIAGEM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 4. Botões de Rápido Acesso (Lateral Direita Inferior)
        Positioned(
          right: 15,
          bottom: 15,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'favBtn',
                mini: false,
                backgroundColor: theme.cardColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acessando seus Favoritos...'),
                    ),
                  );
                },
                child: Icon(Icons.favorite_border, color: primaryColor),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'payBtn',
                mini: false,
                backgroundColor: theme.cardColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acessando Formas de Pagamento...'),
                    ),
                  );
                },
                child: Icon(Icons.credit_card, color: primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Seção de Perfil (Aba 2)
  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isPassenger = widget.userRole == 'passageiro';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.account_circle,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPassenger ? 'Passageiro Teste' : 'Motorista Teste',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isPassenger
                            ? 'passageiro@teste.com'
                            : 'motorista@teste.com',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: ${widget.userId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          ListTile(
            leading: Icon(Icons.settings, color: primaryColor),
            title: Text(
              'Configurações da Conta',
              style: theme.textTheme.titleMedium,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.payment, color: primaryColor),
            title: Text(
              'Formas de Pagamento',
              style: theme.textTheme.titleMedium,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onTap: () {},
          ),
          if (!isPassenger)
            ListTile(
              leading: Icon(Icons.car_rental, color: primaryColor),
              title: Text(
                'Detalhes do Veículo',
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodyLarge?.color,
              ),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
