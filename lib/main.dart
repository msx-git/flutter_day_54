import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationService.checkPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class YandexMapScreen extends StatefulWidget {
  const YandexMapScreen({super.key});

  @override
  _YandexMapScreenState createState() => _YandexMapScreenState();
}

class _YandexMapScreenState extends State<YandexMapScreen> {
  YandexMapController? _mapController;
  Point? _selectedPoint;
  final List<MapObject> _mapObjects = [];
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      _moveToLocation(position.latitude, position.longitude, isInitial: true);
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  void _moveToLocation(double latitude, double longitude,
      {bool isInitial = false}) {
    if (_mapController != null) {
      final point = Point(latitude: latitude, longitude: longitude);
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: _currentZoom),
        ),
        animation: const MapAnimation(duration: 1),
      );

      if (isInitial) {
        setState(
          () {
            _selectedPoint = point;
            _mapObjects.clear();
            _mapObjects.add(
              PlacemarkMapObject(
                mapId: const MapObjectId('current_location'),
                point: point,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(
                      'assets/current_location_pin.png',
                    ),
                    scale: 0.2,
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: YandexMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onCameraPositionChanged: (cameraPosition, reason, finished) {
          if (finished) {
            _currentZoom = cameraPosition.zoom;
          }
        },
        onMapTap: (point) {
          setState(() {
            _selectedPoint = point;
            _mapObjects.clear();
            _mapObjects.add(
              PlacemarkMapObject(
                mapId: const MapObjectId('selected_point'),
                point: point,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(
                        'assets/selected_location_pin.png'),
                    scale: 0.2,
                  ),
                ),
              ),
            );
          });
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: point, zoom: _currentZoom),
            ),
          );
        },
        mapObjects: _mapObjects,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          if (_selectedPoint != null) {
            Navigator.pop(context, _selectedPoint);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a location first')),
            );
          }
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Point? _savedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yandex Maps Integration')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Select Location'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const YandexMapScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _savedLocation = result;
                  });
                }
              },
            ),
            if (_savedLocation != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Selected Location:'),
                      const SizedBox(height: 8),
                      Text(
                          'Latitude: ${_savedLocation!.latitude.toStringAsFixed(6)}'),
                      Text(
                          'Longitude: ${_savedLocation!.longitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: YandexMap(
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          mapObjects: [
                            PlacemarkMapObject(
                              mapId: const MapObjectId('saved_location'),
                              point: _savedLocation!,
                              icon: PlacemarkIcon.single(
                                PlacemarkIconStyle(
                                  image: BitmapDescriptor.fromAssetImage(
                                    'assets/selected_location_pin.png',
                                  ),
                                  scale: 0.2,
                                ),
                              ),
                            ),
                          ],
                          onMapCreated: (controller) {
                            controller.moveCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: _savedLocation!, zoom: 16),
                              ),
                              animation: const MapAnimation(duration: 1),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
