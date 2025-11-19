import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobility_app/screens/documents/documentos_screen.dart';
// Importação relativa corrigida:
import 'map_view.dart';

// ======================================================================
// ENUM para o Estado do Pedido de Viagem do Passageiro
enum TripRequestStatus {
  IDLE,
  CHOOSING_DESTINATION,
  PRICE_ESTIMATED,
  REQUEST_SENT,
  TRIP_ACCEPTED,
  TRIP_COMPLETED,
}
// ======================================================================

// 💡 Posição neutra (0, 0) para uso APENAS como fallback técnico
// O mapa só será exibido depois que a localização for tentada, mesmo que falhe.
const LatLng _kNeutralFallbackPosition = LatLng(0, 0);

// Variáveis globais para as instâncias reais dos serviços
late final FirebaseFirestore _firestore;
late final FirebaseAuth _auth;
late final String _appId;

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String userId;

  const HomeScreen({super.key, required this.userRole, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Variáveis para a lógica de mapa
  // 🔑 ALTERAÇÃO CHAVE: _currentPosition é Opcional (Nullable) e começa como null
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady =
      false; // Indica se a tentativa de obter a localização inicial terminou

  // Flag de Prontidão do Firebase
  bool _isFirebaseReady = false;

  // ESTADO ESPECÍFICO DO PASSAGEIRO
  final TextEditingController _searchController = TextEditingController();
  String? _destinationAddress;
  String? _currentAddress;
  TripRequestStatus _tripRequestStatus = TripRequestStatus.IDLE;
  String? _currentRequestId;
  String _selectedCategory = 'Pop';

  // ESTADO A-5: CORRIDA ACEITA
  StreamSubscription<DocumentSnapshot>? _tripStatusSubscription;
  Map<String, dynamic>? _acceptedDriverData;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _singleDriverLocationSubscription;

  // ESTADO ESPECÍFICO DO MOTORISTA
  bool _isDriverOnline = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  StreamSubscription<QuerySnapshot>? _requestsStreamSubscription;
  Map<String, dynamic>? _pendingRequest;

  // Variáveis mock para simulação de dados do pedido
  final double _mockPrice = 35.90;

  @override
  void initState() {
    super.initState();
    // 🐛 CORRIGIDO: _onSearchChanged agora é um método definido.
    _searchController.addListener(_onSearchChanged);
    _setupAppInitialization();
  }

  // --- Funções de inicialização e dispose ---
  Future<void> _setupAppInitialization() async {
    await _initializeFirebase();
    // Espera a localização real
    await _checkLocationPermissionAndGetLocation();

    // Endereço só é definido se a localização não for null
    _currentAddress = _currentPosition != null
        ? 'Localização GPS Obtida'
        : 'Localização Indefinida';

    if (_isFirebaseReady) {
      if (widget.userRole == 'passageiro') {
        _startListeningToDrivers();
      }
    }
  }

  @override
  void dispose() {
    // 🐛 CORRIGIDO: _onSearchChanged agora é um método definido.
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    // 🐛 CORRIGIDO: Função adicionada.
    _stopLocationTracking();
    _stopListeningToDrivers();
    _stopListeningToRequests();
    _stopListeningToTripStatus();
    _stopListeningToDriverLocation();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // 🛠️ LÓGICA DE FIREBASE (Inicialização e Escuta)
  // -----------------------------------------------------------------

  Future<void> _initializeFirebase() async {
    if (_isFirebaseReady) return;

    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        _appId = Firebase.app().options.projectId;
      } else {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        _appId = 'mock-app-id';
      }

      print(
        'DEBUG: Firebase e Firestore acessados com sucesso. App ID: $_appId',
      );

      setState(() {
        _isFirebaseReady = true;
      });
    } on FirebaseException catch (e) {
      print('ERRO: Falha ao acessar o Firebase: $e');
      setState(() {
        _isFirebaseReady = false;
      });
    } catch (e) {
      print('ERRO GENÉRICO na inicialização do Firebase: $e');
      setState(() {
        _isFirebaseReady = false;
      });
    }
  }

  // --- LÓGICA DE ESCUTA (Passageiro) ---

  void _startListeningToDrivers() {
    if (!_isFirebaseReady) return;

    final driversCollection = _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('drivers');

    final q = driversCollection.where('isOnline', isEqualTo: true);

    // Usa _driversStreamSubscription para a coleção (QuerySnapshot)
    _driversStreamSubscription = q.snapshots().listen(
      (snapshot) {
        print(
          'FIRESTORE: Recebendo atualização de ${snapshot.docs.length} motoristas online.',
        );

        final newMarkers = <Marker>{};
        _markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final driverId = data['driverId'] as String;
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;

          if (lat != null && lng != null && driverId != widget.userId) {
            newMarkers.add(
              Marker(
                markerId: MarkerId('driver_$driverId'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: 'Motorista Online: ${driverId.substring(0, 6)}...',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
              ),
            );
          }
        }

        setState(() {
          _markers.addAll(newMarkers);
        });
      },
      onError: (error) {
        print('ERRO no Stream de Motoristas: $error');
      },
    );
  }

  void _stopListeningToDrivers() {
    _driversStreamSubscription?.cancel();
    _driversStreamSubscription = null;
    print('FIRESTORE: Escuta de motoristas interrompida.');
  }

  void _startListeningToDriverLocation(String driverId) {
    if (!_isFirebaseReady) return;

    _stopListeningToDrivers();
    _singleDriverLocationSubscription?.cancel();

    final driverDocRef = _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('drivers')
        .doc(driverId);

    _singleDriverLocationSubscription = driverDocRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          _stopListeningToDriverLocation();
          // 🐛 CORRIGIDO: Função adicionada.
          _onCancelRequest();
          return;
        }

        final data = snapshot.data()!;
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;

        if (lat != null && lng != null) {
          final driverPosition = LatLng(lat, lng);

          setState(() {
            _acceptedDriverData = {
              ...(_acceptedDriverData ?? {}),
              'latitude': lat,
              'longitude': lng,
            };

            _markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));
            _markers.add(
              Marker(
                markerId: MarkerId('driver_$driverId'),
                position: driverPosition,
                infoWindow: InfoWindow(
                  title: _acceptedDriverData!['driverName'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );

            _mapController?.animateCamera(
              CameraUpdate.newLatLng(driverPosition),
            );
          });
        }
      },
      onError: (error) {
        print('ERRO no Stream de Localização do Motorista: $error');
        _stopListeningToDriverLocation();
      },
    );
  }

  void _stopListeningToDriverLocation() {
    _singleDriverLocationSubscription?.cancel();
    _singleDriverLocationSubscription = null;
    print('FIRESTORE: Escuta de localização do motorista aceito interrompida.');

    if (widget.userRole == 'passageiro' &&
        _tripRequestStatus == TripRequestStatus.IDLE) {
      _startListeningToDrivers();
    }
  }

  void _startListeningToTripStatus(String requestId) {
    if (!_isFirebaseReady) return;

    _stopListeningToTripStatus();

    final requestDocRef = _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('requests')
        .doc(requestId);

    _tripStatusSubscription = requestDocRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          _stopListeningToTripStatus();
          return;
        }

        final data = snapshot.data()!;
        final status = data['status'] as String?;

        if (status == 'accepted') {
          print('FIRESTORE: Pedido ACEITO pelo motorista!');

          setState(() {
            _tripRequestStatus = TripRequestStatus.TRIP_ACCEPTED;
            _acceptedDriverData = {
              'driverId': data['driverId'],
              'driverName': data['driverName'],
              'category': data['category'],
              'vehicleModel': 'Fiat Uno', // Mock
              'vehiclePlate': 'ABC-1234', // Mock
            };
          });

          _startListeningToDriverLocation(data['driverId'] as String);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Motorista ${data['driverName']} aceitou a corrida!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else if (status == 'cancelled') {
          // 🐛 CORRIGIDO: Função adicionada.
          _onCancelRequest(); // Trata o cancelamento
        }
      },
      onError: (error) {
        print('ERRO no Stream de Status da Viagem: $error');
      },
    );
  }

  void _stopListeningToTripStatus() {
    _tripStatusSubscription?.cancel();
    _tripStatusSubscription = null;
    _stopListeningToDriverLocation();
  }

  // --- LÓGICA DE ESCUTA (Motorista) ---

  void _startListeningToRequestsForDriver() {
    if (!_isFirebaseReady) return;

    final requestsCollection = _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('requests');

    final q = requestsCollection.where('status', isEqualTo: 'pending');

    _requestsStreamSubscription = q.snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          if (_pendingRequest != null) {
            setState(() {
              _pendingRequest = null;
            });
          }
          return;
        }

        final newRequest = snapshot.docs.first;
        final requestData = newRequest.data();
        final requestId = newRequest.id;

        if (_pendingRequest != null &&
            _pendingRequest!['requestId'] == requestId) {
          return;
        }

        setState(() {
          _pendingRequest = {...requestData, 'requestId': requestId};
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'NOVO PEDIDO! Categoria: ${requestData['category']}, Destino: ${requestData['destinationAddress']}',
              ),
              backgroundColor: Colors.purple,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onError: (error) {
        print('ERRO no Stream de Pedidos: $error');
      },
    );
  }

  void _stopListeningToRequests() {
    _requestsStreamSubscription?.cancel();
    _requestsStreamSubscription = null;
    print('FIRESTORE: Escuta de pedidos interrompida.');
  }

  // -----------------------------------------------------------------
  // ⚙️ LÓGICA DE AÇÕES (Requisição / Aceite)
  // -----------------------------------------------------------------

  Future<void> _acceptRequest(String requestId) async {
    if (!_isFirebaseReady) return;
    // ... (Lógica de aceitar no Firestore)
    try {
      final requestDocRef = _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('public')
          .doc('data')
          .collection('requests')
          .doc(requestId);

      await requestDocRef.update({
        'status': 'accepted',
        'driverId': widget.userId,
        'driverName': 'Motorista Teste (${widget.userId.substring(0, 6)})',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _pendingRequest = null;
      });
      // ... (Mensagem de sucesso)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pedido aceite! Navegando para o ponto de recolha...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao aceitar pedido: $e');
      // ... (Mensagem de erro)
    }
  }

  Future<void> _saveTripRequestToFirestore() async {
    if (!_isFirebaseReady ||
        _destinationAddress == null ||
        _currentAddress == null ||
        _currentPosition == null) {
      // Adicionando checagem de _currentPosition
      return;
    }

    setState(() {
      _tripRequestStatus = TripRequestStatus.REQUEST_SENT;
    });

    try {
      final requestsCollection = _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('public')
          .doc('data')
          .collection('requests');

      final newRequest = {
        'passengerId': widget.userId,
        'passengerName':
            'Passageiro Teste (${widget.userId.length >= 6 ? widget.userId.substring(0, 6) : widget.userId})',
        'originAddress': _currentAddress,
        'originLatitude':
            _currentPosition!.latitude, // Usando ! pois checamos antes
        'originLongitude':
            _currentPosition!.longitude, // Usando ! pois checamos antes
        'destinationAddress': _destinationAddress,
        'estimatedPrice': _mockPrice,
        'category': _selectedCategory,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await requestsCollection.add(newRequest);

      setState(() {
        _currentRequestId = docRef.id;
      });

      _startListeningToTripStatus(docRef.id);
      // ... (Mensagem de sucesso)
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao salvar pedido: $e');
      setState(() {
        _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;
      });
      // ... (Mensagem de erro)
    }
  }

  // -----------------------------------------------------------------
  // 🗺️ LÓGICA DE RASTREAMENTO E MAPA
  // -----------------------------------------------------------------

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('GEOLOCATOR: Rastreamento de localização interrompido.');
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    if (!_isFirebaseReady || !_isDriverOnline) return;

    try {
      await _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('public')
          .doc('data')
          .collection('drivers')
          .doc(widget.userId)
          .set({
            'driverId': widget.userId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'isOnline': true,
          }, SetOptions(merge: true));
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao atualizar localização do motorista: $e');
    }
  }

  Future<void> _startLocationTrackingForDriver() async {
    if (!_isFirebaseReady) return;

    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final newPosition = LatLng(position.latitude, position.longitude);

            setState(() {
              _currentPosition = newPosition;

              if (_mapController != null && _selectedIndex == 0) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: newPosition, zoom: 16.0),
                  ),
                );
              }

              _markers.removeWhere(
                (m) => m.markerId.value == 'currentLocation',
              );
              _markers.add(
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: newPosition,
                  infoWindow: const InfoWindow(title: 'Você está ONLINE'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              );
            });

            // 🐛 CORRIGIDO: Função adicionada e chamada.
            _updateDriverLocationInFirestore(position);
          },
          onError: (e) {
            print('ERRO no Stream de Localização: $e');
            // 🐛 CORRIGIDO: Função adicionada e chamada.
            _stopLocationTracking();
          },
          cancelOnError: true,
        );
  }

  /// 🚀 FUNÇÃO QUE OBTÉM A LOCALIZAÇÃO ATUAL DO USUÁRIO.
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS desligado
      setState(() => _isMapReady = true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permissão negada
        setState(() => _isMapReady = true);
        return;
      }
    }

    try {
      // 📌 CHAVE: Obtendo a posição atual do usuário
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition; // <-- POSIÇÃO REAL CAPTURADA
        _isMapReady = true;

        // Adiciona o marcador do usuário real (azul)
        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: newPosition,
            infoWindow: const InfoWindow(title: 'Sua Localização Atual'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      });

      // Centraliza o mapa se ele já estiver pronto
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      print('ERRO GERAL na localização inicial: $e');
      // Falha na captura, _currentPosition permanece null.
      setState(() => _isMapReady = true);
    }
  }

  /// Garante que o mapa centralize na localização atual (_currentPosition)
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Usa a posição real se existir, caso contrário, usa a coordenada neutra (0, 0)
    final target = _currentPosition ?? _kNeutralFallbackPosition;

    if (_isMapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.0),
        ),
      );
    }
  }

  // -----------------------------------------------------------------
  // 💾 LÓGICA DE UI E ESTADO (Ações do Passageiro/Motorista)
  // -----------------------------------------------------------------

  // 🐛 CORRIGIDO: Função _onSearchChanged adicionada.
  void _onSearchChanged() {
    // Implemente a lógica de sugestão de endereço aqui (ex: chamada a API de geocoding)
    // Por enquanto, apenas um placeholder para alterar o estado.
    if (_tripRequestStatus == TripRequestStatus.PRICE_ESTIMATED &&
        _searchController.text.isEmpty) {
      _onCancelRequest();
    } else if (_tripRequestStatus == TripRequestStatus.IDLE &&
        _searchController.text.isNotEmpty) {
      setState(() {
        _tripRequestStatus = TripRequestStatus.CHOOSING_DESTINATION;
      });
    }
  }

  // 🐛 CORRIGIDO: Função _onCancelRequest (limpar estado de requisição) adicionada.
  void _onCancelRequest() {
    _stopListeningToTripStatus();
    _stopListeningToDriverLocation();

    setState(() {
      _tripRequestStatus = TripRequestStatus.IDLE;
      _destinationAddress = null;
      _currentRequestId = null;
      _acceptedDriverData = null;
      _searchController.clear();
      // Limpa marcadores de destino e motorista aceito, mantendo o da localização atual
      _markers.removeWhere(
        (m) =>
            m.markerId.value == 'destinationLocation' ||
            m.markerId.value.startsWith('driver_'),
      );

      // Reinicia a escuta de todos os drivers se for passageiro e estiver no mapa
      if (widget.userRole == 'passageiro' && _selectedIndex == 0) {
        _startListeningToDrivers();
      }
    });

    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15.0),
        ),
      );
    }
  }

  // 🐛 CORRIGIDO: Função _onCategorySelected adicionada.
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSelectDestination(String address) {
    if (_currentPosition == null)
      return; // Não faz nada se não tiver localização

    setState(() {
      _destinationAddress = address;
      _searchController.text = address.split(',').first;
      _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;

      // Lógica de Marcadores/Câmera
      _markers.removeWhere((m) => m.markerId.value == 'destinationLocation');
      final mockDestination = LatLng(
        _currentPosition!.latitude + 0.01,
        _currentPosition!.longitude + 0.01,
      );
      _markers.add(
        // ... (Adição do marcador de destino)
        Marker(
          markerId: const MarkerId('destinationLocation'),
          position: mockDestination,
          infoWindow: InfoWindow(title: 'Destino: $address'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
      // ... (Ajuste da câmera)
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentPosition!.latitude < mockDestination.latitude
                  ? _currentPosition!.latitude
                  : mockDestination.latitude,
              _currentPosition!.longitude < mockDestination.longitude
                  ? _currentPosition!.longitude
                  : mockDestination.longitude,
            ),
            northeast: LatLng(
              _currentPosition!.latitude > mockDestination.latitude
                  ? _currentPosition!.latitude
                  : mockDestination.latitude,
              _currentPosition!.longitude > mockDestination.longitude
                  ? _currentPosition!.longitude
                  : mockDestination.longitude,
            ),
          ),
          100.0,
        ),
      );
    });
  }

  // 🐛 CORRIGIDO: Função _onToggleDriverStatus (lógica ON/OFF) adicionada.
  Future<void> _onToggleDriverStatus(bool isOnline) async {
    if (!_isFirebaseReady) return;

    setState(() {
      _isDriverOnline = isOnline;
    });

    if (isOnline) {
      await _startLocationTrackingForDriver();
      _startListeningToRequestsForDriver();
    } else {
      _stopLocationTracking();
      _stopListeningToRequests();
      _pendingRequest = null;
      // Remove o marcador do motorista.
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _currentPosition =
            null; // Zera a posição no mapa para forçar loading/recentralização
      });
      // Notifica o Firestore que está offline
      try {
        await _firestore
            .collection('artifacts')
            .doc(_appId)
            .collection('public')
            .doc('data')
            .collection('drivers')
            .doc(widget.userId)
            .update({'isOnline': false});
      } catch (e) {
        print('ERRO ao desativar motorista no Firestore: $e');
      }
    }
  }

  // 🐛 CORRIGIDO: Função _onItemTapped adicionada.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Lógica de inicialização do Motorista (volta para o mapa)
    if (index == 0 && widget.userRole == 'motorista' && _isDriverOnline) {
      // Garante que o rastreamento reinicie
      _startLocationTrackingForDriver();
      _startListeningToRequestsForDriver();
    } else if (index != 0 &&
        widget.userRole == 'motorista' &&
        _isDriverOnline) {
      // Para o rastreamento e escuta quando sai da tela do mapa
      _stopLocationTracking();
      _stopListeningToRequests();
    }
    // Lógica de inicialização do Passageiro (volta para o mapa)
    if (index == 0 && widget.userRole == 'passageiro') {
      _startListeningToDrivers();
      _checkLocationPermissionAndGetLocation();
    } else if (index != 0 && widget.userRole == 'passageiro') {
      _stopListeningToDrivers();
    }
  }

  // --- Função auxiliar para o widget da seção de Perfil ---
  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            Text(
              'Usuário: ${widget.userId.length >= 8 ? widget.userId.substring(0, 8) : widget.userId}...',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              'Função: ${widget.userRole.toUpperCase()}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.primaryColor,
              ),
            ),
            // ... (restante do perfil)
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DocumentosScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text(
                'Ver Meus Documentos',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // 🔨 BUILD METHOD PRINCIPAL
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Checagem de prontidão do Firebase
    if (!_isFirebaseReady && !widget.userRole.contains('loading')) {
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

    // 🔑 CHECAGEM PRINCIPAL: Se estiver no mapa e a posição real ainda não foi obtida, mostra o Loading.
    if (_selectedIndex == 0 && _currentPosition == null && !_isMapReady) {
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
      // NOVIDADE: Verifica se temos uma localização real (não nula)
      final bool hasRealLocation = _currentPosition != null;
      // Usa a posição real se existir, caso contrário, usa a coordenada neutra (0, 0)
      final positionToUse = _currentPosition ?? _kNeutralFallbackPosition;

      switch (_selectedIndex) {
        case 0:
          appBarTitle = isPassenger ? 'Pedir Viagem' : 'Modo Motorista';
          content = MapSection(
            isPassenger: isPassenger,
            isMapReady: _isMapReady,
            currentPosition: positionToUse, // Posição Real ou (0, 0)
            hasRealLocation: hasRealLocation, // <--- NOVO PARÂMETRO
            markers: _markers,
            primaryColor: primaryColor,
            onMapCreated: _onMapCreated,
            tripRequestStatus: _tripRequestStatus,
            // Props Passageiro
            searchController: _searchController,
            onSelectDestination: _onSelectDestination,
            // 🐛 CORRIGIDO: Função adicionada e passada como referência.
            onClearSearch: _onCancelRequest,
            currentAddress: _currentAddress,
            destinationAddress: _destinationAddress,
            mockPrice: _mockPrice,
            onRequestTrip: _saveTripRequestToFirestore,
            // 🐛 CORRIGIDO: Função adicionada e passada como referência.
            onCancelRequest: _onCancelRequest,
            selectedCategory: _selectedCategory,
            // 🐛 CORRIGIDO: Função adicionada e passada como referência.
            onCategorySelected: _onCategorySelected,
            acceptedDriverData: _acceptedDriverData,
            // Props Motorista
            isDriverOnline: _isDriverOnline,
            // 🐛 CORRIGIDO: Função adicionada e passada como referência.
            onToggleDriverStatus: _onToggleDriverStatus,
            pendingRequest: _pendingRequest,
            // 🐛 CORRIGIDO: Função adicionada e passada como referência.
            onAcceptRequest: _acceptRequest,
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
          content = _buildProfileSection(context);
          break;
        default:
          content = const Center(child: Text('Tela Desconhecida'));
          appBarTitle = 'Erro';
      }
    }

    final isMapTab = _selectedIndex == 0;

    return Scaffold(
      // A AppBar só é exibida se não for a aba do mapa, ou se for a aba do mapa, mas a localização está carregando
      appBar: isMapTab && _currentPosition == null
          ? AppBar(
              title: Text(appBarTitle),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            )
          : isMapTab
          ? null // Deixa o MapSection gerenciar a UI do mapa
          : AppBar(
              title: Text(
                appBarTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),

      body: content,

      // BottomNavigationBar
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
