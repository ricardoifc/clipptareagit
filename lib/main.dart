import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter_geocoding/flutter_geocoding.dart';
// import 'package:geocoder/geocoder.dart';


import 'marcadorDB.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CLIPP TAREA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapaPage(),
      routes: {
        '/other_page': (context) => OtherPage(),
      },
    );
  }
}

class MapaPage extends StatefulWidget {
  const MapaPage({Key? key});

  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  List<MarkerData> _listaMarcadores = [];
  Polyline? _polyline;

  Set<Marker> _marcadores = {};
  bool puedeEditar = true;

  LatLng? posicionActual;
  Location ubicacion = Location();
  final TextEditingController nameController = TextEditingController();



  void toggleMarkerAdding() {
    setState(() {
      puedeEditar = !puedeEditar;
    });
  }





  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }


  void _addMarker(LatLng posicion, String name) async {
    MarkerData markerData = MarkerData(
      name: name,
      latitude: posicion.latitude,
      longitude: posicion.longitude,
    );
    int markerId = await DatabaseHelper.instance.insertMarker(markerData);
    MarkerId markerIdObject = MarkerId(markerId.toString());
    Marker marker = Marker(
      markerId: markerIdObject,
      position: posicion,
      onTap: () {},
    );

    setState(() {
      _marcadores.add(marker);
    });

    // Actualizar los marcadores después de agregar uno nuevo
    updateMarkers();
  }


  /*void _drawRouteToMarker(MarkerData markerData) async {
    // Obtener la ubicación actual
    LocationData currentLocation = await location.getLocation();
    LatLng currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);


    LatLng startLatLng = currentLatLng;
    LatLng endLatLng = LatLng(markerData.latitude, markerData.longitude);

    List<LatLng> polylinePoints = [startLatLng, endLatLng];

    PolylineId polylineId = PolylineId('route');
    Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blue,
      width: 2,
      points: polylinePoints,
    );

    setState(() {
      _polyline = polyline;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            startLatLng.latitude < endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
            startLatLng.longitude < endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
          ),
          northeast: LatLng(
            startLatLng.latitude > endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
            startLatLng.longitude > endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
          ),
        ),
        50.0,
      ),
    );
  }*/


  Future<void> _drawRouteToMarker(MarkerData markerData) async {
    // ubicación actual
    LocationData ubicacionActual = await ubicacion.getLocation();
    LatLng currentLatLng = LatLng(ubicacionActual.latitude!, ubicacionActual.longitude!);

    LatLng startLatLng = currentLatLng;
    LatLng endLatLng = LatLng(markerData.latitude, markerData.longitude);

    // API de direcciones
    String apiKey = 'AIzaSyCoQcikzh8RyjXsBlLCVxUJuvkHP2vpttM';
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${startLatLng.latitude},${startLatLng.longitude}&destination=${endLatLng.latitude},${endLatLng.longitude}&key=$apiKey';
    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // JSON
      Map<String, dynamic> data = jsonDecode(response.body);
      List<LatLng> polylinePoints = [];

      if (data['status'] == 'OK') {
        List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];
        for (var step in steps) {
          double lat = step['end_location']['lat'];
          double lng = step['end_location']['lng'];
          polylinePoints.add(LatLng(lat, lng));
        }
      }

      // Dibujar
      PolylineId polylineId = PolylineId('route');
      Polyline polyline = Polyline(
        polylineId: polylineId,
        color: Colors.blue,
        width: 2,
        points: polylinePoints,
      );

      setState(() {
        _polyline = polyline;
      });

      // Ajustar pantalla ruta
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              startLatLng.latitude < endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
              startLatLng.longitude < endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
            ),
            northeast: LatLng(
              startLatLng.latitude > endLatLng.latitude ? startLatLng.latitude : endLatLng.latitude,
              startLatLng.longitude > endLatLng.longitude ? startLatLng.longitude : endLatLng.longitude,
            ),
          ),
          50.0, // área visible
        ),
      );
    } else {
      print('Error al obtener la ruta: ${response.statusCode}');
    }
  }





  void updateMarkers() async {
    final marcadores = await DatabaseHelper.instance.getMarkers();
    setState(() {
      _listaMarcadores = marcadores;
    });
    Set<Marker> updatedMarkers = marcadores.map((markerData) {
      final markerId = MarkerId(markerData.id.toString());
      final marcador = Marker(
        markerId: markerId,
        position: LatLng(markerData.latitude, markerData.longitude),
        onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.location_city),
                      title: Text('Nombre del marcador: ${markerData.name}'),
                      onTap: () {
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on_outlined),
                      title: Text(
                          'Posición: ${markerData.latitude}, ${markerData.longitude}'),
                      onTap: () {
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.pageview),
                      title: Text('Ir a otra página'),
                      onTap: () {
                        Navigator.pushNamed(context, '/other_page');
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Ir a esta ubicación'),
                      onTap: () {
                        _drawRouteToMarker(markerData);
                        Navigator.of(context).pop();

                      },

                    ),
                    ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Eliminar este marcador'),
                      onTap: () async {
                        await DatabaseHelper.instance
                            .deleteMarker(markerData.id!);

                        setState(() {
                          _marcadores.removeWhere(
                                  (marker) => marker.markerId.value == markerId.value);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
        return marcador;
      }).toSet();
    setState(() {
      _marcadores = updatedMarkers;
    });
  }

  @override
  void initState() {
    super.initState();
    updateMarkers();
  }

  Future<void> _showNameDialog(LatLng position) async {
    String? markerName = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ingrese un nombre para el marcador'),
          content: TextField(
            onChanged: (value) {
              markerName = value;
            },
            decoration: const InputDecoration(
              hintText: 'Nombre del marcador',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                _addMarker(position, markerName!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showMarkerList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerListPage(markerList: _listaMarcadores),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de x'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(-4.020701, -79.216120),
              zoom: 20.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _marcadores,
            polylines: _polyline != null ? Set<Polyline>.from([_polyline!]) : Set<Polyline>(),

            onTap: (position) {
              if (!puedeEditar) {
                _showNameDialog(position);
              }
            },
          ),
          Positioned(
            top: 10.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              height: 40.0,
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Calles: Aqui calles marcador',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 9.0,
            right: 70.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (puedeEditar) {
                    toggleMarkerAdding();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ahora puedes editar'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    toggleMarkerAdding();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ya no puedes agregar marcadores'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              },
              child: Icon(puedeEditar ? Icons.add : Icons.remove),
            ),
          ),
          Positioned(
            bottom: 9.0,
            right: 130.0,
            child: FloatingActionButton(
              onPressed: () {
                _showMarkerList();
              },
              child: const Icon(Icons.list),
            ),
          ),
          Positioned(
            bottom: 9.0,
            right: 190.0,
            child: FloatingActionButton(
              onPressed: () {
                updateMarkers();
              },
              child: const Icon(Icons.refresh),
            ),
          ),

        ],
      ),
    );
  }
}

class OtherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otra página'),
      ),
      body: const Center(
        child: Text('Contenido de página'),
      ),
    );
  }
}

class MarkerListPage extends StatefulWidget {
  final List<MarkerData> markerList;

  MarkerListPage({required this.markerList});

  @override
  _MarkerListPageState createState() => _MarkerListPageState();
}

class _MarkerListPageState extends State<MarkerListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Marcadores'),
      ),
      body: ListView.builder(
        itemCount: widget.markerList.length,
        itemBuilder: (BuildContext context, int index) {
          final marker = widget.markerList[index];
          return ListTile(
            title: Text(marker.name),
            subtitle: Text(
              'Latitud: ${marker.latitude}, Longitud: ${marker.longitude}',
            ),
            onTap: () {
              // Acción al seleccionar un marcador de la lista
            },
          );
        },
      ),
    );
  }
}

