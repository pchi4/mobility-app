import 'package:flutter/material.dart';

// Typedefs (Definidos no map_view, mas repetidos para clareza no widget)
typedef ToggleStatusCallback = void Function(bool isOnline);
typedef AcceptRequestCallback = void Function(String requestId);

// ======================================================================
// 1. WIDGET DE TOGGLE DE STATUS (DriverStatusToggle)
// ======================================================================

class DriverStatusToggle extends StatelessWidget {
  final bool isDriverOnline;
  final ToggleStatusCallback onToggleDriverStatus;
  final Color primaryColor;

  const DriverStatusToggle({
    super.key,
    required this.isDriverOnline,
    required this.onToggleDriverStatus,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDriverOnline ? Icons.online_prediction : Icons.offline_bolt,
            color: isDriverOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isDriverOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDriverOnline
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isDriverOnline,
            onChanged: onToggleDriverStatus,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// 2. CARD DE REQUISIÇÃO PENDENTE (DriverPendingRequestCard)
// ======================================================================

class DriverPendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> pendingRequest;
  final AcceptRequestCallback onAcceptRequest;
  final Color primaryColor;

  const DriverPendingRequestCard({
    super.key,
    required this.pendingRequest,
    required this.onAcceptRequest,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final passengerName =
        pendingRequest['passengerName'] ?? 'Passageiro Desconhecido';
    final destination =
        pendingRequest['destinationAddress']?.split(',').first ??
        'Destino Não Informado';
    final category = pendingRequest['category'] ?? 'Padrão';
    final price =
        pendingRequest['estimatedPrice']?.toStringAsFixed(2) ?? '0.00';
    final requestId = pendingRequest['requestId'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nova Solicitação de Viagem!',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 15, thickness: 1),

          _buildDetailRow(
            Icons.person_outline,
            'Passageiro',
            passengerName,
            Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.flag_circle,
            'Destino',
            destination,
            Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.category,
            'Categoria',
            category,
            Colors.black87,
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ganho Estimado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'R\$ $price',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () => onAcceptRequest(requestId),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'ACEITAR CORRIDA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
