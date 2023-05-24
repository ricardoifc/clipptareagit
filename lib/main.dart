import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';




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
  String _nombreCalle = '';




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

  void _editarNombre(MarkerData markerData) async {
    String oldName = markerData.name;
    nameController.text = oldName;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Text("hi");/*AlertDialog(
          title: const Text('Editar nombre de marcador'),
          content: TextField(
            controller: nameController,
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
              onPressed: () async {
                String newName = nameController.text;
                await DatabaseHelper.instance.updateMarkerName(markerData.id!, newName);

                setState(() {
                  _marcadores = _marcadores.map((marker) {
                    if (marker.markerId.value == markerData.id.toString()) {
                      return marker.copyWith(
                        infoWindowParam: InfoWindow(
                          title: newName,
                          snippet: 'Posición: ${markerData.latitude}, ${markerData.longitude}',
                        ),
                      );
                    }
                    return marker;
                  }).toSet();
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );*/
      },
    );
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





  List<LatLng> _decodificarPolilinea(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latDouble = lat / 1e5;
      double lngDouble = lng / 1e5;
      points.add(LatLng(latDouble, lngDouble));
    }

    return points;
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
                        //_editarNombre(markerData);
                        //Navigator.of(context).pop();
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

  Future<void> _drawRouteToMarker(MarkerData markerData) async {
    // ubicación actual
    LocationData ubicacionActual = await ubicacion.getLocation();
    LatLng currentLatLng = LatLng(ubicacionActual.latitude!, ubicacionActual.longitude!);

    LatLng startLatLng = currentLatLng;
    LatLng finalLatLng = LatLng(markerData.latitude, markerData.longitude);

    // API de direcciones
    String apiKey = 'AIzaSyCoQcikzh8RyjXsBlLCVxUJuvkHP2vpttM';
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${startLatLng.latitude},${startLatLng.longitude}&destination=${finalLatLng.latitude},${finalLatLng.longitude}&key=$apiKey';
    //http.Response response = await http.get(Uri.parse(url));

    try { //DIO
      Response response = await Dio().get(url); //DIO

      if (response.statusCode == 200) {

        // Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, dynamic> data = response.data;
        List<LatLng> polylinePoints = [];

        if (data['status'] == 'OK') {
          List<dynamic> pasos = data['routes'][0]['legs'][0]['steps'];
          for (var step in pasos) {
            double inicioLat = step['start_location']['lat'];
            double inicioLng = step['start_location']['lng'];
            double finalLat = step['end_location']['lat'];
            double finalLng = step['end_location']['lng'];

            polylinePoints.add(LatLng(inicioLat, inicioLng)); // punto inicial
            String endStreet = await _callesNombres(finalLat, finalLng);
            print('Calle de destino: $endStreet');


            List<LatLng> puntosIntermedios = _decodificarPolilinea(step['polyline']['points']); // puntos intermedios
            polylinePoints.addAll(puntosIntermedios);

            polylinePoints.add(LatLng(finalLat, finalLng)); // punto final



            /*
          double lat = step['end_location']['lat'];
          double lng = step['end_location']['lng'];
          polylinePoints.add(LatLng(lat, lng));
          */

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
                startLatLng.latitude < finalLatLng.latitude ? startLatLng.latitude : finalLatLng.latitude,
                startLatLng.longitude < finalLatLng.longitude ? startLatLng.longitude : finalLatLng.longitude,
              ),
              northeast: LatLng(
                startLatLng.latitude > finalLatLng.latitude ? startLatLng.latitude : finalLatLng.latitude,
                startLatLng.longitude > finalLatLng.longitude ? startLatLng.longitude : finalLatLng.longitude,
              ),
            ),
            50.0, // área visible
          ),
        );
      } else {
        print('Error al obtener la ruta: ${response.statusCode}');
      }
    }
    catch (e) { // DIO
      print('Error al obtener la ruta: $e'); // DIO
    }
  }

  Future<String> _callesNombres(double latitude, double longitude) async {
    String apiKey = 'AIzaSyCoQcikzh8RyjXsBlLCVxUJuvkHP2vpttM';
    String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    try {
      Response response = await Dio().get(url);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;
        if (data['status'] == 'OK') {
          List<dynamic> results = data['results'];
          if (results.isNotEmpty) {
            setState(() {
              _nombreCalle = results[0]['formatted_address'];
            });
          } else {
            setState(() {
              _nombreCalle = 'Calle desconocida';
            });
          }
        }
      }
      return 'Calle desconocida';
    } catch (e) {
      print('Error al obtener el nombre de la calle: $e');
      return 'Calle desconocida';
    }
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
          Container(
            height: 40.0,
            color: Colors.white,
            child: Center(
              child: Text(
                'Calles: $_nombreCalle',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
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

