import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  RtcEngine? _engine;
  final String appId = "b44118e35a7149e3bd7a4065ac162546";

  final ValueNotifier<bool> isTalking = ValueNotifier(false);
  final ValueNotifier<String> status = ValueNotifier("OFFLINE");

  Future<void> initVoice(RtcEngineEventHandler handler) async {
    try {
      // NUCLEAR STEP: If engine exists, kill it and wait for it to die.
      if (_engine != null) {
        status.value = "PURGING ENGINE...";
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
        // Small delay to allow the native layer to clear memory
        await Future.delayed(const Duration(milliseconds: 500));
      }

      status.value = "INITIALIZING...";
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(handler);
      await _engine!.enableAudio();
      
      // Start in Muted (PTT) state
      await _engine!.muteLocalAudioStream(true);
      
      status.value = "READY";
    } catch (e) {
      status.value = "INIT_ERR: $e";
      print("❌ Init Error: $e");
    }
  }

  Future<void> joinRoom(String roomName) async {
    if (_engine == null) return;
    try {
      status.value = "ESTABLISHING UPLINK...";
      await _engine!.joinChannel(
        token: "", // ⚠️ Verify Agora Console has App Certificate DISABLED
        channelId: roomName,
        uid: 0, 
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      status.value = "JOIN_ERR: $e";
      print("❌ Join Error: $e");
    }
  }

  Future<void> setMicActive(bool active) async {
    if (_engine == null) return;
    isTalking.value = active;
    await _engine!.muteLocalAudioStream(!active);
  }

  Future<void> leaveRoom() async {
    if (_engine == null) return;
    status.value = "CLOSING UPLINK...";
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
    status.value = "OFFLINE";
  }
}

final voiceService = VoiceService();