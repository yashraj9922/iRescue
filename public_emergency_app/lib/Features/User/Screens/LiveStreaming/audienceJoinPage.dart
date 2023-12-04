import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'keys.dart'; // Import your app credentials

class AudienceJoinPage extends StatelessWidget {
  final String liveId; // The live stream ID you want to join

  const AudienceJoinPage({Key? key, required this.liveId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Live Stream"),
      ),
      body: SafeArea(
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: Keys().appId,
          appSign: Keys().appSign,
          userID: Keys().userId,
          userName: "user_${Keys().userId}",
          liveID: liveId, // Pass the live stream ID you want to join
          config: ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
        ),
      ),
    );
  }
}
