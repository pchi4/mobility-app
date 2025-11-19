import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_screen.dart';
import 'passenger_ui_widgets.dart';
import 'driver_ui_widgets.dart';

typedef MapCreatedCallback = void Function(GoogleMapController controller);
typedef SelectDestinationCallback = void Function(String address);
typedef ToggleStatusCallback = void Function(bool isOnline);
typedef RequestTripCallback = Future<void> Function();
typedef CancelRequestCallback = void Function();
typedef SelectCategoryCallback = void Function(String category);

class MapSection extends StatelessWidget {
  final bool isPassenger;
  final bool isMapReady;
  final LatLng currentPosition;
  final bool hasRealLocation; // 🔑 NOVO PARÂMETRO
  final Set<Marker> markers;
  final Color primaryColor;
  final MapCreatedCallback onMapCreated;
  final TripRequestStatus tripRequestStatus;

  final TextEditingController searchController;
  final SelectDestinationCallback onSelectDestination;
  final VoidCallback onClearSearch;
  final String? currentAddress;
  final String? destinationAddress;
  final double mockPrice;
  final RequestTripCallback onRequestTrip;
  final CancelRequestCallback onCancelRequest;
  final String selectedCategory;
  final SelectCategoryCallback onCategorySelected;
  final Map<String, dynamic>? acceptedDriverData;

  final bool isDriverOnline;
  final ToggleStatusCallback onToggleDriverStatus;
  final Map<String, dynamic>? pendingRequest;
  final Function(String) onAcceptRequest;

  const MapSection({
    super.key,
    required this.isPassenger,
    required this.isMapReady,
    required this.currentPosition,
    required this.hasRealLocation, // 🔑 Requerido
    required this.markers,
    required this.primaryColor,
    required this.onMapCreated,
    required this.tripRequestStatus,
    required this.searchController,
    required this.onSelectDestination,
    required this.onClearSearch,
    this.currentAddress,
    this.destinationAddress,
    required this.mockPrice,
    required this.onRequestTrip,
    required this.onCancelRequest,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.acceptedDriverData,
    required this.isDriverOnline,
    required this.onToggleDriverStatus,
    this.pendingRequest,
    required this.onAcceptRequest,
  });

  @override
  Widget build(BuildContext context) {
    final googleMapWidget = GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: currentPosition,
        zoom: 15.0,
      ),
      markers: markers,
      myLocationEnabled: isMapReady,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
    );

    if (isPassenger) {
      // 📌 Lógica do Passageiro
      Widget? passengerUI;

      if (!hasRealLocation) {
        // Bloqueia a UI de busca se não houver localização real (exibe loading/aviso)
        passengerUI = Positioned(
          top: 50,
          left: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.location_disabled, color: primaryColor),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Obtendo seu GPS para iniciar a busca...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        );
      } else if (tripRequestStatus == TripRequestStatus.IDLE ||
          tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION) {
        // Exibe a barra de busca se estiver em IDLE ou escolhendo destino
        passengerUI = Positioned(
          top: 50,
          left: 15,
          right: 15,
          child: PassengerSearchUI(
            searchController: searchController,
            onSelectDestination: onSelectDestination,
            onClearSearch: onClearSearch,
            currentAddressFirstPart: currentAddress?.split(',').first,
            primaryColor: primaryColor,
            tripRequestStatus: tripRequestStatus,
          ),
        );
      } else if (tripRequestStatus == TripRequestStatus.PRICE_ESTIMATED ||
          tripRequestStatus == TripRequestStatus.REQUEST_SENT ||
          tripRequestStatus == TripRequestStatus.TRIP_ACCEPTED) {
        // Exibe o card de estimativa/status da viagem
        passengerUI = Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: PassengerPriceEstimateCard(
            tripRequestStatus: tripRequestStatus,
            primaryColor: primaryColor,
            mockPrice: mockPrice,
            destinationAddress: destinationAddress,
            currentAddress: currentAddress,
            onRequestTrip: onRequestTrip,
            onCancelRequest: onCancelRequest,
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
            acceptedDriverData: acceptedDriverData,
          ),
        );
      }

      return Stack(
        children: [
          googleMapWidget,
          if (passengerUI != null) passengerUI,
          if (isMapReady) const QuickAccessButtons(),
        ],
      );
    } else {
      // 📌 Lógica do Motorista
      return Stack(
        children: [
          googleMapWidget,

          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: DriverStatusToggle(
              isDriverOnline: isDriverOnline,
              onToggleDriverStatus: onToggleDriverStatus,
              primaryColor: primaryColor,
            ),
          ),

          if (pendingRequest != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DriverPendingRequestCard(
                pendingRequest: pendingRequest!,
                onAcceptRequest: onAcceptRequest,
                primaryColor: primaryColor,
              ),
            ),

          if (isMapReady) const QuickAccessButtons(),
        ],
      );
    }
  }
}

class QuickAccessButtons extends StatelessWidget {
  const QuickAccessButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 15,
      child: Column(
        children: [
          FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centralizando no GPS...')),
              );
            },
            heroTag: 'myLocation',
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).primaryColor,
            mini: true,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
