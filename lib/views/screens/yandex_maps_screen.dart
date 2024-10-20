import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../services/location_service.dart';
import '../../services/yandex_service.dart';
import '../widgets/error_dialog.dart';
import '../widgets/zoom_button.dart';

class YandexMapsScreen extends StatefulWidget {
  const YandexMapsScreen({super.key});

  @override
  State<YandexMapsScreen> createState() => _YandexMapsScreenState();
}

class _YandexMapsScreenState extends State<YandexMapsScreen> {
  YandexMapController? _yandexMapController;
  Point? _userCurrentPosition;
  bool _isFetchingAddress = true;
  List _suggestionList = [];
  List<MapObject>? _polyLines;
  final TextEditingController _searchTextController = TextEditingController();

  void _onMapCreated(YandexMapController yandexMapController) {
    _yandexMapController = yandexMapController;
    if (_userCurrentPosition != null) {
      _yandexMapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userCurrentPosition!, zoom: 17),
        ),
      );
    }
  }

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    super.initState();
    LocationService.determinePosition().then(
      (value) async {
        if (value != null) {
          _userCurrentPosition = Point(
            latitude: value.latitude,
            longitude: value.longitude,
          );
        }
      },
    ).catchError((error) {
      showDialog(
        context: context,
        builder: (context) => ShowErrorDialog(errorText: error.toString()),
      );
    }).whenComplete(
      () {
        _isFetchingAddress = false;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    positionStream.cancel();
    _searchTextController.dispose();
    super.dispose();
  }

  void _onMyLocationTapped() {
    if (_userCurrentPosition != null || _yandexMapController != null) {
      _yandexMapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userCurrentPosition!, zoom: 17),
        ),
      );
    }
  }

  Future<SuggestSessionResult> _suggest() async {
    final resultWithSession = await YandexSuggest.getSuggestions(
      text: _searchTextController.text,
      boundingBox: const BoundingBox(
        northEast: Point(latitude: 56.0421, longitude: 38.0284),
        southWest: Point(latitude: 55.5143, longitude: 37.24841),
      ),
      suggestOptions: const SuggestOptions(
        suggestType: SuggestType.geo,
        suggestWords: true,
        userPosition: Point(latitude: 56.0321, longitude: 38),
      ),
    );

    return await resultWithSession.$2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isFetchingAddress
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                YandexMap(
                  onMapCreated: _onMapCreated,
                  zoomGesturesEnabled: true,
                  mapObjects: [
                    PlacemarkMapObject(
                      mapId: const MapObjectId('current_location'),
                      point: _userCurrentPosition!,
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                            "assets/icons/current_location_pin.png",
                          ),
                        ),
                      ),
                    ),
                    ...?_polyLines,
                  ],
                  onMapLongTap: (argument) async {
                    _polyLines = await YandexMapService.getDirection(
                        _userCurrentPosition!, argument);
                    setState(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomZoomButton(
                          isZoomIn: true,
                          onTap: () {
                            _yandexMapController!.moveCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        CustomZoomButton(
                          isZoomIn: false,
                          onTap: () {
                            _yandexMapController!.moveCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF1C1D22),
              onPressed: _onMyLocationTapped,
              child: const Icon(
                Icons.navigation_outlined,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchTextController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) async {
                final res = await _suggest();
                if (res.items != null) {
                  _suggestionList = res.items!.toSet().toList();
                  setState(() {});
                }
              },
            ),
          ),
          SizedBox(
            height: _suggestionList.isNotEmpty ? 200 : 0,
            child: ListView.builder(
              itemCount: _suggestionList.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 50,
                  margin: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(
                        _suggestionList[index].subtitle.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
