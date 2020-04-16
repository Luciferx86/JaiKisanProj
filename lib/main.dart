import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;
import 'package:geolocator/geolocator.dart';
import 'dart:developer';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        primarySwatch: Colors.blue,
      ),
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Set<Marker> markers = {};

  Set<Polygon> myPolygon() {
    List<LatLng> polygonCoords = new List();

    this.markers.forEach((marker) {
      polygonCoords.add(marker.position);
    });

    Set<Polygon> polygonSet = new Set();
    if (polygonCoords.length > 1) {
      polygonSet.add(Polygon(
          polygonId: PolygonId('test'),
          points: polygonCoords,
          strokeColor: Colors.red,
          strokeWidth: 4,
          fillColor: Colors.blueAccent));
    }

    return polygonSet;
  }

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(35.22, -101.83),
    zoom: 14.4746,
  );

  CameraPosition cameraPosition = null;

  Widget getMap() {
    return Stack(children: [
      GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: cameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: this.markers,
        onTap: handleTap,
        polygons: myPolygon(),
      ),
      Container(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton.extended(
              onPressed: showArea,
              backgroundColor: Colors.deepOrange,
              label: Text('Get Area'),
              icon: Icon(Icons.crop_square),
            ),
            FloatingActionButton.extended(
              onPressed: removeAllMarkers,
              label: Text('Reset Markers'),
              icon: Icon(Icons.settings_backup_restore),
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: cameraPosition == null
            ? Center(child: Text("Fetching Location..."))
            : getMap());
  }

  Future<bool> isLocationEnabled() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    bool res = await geolocator.isLocationServiceEnabled();
    return res;
  }

  void handleTap(LatLng point) {
    Marker m = Marker(
      markerId: MarkerId(point.toString()),
      position: point,
      infoWindow: InfoWindow(
        title: 'I am a marker',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
    Set allMarkers = this.markers;
    allMarkers.add(m);
    this.setState(() {
      markers = allMarkers;
    });
  }

  void removeAllMarkers() async {
    this.setState(() {
      markers = {};
    });
  }

  void showArea() {
    myPolygon().forEach((f) {
      
      var area = maps_toolkit.SphericalUtil.computeArea(getLatLng(f.points));
      var areaInAcres = (area * 0.000247105).toStringAsPrecision(4);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text("Area"),
                content: Text("Area  = " + areaInAcres.toString() + " Acres"));
          });
    });
  }

  List<maps_toolkit.LatLng> getLatLng(List<LatLng> val) {
    List<maps_toolkit.LatLng> newLatLngs = [];
    val.forEach((latlng) {
      newLatLngs.add(maps_toolkit.LatLng(latlng.latitude, latlng.longitude));
    });
    return newLatLngs;
  }

  @override
  void initState() {
    super.initState();
    Future<bool> res = isLocationEnabled();
    res.then((onValue) {
      if (onValue) {
        getCurrentLocation();
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Location"),
                  content: Text(
                      "Location services not enabled. Please enable GPS and restart the app"));
            });
      }
    });
  }

  getCurrentLocation() {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;


    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      log(position.toString());
      setState(() {
        cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.4746,
        );
      });
    }).catchError((e) {
      log("error " + e);
      print(e);
    });
  }
}
