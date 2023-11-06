import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Screens/LiveStreaming/sos_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Emergency Contacts/emergency_contacts_controller.dart';

// ignore: camel_case_types
class messageController extends GetxController {
  static messageController get instance => Get.find();
  final emergencyContactsController = Get.put(EmergencyContactsController());

  String? _currentAddress;
  Position? _currentPosition;
  void _sendSMS(String message, List<String> recipents) async {
    for (var i = 0; i < recipents.length; i++) {
      String _result = await BackgroundSms.sendMessage(
              //add all phone numbers in phone number list
              phoneNumber: recipents[i].toString(),
              message: message)
          .toString();
      // Get.snackbar("SMS", _result);
    }
    Get.snackbar("SMS", "Distress SMS Sent Successfully");

    print(recipents);
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Disabled",
          'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Rejected", 'Location Permissions are denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Rejected",
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  handleSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      debugPrint("SMS Permission Granted");
      return true;
    } else {
      debugPrint("SMS Permission Denied");
      return false;
    }
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();

    if (!hasPermission) {
      return Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0);
    }
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      _currentPosition = position;
      _getAddressFromLatLng(_currentPosition!);
      return _currentPosition!;
    }).catchError((e) {
      debugPrint(e);
    });
    return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      _currentAddress =
          '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> sendLocationViaSMS(String EmergencyType) async {
    await getCurrentPosition().then((_currentAddress) async {
      // ignore: unnecessary_null_comparison
      if (_currentAddress != null) {
        String message =
            "HELP me! There is an $EmergencyType \n http://www.google.com/maps/place/${_currentPosition!.latitude},${_currentPosition!.longitude}}\n Live Stream ID: $liveStreamId";
        await emergencyContactsController
            .loadData()
            .then((emergencyContacts) => _sendSMS(message, emergencyContacts));
      } else {}
    });
  }
}
