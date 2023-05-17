import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ocultar debug
      title: 'CLIPP TAREA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapaPage(),
    );
  }
}

class MapaPage extends StatefulWidget{
  const MapaPage({super.key});

  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de basureros'),
        ),
        body:
        //const Text("mapa aqui")
      GoogleMap(
        onMapCreated: _onMapCreated,
        polylines: _polylines,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-4.020701, -79.216120), // Coordenadas iniciales del mapa
          zoom: 20.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
  late GoogleMapController _mapController;
  Location _location = Location();
  List<LatLng> _polylinePoints = [];
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_mapController != null) {
        _updateLocation(currentLocation);
      }
    });
  }

  void _updateLocation(LocationData locationData) {
    final latLng = LatLng(locationData.latitude!, locationData.longitude!);
    setState(() {
      _polylinePoints.add(latLng);
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _polylinePoints,
        color: Colors.blue,
      ));
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }


}

