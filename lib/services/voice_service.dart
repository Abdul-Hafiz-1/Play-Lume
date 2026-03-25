import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  RtcEngine? _engine;
  // IMPORTANT: Make sure this is YOUR App ID from the Agora console.
  final String appId = "df153a60f7e949299d202d4d968d1963"; 

  // lib/services/voice_service.dart

Future<void> initVoice(RtcEngineEventHandler handler) async {
  // If engine exists, we MUST release it to clear the -4 lock
  if (_engine != null) {
    await _engine!.release();
    _engine = null;
  }

  _engine = createAgoraRtcEngine();
  await _engine!.initialize(RtcEngineContext(
    appId: appId,
    channelProfile: ChannelProfileType.channelProfileCommunication,
  ));

  _engine!.registerEventHandler(handler);
}

Future<void> joinRoom(String roomName) async {
  if (_engine == null) return;

  // This is a mobile-only feature.
  if (!kIsWeb) {
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
  }

  // Enable audio module
  await _engine!.enableAudio();
  await _engine!.setParameters('{"che.audio.opensl":true}');
  await _engine!.adjustPlaybackSignalVolume(100);

  await _engine!.joinChannel(
    // IMPORTANT: If you have enabled tokens in your Agora project, 
    // you must generate a token on your server and pass it here.
    token: "", 
    channelId: roomName,
    uid: 0, 
    options: const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
    ),
  );
}

  // lib/services/voice_service.dart

Future<void> setMicActive(bool active) async {
  if (_engine == null) return;
  await _engine!.muteLocalAudioStream(!active);
  if (active) {
    // On web, this helps wake up the audio system
    await _engine!.adjustRecordingSignalVolume(100);
    await _engine!.adjustPlaybackSignalVolume(100);
    // Some Agora web SDKs require this to resume
    await _engine!.setParameters('{"che.audio.force_resume":true}');
  }
}

  Future<void> leaveRoom() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }
}

final voiceService = VoiceService();