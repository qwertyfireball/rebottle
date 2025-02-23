//MICHAEL WAS HERE!
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
}

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng startpos = LatLng(39.9055, 116.3976);
  static const LatLng yourpos = LatLng(2,3);
  LatLng? cafe1 = null;
  LatLng? currentPosition = null;
  Location locationController = new Location();

  @override
  void initState() {
    super.initState();
    getlocationUpdates();
  }

  //ask for permission and get constant location
  Future<void> getlocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          debugPrint("Updated position: $currentPosition");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 146, 206, 255),
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 30,
              ),
              Text(
                'Cafes near you',
                style: GoogleFonts.openSans(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: startpos, zoom: 13),
              markers: {
                Marker(
                    markerId: MarkerId("You're Here"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: yourpos),
                Marker(
                    markerId: MarkerId("new cafe"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: cafe1!)
              },
            ),
          ),
          FloatingActionButton(
            onPressed: () {
              if (currentPosition != null) {
                setState(() {
                  cafe1 = LatLng(
                      currentPosition!.latitude, currentPosition!.longitude);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Current Position: $currentPosition")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Location not available yet!")),
                );
              }
            },
            child: Icon(Icons.location_on),
          )
        ],
      ),
    );
  }
}