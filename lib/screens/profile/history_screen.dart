import 'package:flutter/material.dart';

// Modelo Simulado para uma Viagem
class Trip {
  final String id;
  final DateTime date;
  final String startLocation;
  final String endLocation;
  final double amount;
  final String status; // Ex: 'Concluída', 'Cancelada', 'Em Análise'

  // 💡 Construtor NÃO é const
  Trip({
    required this.id,
    required this.date,
    required this.startLocation,
    required this.endLocation,
    required this.amount,
    required this.status,
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // 💡 CORREÇÃO FINAL: Usamos 'static final' (inicializado uma vez),
  // eliminando a necessidade de 'const' no DateTime.
  static final List<Trip> _mockTrips = [
    // Novembro
    Trip(
      id: 'T001',
      date: DateTime.utc(2025, 11, 19, 10, 30),
      startLocation: 'Rua das Flores, 100',
      endLocation: 'Aeroporto Internacional',
      amount: 45.50,
      status: 'Concluída',
    ),
    Trip(
      id: 'T002',
      date: DateTime.utc(2025, 11, 18, 18, 45),
      startLocation: 'Shopping Central',
      endLocation: 'Av. Paulista, 2000',
      amount: 22.80,
      status: 'Concluída',
    ),
    // Outubro
    Trip(
      id: 'T003',
      date: DateTime.utc(2025, 10, 25, 9, 0),
      startLocation: 'Bairro Novo',
      endLocation: 'Estação de Trem',
      amount: 15.00,
      status: 'Concluída',
    ),
    Trip(
      id: 'T004',
      date: DateTime.utc(2025, 10, 20, 14, 20),
      startLocation: 'Casa',
      endLocation: 'Parque Ibirapuera',
      amount: 38.90,
      status: 'Concluída',
    ),
    Trip(
      id: 'T005',
      date: DateTime.utc(2025, 10, 1, 7, 0),
      startLocation: 'Rodoviária',
      endLocation: 'Hotel Atlântico',
      amount: 5.00,
      status: 'Cancelada',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Acessamos a lista estática
    final Map<String, List<Trip>> groupedTrips = _groupTripsByMonth(_mockTrips);

    return Scaffold(
      // ... (o restante do código permanece o mesmo, usando _mockTrips)
      appBar: AppBar(
        title: const Text(
          'Histórico de Viagens',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: groupedTrips.isEmpty
          ? Center(
              child: Text(
                'Você ainda não realizou nenhuma viagem.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: groupedTrips.keys.length,
              itemBuilder: (context, index) {
                final monthYear = groupedTrips.keys.elementAt(index);
                final trips = groupedTrips[monthYear]!;

                return _buildMonthSection(
                  context,
                  monthYear,
                  trips,
                  primaryColor,
                );
              },
            ),
    );
  }

  // --- Funções Auxiliares (Permanecem as mesmas) ---

  Map<String, List<Trip>> _groupTripsByMonth(List<Trip> trips) {
    trips.sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<Trip>> grouped = {};

    for (var trip in trips) {
      final key = '${_getMonthName(trip.date.month)} ${trip.date.year}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(trip);
    }
    return grouped;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Janeiro';
      case 2:
        return 'Fevereiro';
      case 3:
        return 'Março';
      case 4:
        return 'Abril';
      case 5:
        return 'Maio';
      case 6:
        return 'Junho';
      case 7:
        return 'Julho';
      case 8:
        return 'Agosto';
      case 9:
        return 'Setembro';
      case 10:
        return 'Outubro';
      case 11:
        return 'Novembro';
      case 12:
        return 'Dezembro';
      default:
        return '';
    }
  }

  Widget _buildMonthSection(
    BuildContext context,
    String monthYear,
    List<Trip> trips,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 20.0,
            bottom: 8.0,
            right: 16.0,
          ),
          child: Text(
            monthYear,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...trips
            .map((trip) => _buildTripTile(context, trip, primaryColor))
            .toList(),
      ],
    );
  }

  Widget _buildTripTile(BuildContext context, Trip trip, Color primaryColor) {
    Color statusColor = trip.status == 'Concluída' ? Colors.green : Colors.red;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: Icon(
            Icons.location_on_outlined,
            color: primaryColor,
            size: 30,
          ),
          title: Text(
            '${trip.startLocation} para ${trip.endLocation}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${trip.date.day}/${trip.date.month}/${trip.date.year} às ${trip.date.hour.toString().padLeft(2, '0')}:${trip.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                trip.status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Text(
            'R\$ ${trip.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: trip.status == 'Concluída' ? Colors.black : Colors.grey,
            ),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Detalhes da Viagem ${trip.id}')),
            );
          },
        ),
        Divider(
          height: 0,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}
