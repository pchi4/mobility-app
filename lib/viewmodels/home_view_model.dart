import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

enum TripRequestStatus {
  IDLE,
  CHOOSING_DESTINATION,
  PRICE_ESTIMATED,
  REQUEST_SENT,
  TRIP_ACCEPTED,
  TRIP_COMPLETED,
}

// Posição de fallback para inicialização, mas usaremos o Geolocator
const LatLng _kNeutralFallbackPosition = LatLng(0, 0);

class HomeViewModel extends ChangeNotifier {
  // Variáveis de inicialização
  GoogleMapController? _mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================================================================
  // 1. ESTADO INTERNO
  // ======================================================================
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _isFirebaseReady = false;

  // Simulação do ID do usuário (Na vida real, viria da autenticação)
  final String _mockUserId = 'PASSENGER_123';

  // Estado Passageiro
  TripRequestStatus _tripRequestStatus = TripRequestStatus.IDLE;
  String? _currentAddress;
  String? _destinationAddress;
  String _selectedCategory = 'Pop';
  final double _mockPrice = 35.90;
  Map<String, dynamic>? _acceptedDriverData;
  final TextEditingController _searchController = TextEditingController();
  String? _currentTripRequestId; // ID da requisição de viagem atual

  // Estado Motorista
  bool _isDriverOnline = false;
  Map<String, dynamic>? _pendingRequest;

  // Subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  StreamSubscription<QuerySnapshot>? _requestsStreamSubscription;
  StreamSubscription<DocumentSnapshot>? _tripStatusSubscription;

  // ======================================================================
  // 2. GETTERS PÚBLICOS
  // ======================================================================
  bool get isFirebaseReady => _isFirebaseReady;
  bool get isMapReady => _isMapReady;
  LatLng? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  TripRequestStatus get tripRequestStatus => _tripRequestStatus;
  bool get isDriverOnline => _isDriverOnline;
  String? get currentAddress => _currentAddress;
  String? get destinationAddress => _destinationAddress;
  double get mockPrice => _mockPrice;
  String get selectedCategory => _selectedCategory;
  Map<String, dynamic>? get acceptedDriverData => _acceptedDriverData;
  Map<String, dynamic>? get pendingRequest => _pendingRequest;
  TextEditingController get searchController => _searchController;
  String? get currentTripRequestId => _currentTripRequestId;

  // ======================================================================
  // 3. MÉTODOS DE AÇÃO (Inicialização e Localização REAL)
  // ======================================================================

  void setupAppInitialization(String userRole, String userId) {
    _isFirebaseReady = true;
    notifyListeners();
    _checkLocationPermissionAndGetLocation();
  }

  /// Verifica permissões, inicia o stream de posição e obtém a primeira posição.
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Serviços de localização desativados.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Permissão de localização negada.');
        return;
      }
    }

    try {
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            _updateCurrentPosition,
            onError: (e) {
              print('Erro no stream de localização: $e');
            },
          );

      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateCurrentPosition(initialPosition);
    } catch (e) {
      print('Erro ao inicializar a localização: $e');
    }
  }

  /// Centraliza a atualização do estado de localização
  void _updateCurrentPosition(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);
    _currentPosition = newPosition;
    _isMapReady = true;

    // ⚠️ Se quiser o endereço real, chame o Geocoding Reverso aqui
    _currentAddress = 'Localização Real do Dispositivo';

    notifyListeners();

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPosition, zoom: 15.0),
        ),
      );
    }
  }

  void setMapControllerReady(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15.0),
        ),
      );
    }
  }

  // ======================================================================
  // 4. AÇÕES DO PASSAGEIRO (Firestore)
  // ======================================================================

  void startSearch() {
    if (_tripRequestStatus == TripRequestStatus.IDLE) {
      _tripRequestStatus = TripRequestStatus.CHOOSING_DESTINATION;
      notifyListeners();
    }
  }

  void selectDestination(String address) {
    _searchController.text = address;
    _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;
    _destinationAddress = address;
    notifyListeners();
  }

  void onCategorySelected(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// 💡 IMPLEMENTAÇÃO REAL: Salva a requisição no Firestore e começa a escutar mudanças.
  Future<void> saveTripRequestToFirestore() async {
    if (_currentPosition == null || destinationAddress == null) {
      print('Erro: Posição ou Destino não definidos.');
      return;
    }

    try {
      final docRef = await _firestore.collection('trip_requests').add({
        'passengerId': _mockUserId,
        'origin': {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
          'address': currentAddress ?? 'Local de Recolha',
        },
        'destination': {'address': destinationAddress},
        'category': _selectedCategory,
        'status': 'PENDING',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _currentTripRequestId = docRef.id;
      _tripRequestStatus = TripRequestStatus.REQUEST_SENT;
      notifyListeners();

      // Começa a monitorar este documento específico
      _monitorTripStatus(docRef.id);

      print('Requisição de viagem salva: ${docRef.id}');
    } catch (e) {
      print('Erro ao salvar requisição no Firestore: $e');
      _currentTripRequestId = null;
      _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;
      notifyListeners();
    }
  }

  /// Monitora o status da requisição do passageiro.
  void _monitorTripStatus(String tripRequestId) {
    _tripStatusSubscription?.cancel();

    _tripStatusSubscription = _firestore
        .collection('trip_requests')
        .doc(tripRequestId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              print(
                'Requisição de viagem cancelada ou deletada (pelo motorista ou por erro).',
              );
              clearSearch();
              return;
            }

            final data = snapshot.data();
            final status = data?['status'] as String?;
            final driverData = data?['driverData'] as Map<String, dynamic>?;

            if (status == 'ACCEPTED' &&
                _tripRequestStatus != TripRequestStatus.TRIP_ACCEPTED) {
              _tripRequestStatus = TripRequestStatus.TRIP_ACCEPTED;
              _acceptedDriverData = driverData;
              notifyListeners();
              print(
                'Viagem aceita pelo motorista! Motorista: ${driverData?['name']}',
              );
            }
          },
          onError: (e) {
            print('Erro ao monitorar o status da viagem: $e');
          },
        );
  }

  void clearSearch() {
    // Cancela a escuta de status da viagem
    _tripStatusSubscription?.cancel();
    _currentTripRequestId = null;
    _acceptedDriverData = null;

    _tripRequestStatus = TripRequestStatus.IDLE;
    _destinationAddress = null;
    _searchController.clear();
    _markers.clear();
    notifyListeners();
  }

  void onCancelRequest() {
    // Tenta deletar a requisição no Firestore (opcional, dependendo da regra de segurança)
    if (_currentTripRequestId != null) {
      _firestore
          .collection('trip_requests')
          .doc(_currentTripRequestId)
          .delete()
          .catchError((e) {
            print('Erro ao deletar requisição no Firestore: $e');
          });
    }
    clearSearch();
  }

  // ======================================================================
  // 5. AÇÕES DO MOTORISTA (Firestore)
  // ======================================================================

  Future<void> onToggleDriverStatus(bool isOnline) async {
    _isDriverOnline = isOnline;
    notifyListeners();

    if (isOnline) {
      startMonitoringPendingRequests();
    } else {
      _requestsStreamSubscription?.cancel();
      _pendingRequest = null;
      notifyListeners();
    }
  }

  /// Inicia a escuta de requisições com status 'PENDING' próximas.
  void startMonitoringPendingRequests() {
    _requestsStreamSubscription?.cancel();

    _requestsStreamSubscription = _firestore
        .collection('trip_requests')
        .where('status', isEqualTo: 'PENDING')
        .limit(1) // Pega apenas uma para simplificar
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final requestDoc = snapshot.docs.first;
              _pendingRequest = requestDoc.data();
              _pendingRequest!['id'] = requestDoc.id;
              print('Nova requisição pendente: ${_pendingRequest!['id']}');
            } else {
              _pendingRequest = null;
              print('Nenhuma requisição pendente.');
            }
            notifyListeners();
          },
          onError: (e) {
            print('Erro no monitoramento de requisições: $e');
          },
        );
  }

  void handleTabChange(int index, String userRole) {
    // Você pode usar isso para realizar ações quando o usuário troca de aba
    // Por exemplo, iniciar/parar a escuta de requisições se for motorista.
    print('ViewModel: Troca de aba para índice $index no papel de $userRole');

    // Exemplo de como usar o userRole e o índice para definir o estado de isPassenger:
    // if (userRole == 'passenger' && index == 0) {
    //   _isPassenger = true;
    // } else if (userRole == 'driver' && index == 1) {
    //   _isPassenger = false;
    // }
  }

  /// Ação do motorista para aceitar a requisição.
  Future<void> acceptRequest(String requestId) async {
    try {
      await _firestore.collection('trip_requests').doc(requestId).update({
        'status': 'ACCEPTED',
        'driverId': 'DRIVER_789',
        'driverData': {
          'name': 'João Motorista',
          'carModel': 'Renault Kwid',
          'plate': 'ABC-1234',
        },
      });

      _pendingRequest = null;
      notifyListeners();
      print('Requisição $requestId aceita com sucesso!');
    } catch (e) {
      print('Erro ao aceitar requisição: $e');
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _requestsStreamSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  return HomeViewModel();
});
