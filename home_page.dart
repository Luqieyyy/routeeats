import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  LatLng _userLocation = const LatLng(1.8683774, 103.1063707);
  final Set<Marker> _markers = {};
  final String _apiKey = "YOUR_API_KEY_HERE";

  final List<LatLng> customFoodSpots = [
    LatLng(3.8678, 103.0795), // Mee Tarik example
  ];

  final String _mapStyle = '''
[
  {
    "featureType": "all",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.food_and_drink",
    "elementType": "all",
    "stylers": [{ "visibility": "on" }]
  },
  {
    "featureType": "poi.restaurant",
    "elementType": "all",
    "stylers": [{ "visibility": "on" }]
  },
  {
    "featureType": "poi.cafe",
    "elementType": "all",
    "stylers": [{ "visibility": "on" }]
  },

  // 🔴 Explicitly hide these manually
  {
    "featureType": "poi.business",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.lodging",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.medical",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.place_of_worship",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.school",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.attraction",
    "elementType": "all",
    "stylers": [{ "visibility": "off" }]
  },

  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "visibility": "on" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "visibility": "on" }]
  }
]
''';




  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
    _loadNearbyFoodPlaces();
  }

  Future<void> _loadNearbyFoodPlaces() async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_userLocation.latitude},${_userLocation.longitude}&radius=2000&type=restaurant&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      for (var place in results) {
        final LatLng pos = LatLng(
          place['geometry']['location']['lat'],
          place['geometry']['location']['lng'],
        );

        _markers.add(
          Marker(
            markerId: MarkerId(place['place_id']),
            position: pos,
            infoWindow: InfoWindow(title: place['name']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }

      for (var spot in customFoodSpots) {
        _markers.add(
          Marker(
            markerId: MarkerId("custom_${spot.latitude}"),
            position: spot,
            infoWindow: const InfoWindow(title: "Mee Tarik Warisan Asli"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      setState(() {});
    } else {
      print("Failed to load nearby places.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("CraveMap"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              mapController.setMapStyle(_mapStyle);
            },
            initialCameraPosition: CameraPosition(
              target: _userLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            markers: _markers,
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: const [
                    Icon(Icons.local_fire_department, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🔥 Trending Now: Mee Tarik Warisan Asli - 300m ahead!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: "Track"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
