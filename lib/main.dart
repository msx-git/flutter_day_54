import 'package:flutter/material.dart';
import '/views/screens/yandex_maps_screen.dart';
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
      home: YandexMapsScreen(),
    );
  }
}
