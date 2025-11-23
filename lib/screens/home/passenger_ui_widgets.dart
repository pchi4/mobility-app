// lib/screens/home/passenger_ui_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobility_app/viewmodels/home_view_model.dart';

// Typedefs (Para garantir que as assinaturas das funções do ViewModel correspondam)
typedef RequestTripCallback = Future<void> Function();
typedef SelectDestinationCallback = void Function(String address);
typedef CancelRequestCallback = void Function();
typedef SelectCategoryCallback = void Function(String category);
typedef StartSearchCallback = void Function();

// ======================================================================
// 1. WIDGET PRINCIPAL: PassengerUiWidgets
// ======================================================================
class PassengerUiWidgets extends StatelessWidget {
  final TripRequestStatus tripRequestStatus;
  final TextEditingController searchController;
  final Color primaryColor;
  final double mockPrice;
  final String? currentAddress;
  final String? destinationAddress;
  final String selectedCategory;
  final Map<String, dynamic>? acceptedDriverData;
  // Ações
  final SelectDestinationCallback onSelectDestination;
  final RequestTripCallback onRequestTrip;
  final CancelRequestCallback onCancelRequest;
  final SelectCategoryCallback onCategorySelected;
  final VoidCallback onClearSearch;
  final StartSearchCallback onStartSearch;

  const PassengerUiWidgets({
    super.key,
    required this.tripRequestStatus,
    required this.searchController,
    required this.primaryColor,
    required this.mockPrice,
    this.currentAddress,
    this.destinationAddress,
    required this.selectedCategory,
    this.acceptedDriverData,
    required this.onSelectDestination,
    required this.onRequestTrip,
    required this.onCancelRequest,
    required this.onCategorySelected,
    required this.onClearSearch,
    required this.onStartSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (tripRequestStatus == TripRequestStatus.IDLE ||
        tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
            child: PassengerSearchUI(
              searchController: searchController,
              primaryColor: primaryColor,
              tripRequestStatus: tripRequestStatus,
              onSelectDestination: onSelectDestination,
              onClearSearch: onClearSearch,
              currentAddressFirstPart: currentAddress?.split(',').first,
              onStartSearch: onStartSearch,
            ),
          ),
        ],
      );
    }

    // Mostra o cartão de preço/acompanhamento
    return PassengerPriceEstimateCard(
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
    );
  }
}

// ======================================================================
// 2. WIDGET DE PESQUISA (PassengerSearchUI)
// ======================================================================
class PassengerSearchUI extends StatelessWidget {
  final TextEditingController searchController;
  final Color primaryColor;
  final TripRequestStatus tripRequestStatus;
  final SelectDestinationCallback onSelectDestination;
  final VoidCallback onClearSearch;
  final String? currentAddressFirstPart;
  final StartSearchCallback onStartSearch;

  const PassengerSearchUI({
    super.key,
    required this.searchController,
    required this.primaryColor,
    required this.tripRequestStatus,
    required this.onSelectDestination,
    required this.onClearSearch,
    required this.onStartSearch,
    this.currentAddressFirstPart,
  });

  @override
  Widget build(BuildContext buildContext) {
    final isSearchFocused =
        tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION;

    final List<Map<String, String>> mockResults = [
      {'name': 'Aeroporto (GRU)', 'address': 'Guarulhos, São Paulo'},
      {'name': 'Casa', 'address': 'Rua das Flores, 101'},
      {'name': 'Trabalho', 'address': 'Av. Paulista, 2000'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          child: TextField(
            controller: searchController,
            readOnly:
                tripRequestStatus != TripRequestStatus.IDLE &&
                tripRequestStatus != TripRequestStatus.CHOOSING_DESTINATION,
            decoration: InputDecoration(
              hintText: isSearchFocused
                  ? 'Digite o endereço de destino...'
                  : 'Para onde vamos, ${currentAddressFirstPart ?? 'Localização Atual'}?',
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: isSearchFocused
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onTap: () {
              if (tripRequestStatus == TripRequestStatus.IDLE) {
                onStartSearch();
              }
            },
          ),
        ),
        if (isSearchFocused)
          Card(
            margin: const EdgeInsets.only(top: 10),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockResults.length,
              itemBuilder: (context, index) {
                final result = mockResults[index];
                return ListTile(
                  leading: Icon(Icons.location_on, color: primaryColor),
                  title: Text(result['name']!),
                  subtitle: Text(result['address']!),
                  onTap: () {
                    onSelectDestination(
                      '${result['name']}, ${result['address']}',
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ======================================================================
// 3. CARD DE PREÇO E CONFIRMAÇÃO (PassengerPriceEstimateCard)
// ======================================================================
class PassengerPriceEstimateCard extends StatelessWidget {
  final TripRequestStatus tripRequestStatus;
  final Color primaryColor;
  final double mockPrice;
  final String? destinationAddress;
  final String? currentAddress;
  final RequestTripCallback onRequestTrip;
  final VoidCallback onCancelRequest;
  final String selectedCategory;
  final SelectCategoryCallback onCategorySelected;
  final Map<String, dynamic>? acceptedDriverData;

  const PassengerPriceEstimateCard({
    super.key,
    required this.tripRequestStatus,
    required this.primaryColor,
    required this.mockPrice,
    this.destinationAddress,
    this.currentAddress,
    required this.onRequestTrip,
    required this.onCancelRequest,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.acceptedDriverData,
  });

  Map<String, dynamic> _getCategoryInfo(String category) {
    double priceMultiplier = 1.0;
    IconData icon;
    String eta;

    switch (category) {
      case 'Comfort':
        priceMultiplier = 1.3;
        icon = Icons.local_taxi;
        eta = '6 min';
        break;
      case 'Black':
        priceMultiplier = 1.8;
        icon = Icons.local_car_wash;
        eta = '7 min';
        break;
      case 'Pop':
      default:
        priceMultiplier = 1.0;
        icon = Icons.car_rental;
        eta = '5 min';
        break;
    }
    final price = mockPrice * priceMultiplier;
    return {'price': price, 'eta': eta, 'icon': icon};
  }

  Widget _buildCategoryCard(String category) {
    final info = _getCategoryInfo(category);
    final isSelected = category == selectedCategory;

    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final priceText = formatter.format(info['price']);

    final icon = info['icon'] as IconData;
    final eta = info['eta'] as String;

    return GestureDetector(
      onTap: () => onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: 260,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? primaryColor : Colors.blueGrey.shade700,
              ),
            ),

            const SizedBox(width: 14),

            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    eta,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Text(
              priceText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: ['Pop', 'Comfort', 'Black'].map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildCategoryCard(category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripTrackingUI(BuildContext context) {
    final theme = Theme.of(context);
    final currentCategory = selectedCategory;
    final driver = acceptedDriverData;

    String statusText;
    if (tripRequestStatus == TripRequestStatus.REQUEST_SENT) {
      statusText = 'Procurando por um motorista ${currentCategory} próximo...';
    } else if (tripRequestStatus == TripRequestStatus.TRIP_ACCEPTED &&
        driver != null) {
      statusText =
          '${driver['name']} (${driver['carModel']}, ${driver['plate']}) está a caminho!';
    } else {
      statusText = 'Aguardando atualização de status...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: tripRequestStatus == TripRequestStatus.REQUEST_SENT
              ? const CircularProgressIndicator()
              : const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
        const SizedBox(height: 15),
        Text(
          statusText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Local de recolha: ${currentAddress?.split(',').first ?? 'Localização Atual'}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: onCancelRequest,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text(
              'CANCELAR PEDIDO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTracking =
        tripRequestStatus == TripRequestStatus.REQUEST_SENT ||
        tripRequestStatus == TripRequestStatus.TRIP_ACCEPTED;
    final info = _getCategoryInfo(selectedCategory);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTracking) _buildTripTrackingUI(context),

          if (!isTracking) ...[
            _buildCategorySelector(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirmação de Viagem',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatter.format(info['price']),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            _buildDetailRow(
              Icons.radio_button_checked,
              'Origem:',
              currentAddress?.split(',').first ?? 'Localização Atual',
              Colors.green.shade700,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.flag_circle,
              'Destino:',
              destinationAddress?.split(',').first ?? 'Carregando...',
              Colors.red.shade700,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: onRequestTrip,
                icon: const Icon(Icons.local_taxi),
                label: Text(
                  'SOLICITAR ${selectedCategory.toUpperCase()} - ${formatter.format(info['price'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: <TextSpan>[
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// 4. BOTÕES DE ACESSO RÁPIDO (QuickAccessButtons)
// ======================================================================

class QuickAccessButtons extends StatelessWidget {
  final TripRequestStatus tripRequestStatus;
  final Color primaryColor;

  const QuickAccessButtons({
    super.key,
    required this.tripRequestStatus,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tripRequestStatus != TripRequestStatus.IDLE) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 15,
      bottom: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'favoritesBtn',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir Favoritos (Mock)')),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            mini: true,
            child: const Icon(Icons.favorite_outline),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'paymentBtn',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abrir Opções de Pagamento (Mock)'),
                ),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            mini: true,
            child: const Icon(Icons.credit_card),
          ),
        ],
      ),
    );
  }
}
