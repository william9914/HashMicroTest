import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AttendanceMapController extends GetxController {
  final storage = GetStorage();
  String lat = "";
  String lon = "";
  double currentLocationLat = 0.0;
  double currentLocationLon = 0.0;

  List<DataSave> listAttendance = [];

  var attendanceLocation = ''.obs;
  var attendanceAddress = ''.obs;

  //-6.2572746 106.6191134
  double initialLatitude = -6.1707388;
  double initialLongitude = 106.8133555;

  Future showLocationPermissionDialog(String? title, String? content) async {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(title!.tr),
        content: Text(content!.tr),
        actions: [
          CupertinoActionSheetAction(
              onPressed: () => Get.back(),
              child: Text(
                "btn_ok".tr,
                style: TextStyle(color: Get.theme.primaryColor),
              )),
          CupertinoActionSheetAction(
              onPressed: () => Geolocator.openLocationSettings(),
              child: Text(
                "btn_open_settings".tr,
                style: TextStyle(color: Get.theme.primaryColor),
              )),
        ],
      ),
    );
  }

  Future<Position?> getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
        print('permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      showLocationPermissionDialog('txt_location_permission_permanently_denied',
          'txt_enable_location_permission');
      // await Geolocator.openAppSettings();
    }

    try {
      return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best)
          .then((position) {
        // currentPosition = position;
        return position;
      });
    } on PlatformException catch (e) {
      print(e.code);
    }

    // return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true);
  }

  @override
  void onInit() async {
    // TODO: implement onInit
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
        print('permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      showLocationPermissionDialog('txt_location_permission_permanently_denied',
          'txt_enable_location_permission');
      // await Geolocator.openAppSettings();
    }
    super.onInit();
  }
}

class DataSave {
  String? dateClock;
  String? latitude;
  String? longitude;

  DataSave({this.dateClock, this.latitude, this.longitude});
}
