import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NECESSÁRIO

// ======================================================================
// ENUM para o Estado do Pedido de Viagem do Passageiro
enum TripRequestStatus {
  IDLE,
  CHOOSING_DESTINATION,
  PRICE_ESTIMATED,
  REQUEST_SENT,
}
// ======================================================================

// Posição padrão para iniciar o mapa (São Paulo)
const LatLng _kInitialPosition = LatLng(-23.55052, -46.633308);

// Variáveis para as instâncias reais dos serviços
late final FirebaseFirestore _firestore;
late final FirebaseAuth _auth;
late final String _appId; // O ProjectId do Firebase

class HomeScreen extends StatefulWidget {
  final String userRole;
  final String userId; // O UID real do Firebase Auth

  const HomeScreen({super.key, required this.userRole, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Variáveis para a lógica de mapa
  GoogleMapController? _mapController;
  LatLng _currentPosition = _kInitialPosition;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;

  // NOVO: Flag de Prontidão do Firebase
  bool _isFirebaseReady = false;

  // ESTADO ESPECÍFICO DO PASSAGEIRO
  final TextEditingController _searchController = TextEditingController();
  String? _destinationAddress;
  String? _currentAddress; // Simula a localização de origem (para o pedido)
  TripRequestStatus _tripRequestStatus = TripRequestStatus.IDLE;
  String? _currentRequestId; // ID do pedido em curso

  // ESTADO ESPECÍFICO DO MOTORISTA
  bool _isDriverOnline = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>?
      _driversStreamSubscription; // Escuta de motoristas para passageiro
  StreamSubscription<QuerySnapshot>?
      _requestsStreamSubscription; // Escuta de pedidos para motorista
  Map<String, dynamic>? _pendingRequest; // Pedido pendente para aceitação

  // Variáveis mock para simulação de dados do pedido
  final double _mockPrice = 35.90;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // 1. Inicia o Setup Assíncrono (Firebase e Localização)
    _setupAppInitialization();

    _addInitialMarker();
  }

  // NOVO: Função para centralizar a inicialização assíncrona
  Future<void> _setupAppInitialization() async {
    // Tenta inicializar o Firebase (apenas acessa as instâncias)
    await _initializeFirebase();

    // Tenta obter a localização inicial
    await _checkLocationPermissionAndGetLocation();

    // Define um endereço de origem mock após obter a localização
    _currentAddress =
        'Rua Fictícia, ${(_currentPosition.latitude * -100).toInt()}, São Paulo';

    // Se o Firebase estiver pronto, inicia as escutas
    if (_isFirebaseReady) {
      if (widget.userRole == 'passageiro') {
        _startListeningToDrivers();
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    _stopLocationTracking();
    _stopListeningToDrivers();
    _stopListeningToRequests();
    super.dispose();
  }

  // --- LÓGICA DE FIREBASE ---

  Future<void> _initializeFirebase() async {
    if (_isFirebaseReady) return; // Evita dupla inicialização

    try {
      // O Firebase já foi inicializado no main(). Apenas acesse os serviços:
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;

      // Obtém o ProjectId real do aplicativo Firebase, que substitui o __app_id
      _appId = Firebase.app().options.projectId;

      print(
          'DEBUG: Firebase e Firestore acessados com sucesso. App ID: $_appId');

      setState(() {
        _isFirebaseReady = true; // Marca como pronto
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

  // --- LÓGICA DE PASSAGEIRO: ESCUTAR MOTORISTAS ---

  void _startListeningToDrivers() {
    if (!_isFirebaseReady) return; // Proteção

    final driversCollection = _firestore
        .collection('artifacts')
        .doc(_appId) // USANDO O NOVO _appId
        .collection('public')
        .doc('data')
        .collection('drivers');

    final q = driversCollection.where('isOnline', isEqualTo: true);

    _driversStreamSubscription = q.snapshots().listen((snapshot) {
      print(
          'FIRESTORE: Recebendo atualização de ${snapshot.docs.length} motoristas online.');

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
                  title: 'Motorista Online: ${driverId.substring(0, 6)}...'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
            ),
          );
        }
      }

      setState(() {
        _markers.addAll(newMarkers);
      });
    }, onError: (error) {
      print('ERRO no Stream de Motoristas: $error');
    });
  }

  void _stopListeningToDrivers() {
    _driversStreamSubscription?.cancel();
    _driversStreamSubscription = null;
    print('FIRESTORE: Escuta de motoristas interrompida.');
  }

  // --- LÓGICA DE MOTORISTA: ESCUTAR PEDIDOS ---

  void _startListeningToRequestsForDriver() {
    if (!_isFirebaseReady) return; // Proteção

    final requestsCollection = _firestore
        .collection('artifacts')
        .doc(_appId) // USANDO O NOVO _appId
        .collection('public')
        .doc('data')
        .collection('requests');

    // Query: busca pedidos que estão PENDENTES ('pending') e que não foram aceites
    final q = requestsCollection.where('status', isEqualTo: 'pending');

    _requestsStreamSubscription = q.snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Se a lista de pedidos pendentes estiver vazia, limpa o estado
        if (_pendingRequest != null) {
          setState(() {
            _pendingRequest = null;
          });
        }
        return;
      }

      // Processa a lista de pedidos. Vamos considerar apenas o primeiro para simplificar
      final newRequest = snapshot.docs.first;
      final requestData = newRequest.data();
      final requestId = newRequest.id;

      // Se o motorista já estiver a visualizar um pedido, não faz nada
      if (_pendingRequest != null &&
          _pendingRequest!['requestId'] == requestId) {
        return;
      }

      // Define o pedido pendente e notifica o motorista
      setState(() {
        _pendingRequest = {...requestData, 'requestId': requestId};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'NOVO PEDIDO! Destino: ${requestData['destinationAddress']}'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 5),
        ),
      );
    }, onError: (error) {
      print('ERRO no Stream de Pedidos: $error');
    });
  }

  void _stopListeningToRequests() {
    _requestsStreamSubscription?.cancel();
    _requestsStreamSubscription = null;
    print('FIRESTORE: Escuta de pedidos interrompida.');
  }

  // --- LÓGICA DE MOTORISTA: ACEITAR PEDIDO ---

  Future<void> _acceptRequest(String requestId) async {
    if (!_isFirebaseReady) return; // Proteção

    try {
      final requestDocRef = _firestore
          .collection('artifacts')
          .doc(_appId) // USANDO O NOVO _appId
          .collection('public')
          .doc('data')
          .collection('requests')
          .doc(requestId);

      // 1. Atualiza o estado do pedido para 'accepted' e atribui ao motorista
      await requestDocRef.update({
        'status': 'accepted',
        'driverId': widget.userId,
        'driverName': 'Motorista Teste (${widget.userId.substring(0, 6)})',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // 2. Limpa o estado local do motorista e notifica
      setState(() {
        _pendingRequest = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido aceite! Navegando para o ponto de recolha...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao aceitar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao aceitar pedido. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- LÓGICA DE PASSAGEIRO: SALVAR PEDIDO ---

  Future<void> _saveTripRequestToFirestore() async {
    if (!_isFirebaseReady) return; // Proteção

    if (_destinationAddress == null || _currentAddress == null) {
      return;
    }

    setState(() {
      _tripRequestStatus = TripRequestStatus.REQUEST_SENT;
    });

    try {
      final requestsCollection = _firestore
          .collection('artifacts')
          .doc(_appId) // USANDO O NOVO _appId
          .collection('public')
          .doc('data')
          .collection('requests');

      // 1. Cria o objeto do pedido
      final newRequest = {
        'passengerId': widget.userId,
        'passengerName': 'Passageiro Teste (${widget.userId.substring(0, 6)})',
        'originAddress': _currentAddress,
        'originLatitude': _currentPosition.latitude,
        'originLongitude': _currentPosition.longitude,
        'destinationAddress': _destinationAddress,
        'estimatedPrice': _mockPrice,
        'status': 'pending', // Status inicial
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2. Adiciona o documento e obtém a referência (e ID)
      final docRef = await requestsCollection.add(newRequest);

      setState(() {
        _currentRequestId = docRef.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem solicitada! Aguardando motorista...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao salvar pedido: $e');
      setState(() {
        _tripRequestStatus = TripRequestStatus
            .PRICE_ESTIMATED; // Volta ao estado de estimativa em caso de falha
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao solicitar viagem. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- LÓGICA DE MOTORISTA: RASTREAMENTO E ATUALIZAÇÃO ---

  Future<void> _startLocationTrackingForDriver() async {
    if (!_isFirebaseReady) return; // Proteção

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

          _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: newPosition,
              infoWindow: const InfoWindow(title: 'Você está ONLINE'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          );
        });

        _updateDriverLocationInFirestore(position);
      },
      onError: (e) {
        print('ERRO no Stream de Localização: $e');
        _stopLocationTracking();
      },
      cancelOnError: true,
    );
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    if (!_isFirebaseReady) return; // Proteção

    try {
      final driverDocRef = _firestore
          .collection('artifacts')
          .doc(_appId) // USANDO O NOVO _appId
          .collection('public')
          .doc('data')
          .collection('drivers')
          .doc(widget.userId);

      await driverDocRef.set({
        'driverId': widget.userId,
        'isOnline': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('ERRO FIRESTORE: Falha ao enviar localização: $e');
    }
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('RASTREAMENTO: Rastreamento interrompido.');

    if (widget.userRole == 'motorista' && _isFirebaseReady) {
      _firestore
          .collection('artifacts')
          .doc(_appId) // USANDO O NOVO _appId
          .collection('public')
          .doc('data')
          .collection('drivers')
          .doc(widget.userId)
          .update({
        'isOnline': false,
        'timestamp': FieldValue.serverTimestamp(),
      }).catchError((e) {
        print('ERRO FIRESTORE: Falha ao marcar como offline: $e');
      });
    }
  }

  // --- LÓGICA DE UI E ESTADO ---

  void _onSearchChanged() {
    if (_tripRequestStatus == TripRequestStatus.REQUEST_SENT) return;

    setState(() {
      _tripRequestStatus = _searchController.text.isNotEmpty
          ? TripRequestStatus.CHOOSING_DESTINATION
          : TripRequestStatus.IDLE;
    });
  }

  void _onSelectDestination(String address) {
    setState(() {
      _destinationAddress = address;
      _searchController.text = address.split(',').first;
      _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;
      // Adiciona o marcador de destino (mock)
      _markers.removeWhere((m) => m.markerId.value == 'destinationLocation');
      // Posição mock de destino (simulação)
      final mockDestination = LatLng(
          _currentPosition.latitude + 0.01, _currentPosition.longitude + 0.01);
      _markers.add(
        Marker(
          markerId: const MarkerId('destinationLocation'),
          position: mockDestination,
          infoWindow: InfoWindow(title: 'Destino: $address'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );

      // Move a câmera para mostrar a rota (mock)
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
                _currentPosition.latitude < mockDestination.latitude
                    ? _currentPosition.latitude
                    : mockDestination.latitude,
                _currentPosition.longitude < mockDestination.longitude
                    ? _currentPosition.longitude
                    : mockDestination.longitude),
            northeast: LatLng(
                _currentPosition.latitude > mockDestination.latitude
                    ? _currentPosition.latitude
                    : mockDestination.latitude,
                _currentPosition.longitude > mockDestination.longitude
                    ? _currentPosition.longitude
                    : mockDestination.longitude),
          ),
          100.0, // padding
        ),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 0) {
        _searchController.clear();
        _destinationAddress = null;
        _tripRequestStatus = TripRequestStatus.IDLE;
        _markers.removeWhere((m) => m.markerId.value == 'destinationLocation');

        // Se o motorista sair da aba do mapa, ele é forçado a ficar OFFLINE
        if (widget.userRole == 'motorista' && _isDriverOnline) {
          _isDriverOnline = false;
          _stopLocationTracking();
          _stopListeningToRequests();
        }
      }
    });
  }

  void _addInitialMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: 'Sua Localização'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isMapReady = true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isMapReady = true);
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
        _isMapReady = true;

        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: newPosition,
            infoWindow: const InfoWindow(title: 'Sua Localização Atual'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      print('ERRO GERAL na localização inicial: $e');
      setState(() => _isMapReady = true);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != _kInitialPosition && _isMapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 15.0),
        ),
      );
    }
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    // Adicione um indicador de carregamento se o Firebase não estiver pronto
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

    switch (_selectedIndex) {
      case 0:
        appBarTitle = isPassenger ? 'Pedir Viagem' : 'Modo Motorista';
        content = _buildMapSection(context, isPassenger);
        break;
      case 1:
        appBarTitle =
            isPassenger ? 'Histórico de Viagens' : 'Ganhos e Relatórios';
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

  // Seção principal do Mapa (Aba 0)
  Widget _buildMapSection(BuildContext context, bool isPassenger) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final Widget googleMapWidget = _isMapReady
        ? GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text('Aguardando permissão de localização...',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          );

    // Lógica para Motorista - MODO MOTORISTA
    if (!isPassenger) {
      return Stack(
        children: [
          // MAPA REAL (Fundo)
          googleMapWidget,

          // Painel de Status do Motorista
          _buildDriverStatusPanel(context, primaryColor),

          // NOVO: UI para Aceitar Pedido (Flutuante)
          if (_pendingRequest != null)
            _buildDriverRequestCard(context, primaryColor),
        ],
      );
    }

    // Lógica para Passageiro - MODO PASSAGEIRO
    return Stack(
      children: [
        // 1. MAPA REAL (Fundo)
        googleMapWidget,

        // 2. Barra de Busca e Autocomplete (Topo)
        Positioned(
          top: 50,
          left: 15,
          right: 15,
          child: _buildPassengerSearchUI(context, primaryColor),
        ),

        // 3. Estação de Preço Estimado/Pedido Enviado (Exibição Condicional)
        if (_tripRequestStatus == TripRequestStatus.PRICE_ESTIMATED ||
            _tripRequestStatus == TripRequestStatus.REQUEST_SENT)
          Center(
            child: _buildPassengerPriceEstimateCard(context, primaryColor),
          ),

        // 4. Botões de Rápido Acesso (Lateral Direita Inferior)
        _buildQuickAccessButtons(context, primaryColor),
      ],
    );
  }

  // --- WIDGETS AUXILIARES DO MOTORISTA ---

  Widget _buildDriverStatusPanel(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    final buttonColor = _isDriverOnline ? Colors.red : Colors.green;
    final buttonText = _isDriverOnline ? 'FICAR OFFLINE' : 'FICAR ONLINE';
    final statusText = _isDriverOnline
        ? 'Status: ONLINE. Aguardando corridas.'
        : 'Status: OFFLINE. Pronto para dirigir?';
    final statusIcon =
        _isDriverOnline ? Icons.check_circle : Icons.power_settings_new;

    return Align(
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
              statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isDriverOnline
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isDriverOnline = !_isDriverOnline;
                  });

                  if (_isDriverOnline) {
                    _startLocationTrackingForDriver();
                    _startListeningToRequestsForDriver();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Você ficou ONLINE! Começando o rastreamento...')),
                    );
                  } else {
                    _stopLocationTracking();
                    _stopListeningToRequests();
                    setState(() {
                      _pendingRequest = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Você ficou OFFLINE. O rastreamento parou.')),
                    );
                  }
                },
                icon: Icon(statusIcon),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
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
    );
  }

  Widget _buildDriverRequestCard(BuildContext context, Color primaryColor) {
    if (_pendingRequest == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final request = _pendingRequest!;
    final originAddress = request['originAddress'] as String? ?? 'Desconhecido';
    final destinationAddress =
        request['destinationAddress'] as String? ?? 'Desconhecido';
    final estimatedPrice = request['estimatedPrice'] as double? ?? 0.0;
    final requestId = request['requestId'] as String;

    return Positioned(
      top: 20,
      left: 15,
      right: 15,
      child: Card(
        color: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NOVO PEDIDO DE VIAGEM',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Divider(height: 10, color: Colors.grey),
              _buildRequestDetailRow(
                  Icons.pin_drop, 'Origem:', originAddress, primaryColor),
              const SizedBox(height: 5),
              _buildRequestDetailRow(
                  Icons.flag, 'Destino:', destinationAddress, primaryColor),
              const SizedBox(height: 5),
              _buildRequestDetailRow(
                  Icons.monetization_on,
                  'Valor Estimado:',
                  'R\$ ${estimatedPrice.toStringAsFixed(2)}',
                  Colors.green.shade700),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRequest(requestId),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('ACEITAR CORRIDA',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES DO PASSAGEIRO ---

  Widget _buildPassengerSearchUI(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    final isSearchFocused =
        _tripRequestStatus == TripRequestStatus.CHOOSING_DESTINATION;
    final isRequestFlowActive = _tripRequestStatus != TripRequestStatus.IDLE &&
        _tripRequestStatus != TripRequestStatus.REQUEST_SENT;

    final List<Map<String, String>> mockResults = [
      {'name': 'Aeroporto (GRU)', 'address': 'Guarulhos, São Paulo'},
      {'name': 'Casa', 'address': 'Rua das Flores, 101'},
      {'name': 'Trabalho', 'address': 'Av. Paulista, 900'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de Busca
        Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Para onde você vai? (Ex: Aeroporto)',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                          _destinationAddress = null;
                        },
                      )
                    : null,
              ),
              readOnly: _tripRequestStatus == TripRequestStatus.REQUEST_SENT,
              onTap: () {
                if (_tripRequestStatus != TripRequestStatus.REQUEST_SENT &&
                    _tripRequestStatus !=
                        TripRequestStatus.CHOOSING_DESTINATION) {
                  setState(() {
                    _tripRequestStatus = TripRequestStatus.CHOOSING_DESTINATION;
                  });
                }
              },
            ),
          ),
        ),
        // Resultados Mock de Autocomplete
        if (isSearchFocused)
          Card(
            margin: const EdgeInsets.only(top: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: Column(
              children: mockResults
                  .where((r) => r['name']!
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                  .map(
                    (result) => ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(result['name']!),
                      subtitle: Text(result['address']!),
                      onTap: () => _onSelectDestination(result['address']!),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPassengerPriceEstimateCard(
      BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    final isWaiting = _tripRequestStatus == TripRequestStatus.REQUEST_SENT;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWaiting ? 'Procurando Motorista...' : 'Sua Viagem',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWaiting ? Colors.orange.shade700 : primaryColor,
              ),
            ),
            const Divider(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preço Estimado:',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'R\$ ${_mockPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Destino: $_destinationAddress',
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isWaiting ? null : _saveTripRequestToFirestore,
                icon: isWaiting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  isWaiting ? 'Aguardando Confirmação' : 'SOLICITAR VIAGEM',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWaiting ? Colors.grey : primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            if (isWaiting)
              TextButton(
                onPressed: () {
                  // Lógica para cancelar o pedido e voltar ao estado de estimativa
                  setState(() {
                    _tripRequestStatus = TripRequestStatus.PRICE_ESTIMATED;
                    // TODO: Implementar cancelamento no Firestore
                    _currentRequestId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido cancelado pelo passageiro.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Center(
                  child: Text('Cancelar Pedido',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context, Color primaryColor) {
    if (_tripRequestStatus != TripRequestStatus.IDLE) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 20,
      right: 15,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'centerMap',
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentPosition, zoom: 15.0),
                  ),
                );
              }
            },
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'favorites',
            onPressed: () {
              // Simula um clique rápido para definir um destino favorito
              _onSelectDestination('Rua Fictícia Favorita, 500');
            },
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            mini: true,
            child: const Icon(Icons.favorite_border),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 60, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Usuário ID (UID):',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              widget.userId,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            Text(
              'Você está logado como: ${widget.userRole.toUpperCase()}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            // Botão de Logout Simulado
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Simula o logout forçando o estado a 'loading'
                  // Na app real, você chamaria FirebaseAuth.instance.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saindo...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Esta função não faz o logout real, mas mostra o conceito.
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair / Logout',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
