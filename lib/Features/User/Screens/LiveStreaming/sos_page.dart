import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/session_controller.dart';
import 'package:public_emergency_app/Features/User/Screens/LiveStreaming/audienceJoinPage.dart';
import '../../Controllers/message_sending.dart';
import 'live_stream.dart';

class LiveStreamUser extends StatefulWidget {
  const LiveStreamUser({Key? key}) : super(key: key);

  @override
  State<LiveStreamUser> createState() => _LiveStreamUserState();
}

final idController = TextEditingController();
final sessionController = Get.put(SessionController());
final smsController = Get.put(messageController());
final liveStreamId = sessionController.userid.toString();

class _LiveStreamUserState extends State<LiveStreamUser> {
  @override
  void initState() {
    super.initState();
    smsController.handleLocationPermission();

    // smsController.sendLocationViaSMS("SOS BUTTON PRESSED");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(Get.height * 0.12),
            child: Container(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                          image: const AssetImage(
                              "assets/logos/emergencyAppLogo.png"),
                          height: Get.height * 0.1),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SOS",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: Get.width * 0.8,
                height: Get.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () async {
                    //save Current location to database
                    smsController.sendLocationViaSMS("SOS BUTTON PRESSED");
                    saveCurrentLocation().whenComplete(() {
                      //   jumpToLiveStream(
                      //       sessionController.userid.toString(), true);
                    });
                    jumpToLiveStream(liveStreamId, true);
                  },
                  child: const Text("SOS", style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: Get.width * 0.8,
                height: Get.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    showLiveStreamIdInputDialog(context);
                  },
                  child: const Text(
                    "Join as Viewer",
                    style: TextStyle(fontSize: 38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showLiveStreamIdInputDialog(BuildContext context) {
    String liveStreamId = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Live Stream ID"),
          content: TextFormField(
            onChanged: (value) {
              liveStreamId = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Handle joining as an audience with the provided liveStreamId
                if (liveStreamId.isNotEmpty) {
                  Navigator.of(context).pop();
                  joinLiveStreamAsAudience(liveStreamId);
                } else {
                  // Show an error message if the liveStreamId is empty
                  // You can use a Snackbar or any other method for error handling
                }
              },
              child: const Text("Join"),
            ),
          ],
        );
      },
    );
  }

  void joinLiveStreamAsAudience(String liveStreamId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudienceJoinPage(
          liveId: liveStreamId,
        ),
      ),
    );
  }

  saveCurrentLocation() async {
    //adding in try catch

    //save Current location to database
    String videoId = liveStreamId;
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref("sos/${user!.uid.toString()}");
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) async {
      await placemarkFromCoordinates(position.latitude, position.longitude)
          .then((List<Placemark> placemarks) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        ref.set({
          "time":
              "${DateTime.now().hour}:${DateTime.now().minute} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
          "address": address,
          "email": user?.email.toString(),
          "lat": position.latitude.toString(),
          "long": position.longitude.toString(),
          "videoId": user!.uid.toString(),
          "liveId": liveStreamId,
        });
      });
    });
  }

  jumpToLiveStream(String liveId, bool isHost) {
    if (liveId.isNotEmpty) {
      Get.to(
        () => LiveStreamingPage(
          liveId: liveId,
          isHost: isHost,
        ),
      );
    } else {
      Get.snackbar("Error", "Please enter a valid ID");
    }
  }
}
