// lib/screens/home/map_view.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobility_app/viewmodels/home_view_model.dart';
import 'package:mobility_app/screens/home/passenger_ui_widgets.dart'; // Importa todos os widgets UI

// O MapSection precisa ser um ConsumerWidget para ler o ViewModel
class MapSection extends ConsumerWidget {
  final bool isPassenger;
  final bool isMapReady;
  final LatLng currentPosition;
  final bool hasRealLocation;
  final Set<Marker> markers;
  final Color primaryColor;
  final Function(GoogleMapController) onMapCreated;

  const MapSection({
    super.key,
    required this.isPassenger,
    required this.isMapReady,
    required this.currentPosition,
    required this.hasRealLocation,
    required this.markers,
    required this.primaryColor,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final tripRequestStatus = viewModel.tripRequestStatus;

    Widget controlPanel;
    double? bottom;
    double? top;

    // 1. Defina o Widget de Controle e suas Ações
    if (isPassenger) {
      final readViewModel = ref.read(homeViewModelProvider);

      controlPanel = PassengerUiWidgets(
        tripRequestStatus: tripRequestStatus,
        searchController: viewModel.searchController,
        primaryColor: primaryColor,
        mockPrice: viewModel.mockPrice,
        currentAddress: viewModel.currentAddress,
        destinationAddress: viewModel.destinationAddress,
        selectedCategory: viewModel.selectedCategory,
        acceptedDriverData: viewModel.acceptedDriverData,

        // FUNÇÕES CONECTADAS AO VIEWMDL
        onSelectDestination: readViewModel.selectDestination,
        onRequestTrip: readViewModel.saveTripRequestToFirestore,
        onCancelRequest: readViewModel.onCancelRequest,
        onCategorySelected: readViewModel.onCategorySelected,
        onClearSearch: readViewModel.clearSearch,
        onStartSearch: readViewModel.startSearch,
      );

      // 2. Defina o Posicionamento com base no Status
      if (tripRequestStatus == TripRequestStatus.IDLE ||
          tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION) {
        // MODO BUSCA (Campo de busca): Posicionado no topo
        top = 10.0;
        bottom = null;
      } else {
        // MODO CONFIRMAÇÃO/ACOMPANHAMENTO (Cartão de preço): Posicionado na parte inferior
        top = null;
        bottom = 0.0;
      }
    } else {
      // Lógica do Motorista
      // Substitua pelo seu DriverUi real que exibe o pendingRequest
      controlPanel = DriverUiPlaceholder(
        pendingRequest: viewModel.pendingRequest,
        onAcceptRequest: ref.read(homeViewModelProvider).acceptRequest,
        primaryColor: primaryColor,
      );
      bottom = 0.0;
      top = null;
    }

    return Stack(
      children: [
        // 1. O GoogleMap
        GoogleMap(
          mapType: MapType.normal,
          // Garante que o mapa tenha uma posição inicial para carregar
          initialCameraPosition: CameraPosition(
            target: currentPosition,
            zoom: 15.0,
          ),
          onMapCreated: onMapCreated,
          myLocationEnabled: hasRealLocation,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          markers: markers,
        ),

        // 2. O Painel de Controle (Reposicionado)
        Positioned(
          top: top,
          bottom: bottom,
          left: 0,
          right: 0,
          child: controlPanel,
        ),

        // 3. Botões de Acesso Rápido
        QuickAccessButtons(
          primaryColor: primaryColor,
          tripRequestStatus: tripRequestStatus,
        ),
      ],
    );
  }
}

// ======================================================================
// WIDGET PLACEHOLDER DO MOTORISTA (Mova para um arquivo driver_ui.dart se quiser separar)
// ======================================================================
class DriverUiPlaceholder extends StatelessWidget {
  final Map<String, dynamic>? pendingRequest;
  final Future<void> Function(String) onAcceptRequest;
  final Color primaryColor;

  const DriverUiPlaceholder({
    super.key,
    required this.pendingRequest,
    required this.onAcceptRequest,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingRequest == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: Text(
            'Aguardando novas requisições...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      );
    }

    final destinationAddress =
        pendingRequest!['destination']['address'] ?? 'Endereço Desconhecido';
    final category = pendingRequest!['category'] ?? 'Pop';
    final requestId = pendingRequest!['id'] as String;

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚨 NOVA SOLICITAÇÃO DE VIAGEM (${category.toUpperCase()})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Divider(),
              Text(
                'Destino: $destinationAddress',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => onAcceptRequest(requestId),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'ACEITAR CORRIDA',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
