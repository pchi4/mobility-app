import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

typedef RequestTripCallback = Future<void> Function();
typedef SelectDestinationCallback = void Function(String address);
typedef CancelRequestCallback = void Function();
typedef SelectCategoryCallback = void Function(String category);

class PassengerSearchUI extends StatelessWidget {
  final TextEditingController searchController;
  final Color primaryColor;
  final TripRequestStatus tripRequestStatus;
  final SelectDestinationCallback onSelectDestination;
  final VoidCallback onClearSearch;
  final String? currentAddressFirstPart;

  const PassengerSearchUI({
    super.key,
    required this.searchController,
    required this.primaryColor,
    required this.tripRequestStatus,
    required this.onSelectDestination,
    required this.onClearSearch,
    this.currentAddressFirstPart,
  });

  @override
  Widget build(BuildContext buildContext) {
    final isSearchFocused =
        tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION;
    final isRequestFlowActive =
        tripRequestStatus != TripRequestStatus.IDLE &&
        tripRequestStatus != TripRequestStatus.REQUEST_SENT;

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
            readOnly: tripRequestStatus == TripRequestStatus.REQUEST_SENT,
            decoration: InputDecoration(
              hintText:
                  'Para onde vamos, ${currentAddressFirstPart ?? 'Passageiro'}?',
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: isRequestFlowActive
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
  final Map<String, dynamic>? acceptedDriverData; // <--- ADICIONE ESTA LINHA

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

  // passenger_ui_widgets.dart

  // ... (Importações e outros métodos inalterados)

  // NOVO WIDGET PARA RENDERIZAR UM ÚNICO CARTÃO DE CATEGORIA
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
        width: 260, // 🔥 Tamanho fixo para funcionar no scroll horizontal
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
            // Ícone
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

            // Nome e ETA (sem Expanded — agora usando Flexible loose)
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

            // Preço (fixo para não causar flex)
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

  // ... (Resto da classe PassengerPriceEstimateCard inalterado)

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 15),
        Text(
          'Procurando por um motorista ${currentCategory} próximo...',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Local de recolha: ${currentAddress?.split(',').first}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        // Mensagens de Segurança e Contato
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulando Ligação...')),
                );
              },
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Contatar Suporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 5),
                Text(
                  'Viagem segura',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
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
    final isRequestSent = tripRequestStatus == TripRequestStatus.REQUEST_SENT;
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
          // Exibe a tela de Acompanhamento ou o Seletor/Confirmação
          if (isRequestSent) _buildTripTrackingUI(context),

          if (!isRequestSent) ...[
            // 1. Seleção de Categoria (AGORA VISUAL!)
            _buildCategorySelector(),

            // 2. Título e Preço (Mantido, mas usando o preço da categoria selecionada)
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
                  formatter.format(info['price']), // Preço da categoria
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // 3. Detalhes de Origem/Destino (Mantido)
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

            // 4. Botão Solicitar Agora
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
      bottom: 20,
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
