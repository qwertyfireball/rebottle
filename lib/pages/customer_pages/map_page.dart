//MICHAEL WAS HERE!
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// import 'package:rebottle/pages/owner_pages/map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
}

class MapPage extends StatefulWidget {
  //MICHAEL WAS HERE!
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng startpos = LatLng(39.9055, 116.3976);
  LatLng? cafepos = null;
  LatLng? currentPosition = null;
  Location locationController = new Location(); //MICHAEL WAS HERE!

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    getlocationUpdates();
  } //MICHAEL WAS HERE!

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
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Nearby Partnered Cafes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              // child: Center(
              child: Expanded(
                child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: startpos, zoom: 13),
                    markers: markers),
              ),
              // ),
            ),
          ),
        ],
      ),
    );
  }

  void markerMaker() {
    Set<Marker> newmarkers = {};
    if (currentPosition != null) {
      newmarkers.add(Marker(
          markerId: MarkerId("You're Here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: currentPosition!));}

    final markerId = "cafe_name";
    if (cafepos != null) {
      newmarkers.add(Marker(
        markerId: MarkerId(markerId), // fix
        position: cafepos!, // fix
        icon: BitmapDescriptor.defaultMarker,
      ));
      setState(() {
        markers = newmarkers;
      });
    }
  }
}
