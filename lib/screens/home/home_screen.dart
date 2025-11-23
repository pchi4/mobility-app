// lib/screens/home/home_screen.dart (VERSÃO FINAL COM RIVERPOD)

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobility_app/screens/documents/documentos_screen.dart';
import 'package:mobility_app/screens/profile/profile_screen.dart';
import 'package:mobility_app/viewmodels/home_view_model.dart';
import 'map_view.dart'; // O MapSection que criamos/ajustamos

// Posição neutra (deve ser definida em um arquivo de constantes ou no ViewModel)
const LatLng _kNeutralFallbackPosition = LatLng(0, 0);

// ======================================================================
// 💡 MUDANÇA: Agora é ConsumerStatefulWidget
class HomeScreen extends ConsumerStatefulWidget {
  final String userRole;
  final String userId;

  const HomeScreen({super.key, required this.userRole, required this.userId});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // 🔑 ÚNICO ESTADO LOCAL TÉCNICO: O controlador do mapa.
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    // 💡 INICIALIZAÇÃO NO VIEWMDL
    Future.microtask(() {
      final viewModel = ref.read(homeViewModelProvider);
      // Chamamos a inicialização de serviços (Firebase, Localização, Escutas) no ViewModel.
      viewModel.setupAppInitialization(widget.userRole, widget.userId);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    // A maioria das subscriptions foi movida para o HomeViewModel e deve ser cancelada lá no dispose() dele.
    super.dispose();
  }

  // -----------------------------------------------------------------
  // 🗺️ FUNÇÃO DO MAPA (Conecta o Widget com o Controller Local)
  // -----------------------------------------------------------------

  /// FUNÇÃO DE CALLBACK DO WIDGET GoogleMap
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Notifica o ViewModel que o controlador está pronto.
    final viewModel = ref.read(homeViewModelProvider);
    viewModel.setMapControllerReady(controller);

    // O ViewModel agora é responsável por animar a câmera
  }

  // -----------------------------------------------------------------
  // 💾 LÓGICA DE NAVEGAÇÃO
  // -----------------------------------------------------------------

  void _onItemTapped(int index) {
    final viewModel = ref.read(homeViewModelProvider);

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Chame a lógica de transição no ViewModel (que gerencia streams)
    }
  }

  // -----------------------------------------------------------------
  // 🔨 BUILD METHOD PRINCIPAL
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // 🔑 CHAVE: Observar (watch) o HomeViewModel. A UI se reconstrói quando o estado muda.
    final viewModel = ref.watch(homeViewModelProvider);

    // Variáveis Lidas do ViewModel
    final isFirebaseReady = viewModel.isFirebaseReady;
    final isMapReady = viewModel.isMapReady;
    final currentPosition = viewModel.currentPosition;
    final tripRequestStatus =
        viewModel.tripRequestStatus; // Usado para QuickAccessButtons

    // Variáveis locais para estética
    final theme = Theme.of(context);
    final isPassenger = widget.userRole == 'passageiro';
    final primaryColor = theme.primaryColor;

    // 1. CARREGAMENTO INICIAL DO FIREBASE
    if (!isFirebaseReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando serviços (Firebase e Localização)...'),
            ],
          ),
        ),
      );
    }

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

    // 2. CARREGAMENTO DO MAPA/LOCALIZAÇÃO (Aba 0)
    if (_selectedIndex == 0 && currentPosition == null && !isMapReady) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 15),
            const Text('Aguardando localização GPS...'),
          ],
        ),
      );
      appBarTitle = 'Carregando Mapa';
    } else {
      // Posição para o mapa (real ou fallback)
      final positionToUse = currentPosition ?? _kNeutralFallbackPosition;
      final bool hasRealLocation = currentPosition != null;

      switch (_selectedIndex) {
        case 0:
          appBarTitle = isPassenger ? 'Pedir Viagem' : 'Modo Motorista';
          // 🔑 CHAVE: Usando o MapSection (HomeView) ajustado
          content = MapSection(
            isPassenger: isPassenger,
            isMapReady: isMapReady,
            currentPosition: positionToUse,
            hasRealLocation: hasRealLocation,
            markers: viewModel.markers,
            primaryColor: primaryColor,
            onMapCreated: _onMapCreated,
          );
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
          content = ProfileScreen(
            userRole: widget.userRole,
            userId: widget.userId,
          );
          break;
        default:
          content = const Center(child: Text('Tela Desconhecida'));
          appBarTitle = 'Erro';
      }
    }

    // A AppBar pode ser adicionada aqui, fora do switch, se desejar um padrão consistente
    return Scaffold(
      // Se você quiser a AppBar apenas nas abas 1 e 2:
      // Agora a AppBar só aparece se _selectedIndex for diferente de 0.
      appBar: _selectedIndex != 0 ? AppBar(title: Text(appBarTitle)) : null,

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
}
