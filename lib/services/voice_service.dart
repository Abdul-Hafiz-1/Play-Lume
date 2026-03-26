import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  RtcEngine? _engine;
  final String appId = "b44118e35a7149e3bd7a4065ac162546";

  final ValueNotifier<bool> isTalking = ValueNotifier(false);
  final ValueNotifier<String> status = ValueNotifier("OFFLINE");

  // This helper function handles the speaker safely
  Future<void> _enableSpeakerSafe() async {
    try {
      if (_engine != null) {
        await _engine!.setEnableSpeakerphone(true);
      }
    } catch (e) {
      debugPrint("Speaker toggle skipped: $e");
    }
  }

  Future<void> initVoice(RtcEngineEventHandler handler) async {
    try {
      if (_engine != null) {
        status.value = "PURGING ENGINE...";
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
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
      
      // Call speaker fix with a tiny delay so it doesn't block the init process
      Future.delayed(const Duration(milliseconds: 100), () => _enableSpeakerSafe());
      
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
      
      await _enableSpeakerSafe();

      await _engine!.joinChannel(
        token: "", 
        channelId: roomName,
        uid: 0, 
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      // Force it again after the connection is stable
      Future.delayed(const Duration(milliseconds: 500), () => _enableSpeakerSafe());

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