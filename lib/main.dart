import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'marcadorDB.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ocultar debug
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
  Set<Marker> _markers = {};
  bool puedeEditar = true;

  LatLng? currentPosition;
  Location location = Location();
  final TextEditingController nameController = TextEditingController(); // Nuevo


  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    setState(() {
      currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  void toggleMarkerAdding() {
    setState(() {
      puedeEditar = !puedeEditar;
    });
  }

  void _addMarker(LatLng position, String name) async {
    if (puedeEditar) return;

    final markerId = MarkerId(DateTime.now().toString());
    final marker = Marker(
      markerId: markerId,
      position: position,
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.pageview),
                  title: Text('Ir a otra página'),
                  onTap: () {
                    Navigator.pushNamed(context, '/other_page');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Ir a esta ubicación'),
                  onTap: () {
                    // Aquí puedes implementar la lógica para ir a la ubicación del marcador
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Eliminar este marcador'),
                  onTap: () {
                    setState(() {
                      //_markers.remove(marker);
                    });
                    Navigator.pop(context); // Cerrar el modal bottom sheet
                  },
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      _markers.add(marker);
    });

    final markerData = MarkerData(
      name: name,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    await DatabaseHelper.instance.insertMarker(markerData);
  }

  @override
  void dispose() {
    nameController.dispose(); // Liberar el TextEditingController
    super.dispose();
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    loadMarkers(); // Nuevo
  }

  void loadMarkers() async {
    final markers = await DatabaseHelper.instance.getMarkers();
    setState(() {
      _markers = markers.map((markerData) {
        final markerId = MarkerId(markerData.id.toString());
        final marker = Marker(
          markerId: markerId,
          position: LatLng(markerData.latitude, markerData.longitude),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[

                        ListTile(
                          leading: Icon(Icons.pageview),
                          title: Text('Nombre del marcador: ${markerData.name}'),
                          onTap: () {
                            //Navigator.pushNamed(context, '/other_page');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.pageview),
                          title: Text('Posición: ${markerData.latitude}, ${markerData.longitude}'),
                          onTap: () {
                            //Navigator.pushNamed(context, '/other_page');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.pageview),
                          title: Text('Ir a otra página'),
                          onTap: () {
                            Navigator.pushNamed(context, '/other_page');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text('Ir a esta ubicación'),
                          onTap: () {
                            // Aquí puedes implementar la lógica para ir a la ubicación del marcador
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Eliminar este marcador'),
                          onTap: () async {
                            await DatabaseHelper.instance.deleteMarker(markerData.id!);
                            setState(() {
                              _markers.removeWhere((marker) => marker.markerId.value == markerId.value);
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
          },
        );
        return marker;
      }).toSet();
    });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de basureros'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {},
            initialCameraPosition: const CameraPosition(
              target: LatLng(-4.020701, -79.216120), // Coordenadas iniciales del mapa
              zoom: 20.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onTap: (position) {
              if (!puedeEditar) {
                _showNameDialog(position);
              }

            },
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
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    toggleMarkerAdding();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ya no puedes agregar marcadores'),
                        duration: Duration(seconds: 3),
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
                _clearMarkers();
              },
              child: const Icon(Icons.delete),
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
      body: Center(
        child: const Text('Otra página'),
      ),
    );
  }
}
