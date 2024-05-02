import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../controller/attendance_controller.dart';

class AttendanceView extends StatefulWidget {
  final Function(CameraPosition position) onCameraChange;

  const AttendanceView({Key? key, required this.onCameraChange})
      : super(key: key);

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final controller = Get.put(AttendanceMapController());
  var hasLocationPermission = false.obs;
  String? address;
  String fullAddress = "";
  final Set<Marker> markers = {};
  LocationPermission permission =
      LocationPermission.denied; //initial permission status
  var isGpsEnabled = false.obs; //initial permission status
  LatLng initPosition =
      LatLng(0, 0); //initial Position cannot assign null values
  LatLng currentLatLng =
      LatLng(21.192572, 72.799736); //initial Position cannot assign null values
  Completer<GoogleMapController> completer = Completer();
  var addressController = TextEditingController();
  var filterController = TextEditingController();
  var notesController = TextEditingController();
  GoogleMapController? googleMapController;
  double distanceInKiloMeters = 0.0;
  bool markerButton = false;
  DateFormat formattedDate = DateFormat('dd/MM/yyyy HH:mm');

  double rangeRadius = 50.0;

  bool checkAreaCurrent = false;
  bool checkArea = false;

  @override
  void initState() {
    checkPermission().then((value) {
      print('location permisson $value');
      hasLocationPermission.value = value;
    });
    getCurrentUserLocation();

    super.initState();
  }

  Future<bool> geoFencingCheckingCurrentLoc() async {
    double e = controller.initialLatitude * (math.pi / 180);
    double f = controller.initialLongitude * (math.pi / 180);
    double g = controller.currentLocationLat * (math.pi / 180);
    double h = controller.currentLocationLon * (math.pi / 180);

    double i = (math.cos(e) * math.cos(g) * math.cos(f) * math.cos(h) +
        math.cos(e) * math.sin(f) * math.cos(g) * math.sin(h) +
        math.sin(e) * math.sin(g));

    double j = math.acos(i);
    dynamic value = (6371 * j);
    bool isInFence = value > rangeRadius * 0.001 ? false : true;
    print('CHECK DATA FENCE = ${isInFence}');
    checkArea = isInFence;
    checkAreaCurrent = isInFence;

    return isInFence;
  }

  Future<bool> geoFencingChecking() async {
    double e = controller.initialLatitude * (math.pi / 180);
    double f = controller.initialLongitude * (math.pi / 180);
    double g = currentLatLng.latitude * (math.pi / 180);
    double h = currentLatLng.longitude * (math.pi / 180);

    double i = (math.cos(e) * math.cos(g) * math.cos(f) * math.cos(h) +
        math.cos(e) * math.sin(f) * math.cos(g) * math.sin(h) +
        math.sin(e) * math.sin(g));

    double j = math.acos(i);
    dynamic value = (6371 * j);
    bool isInFence = value > rangeRadius * 0.001 ? false : true;
    print('CHECK DATA FENCE = ${isInFence}');
    checkArea = isInFence;

    return isInFence;
  }

  Future<bool> checkPermission() async {
    await Geolocator.requestPermission();
    var isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    // permission = await Geo locator.checkPermission();
    if (!isGpsEnabled) {
      await Geolocator.requestPermission();
      var isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Location permissions are denied'),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Get.back();
                  },
                )
              ],
            );
          },
        );
        return false;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    completer.complete(controller);
  }

  Future getCurrentUserLocation() async {
    Geolocator.getCurrentPosition().then((value) async {
      print('Location User : ${value.latitude} ${value.longitude}');
      controller.currentLocationLat = value.latitude;
      controller.currentLocationLon = value.longitude;
      googleMapController = await completer.future;
      googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(controller.initialLatitude, controller.initialLongitude), 18));
    });
  }

  onCameraChange(CameraPosition position) {
    setState(() {
      currentLatLng = position.target;
    });
    widget.onCameraChange(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geo Tag Attendance'),
      ),
      body: Column(
        children: [
          Container(
            height: 400,
            child: GoogleMap(
              gestureRecognizers: Set()
                ..add(Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer())),
              onMapCreated: _onMapCreated,
              // myLocationButtonEnabled: true,
              initialCameraPosition: CameraPosition(
                target: initPosition,
                zoom: 2,
              ),
              onCameraIdle: () async {
                // googleMapController.isMarkerInfoWindowShown(MarkerId('google_plex')).then((value) {
                //   googleMapController.showMarkerInfoWindow(MarkerId('google_plex'));
                // });
                var placemarks = await placemarkFromCoordinates(
                    currentLatLng.latitude, currentLatLng.longitude);
                print('placemarks $placemarks');
                setState(() {
                  address =
                      "${placemarks[0].locality ?? placemarks[0].subAdministrativeArea}, ${placemarks.first.country} - ${placemarks.first.postalCode}";
                  // AddMarker();
                  fullAddress =
                      "${placemarks[0].thoroughfare ?? placemarks[0].name}, ${placemarks[0].locality}, ${placemarks[0].subAdministrativeArea}, ${placemarks[0].administrativeArea}, ${placemarks.first.country}, ${placemarks.first.postalCode}";
                  geoFencingCheckingCurrentLoc();
                  geoFencingChecking();
                });
                if (placemarks.isNotEmpty) {
                  Future.delayed(
                      Duration.zero,
                      () => googleMapController!.showMarkerInfoWindow(
                            const MarkerId("location"),
                          ));
                  // googleMapController!.showMarkerInfoWindow(MarkerId("location"),);
                }
              },
              onCameraMove: onCameraChange,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              circles: Set.from(
                [
                  Circle(
                    circleId: CircleId('currentCircle'),
                    center: LatLng(controller.initialLatitude,
                        controller.initialLongitude),
                    radius: 50,
                    fillColor: Colors.blue.withOpacity(0.5),
                    strokeColor: Colors.blue.withOpacity(0.1),
                  ),
                ],
              ),
              markers: {
                Marker(
                    icon: BitmapDescriptor.defaultMarker,
                    markerId: const MarkerId('location'),
                    position: currentLatLng,
                    infoWindow: InfoWindow(
                      title: address,
                      // snippet: 'Enjoy',
                    )),
              },
            ),
          ),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: address == '' || address == null
                  ? Text('')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.toString(),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          fullAddress,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.normal),
                        ),
                      ],
                    )),
          Visibility(
              visible: controller.listAttendance.length != 0,
              child: SingleChildScrollView(
                child: Column(
                  children:
                      List.generate(controller.listAttendance.length, (index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clock In'),
                          Row(
                            children: [
                              Text(
                                '${controller.listAttendance[index].dateClock}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Spacer(),
                              Text(
                                '${controller.listAttendance[index].latitude}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Spacer(),
                              Text(
                                '${controller.listAttendance[index].longitude}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      ),
                    );
                  }),
                ),
              )),
        ],
      ),
      bottomSheet: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (checkAreaCurrent == false) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Center(child: Text('you are out of radius')),
                        );
                      },
                    );
                  } else {
                    controller.lat = "";
                    controller.lon = "";
                    controller.lat = currentLatLng.latitude.toString();
                    controller.lon = currentLatLng.longitude.toString();
                    // Get.back();
                    print('map ${controller.lat},${controller.lon}');
                    controller.listAttendance.add(DataSave(
                      dateClock: formattedDate.format(DateTime.now()),
                      latitude: controller.lat,
                      longitude: controller.lon,
                    ));
                    setState(() {});
                  }
                  // Get.back();
                },
                child: Container(
                    height: 40,
                    width: 150,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.lightBlue),
                    child: Center(
                        child: Text(
                      'Save By Current Location',
                      textAlign: TextAlign.center,
                    ))),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  if (checkArea == false) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Center(child: Text('you are out of radius')),
                        );
                      },
                    );
                  } else {
                    controller.lat = "";
                    controller.lon = "";
                    controller.lat = currentLatLng.latitude.toString();
                    controller.lon = currentLatLng.longitude.toString();
                    // Get.back();
                    print('map ${controller.lat},${controller.lon}');
                    controller.listAttendance.add(DataSave(
                      dateClock: formattedDate.format(DateTime.now()),
                      latitude: controller.lat,
                      longitude: controller.lon,
                    ));
                    setState(() {});
                  }
                },
                child: Container(
                    height: 40,
                    width: 150,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.lightBlue),
                    child: Center(child: Text('Save By Marker'))),
              ),
            ],
          )),
    );
  }
}
