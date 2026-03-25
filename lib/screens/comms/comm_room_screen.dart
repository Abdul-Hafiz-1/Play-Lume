import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../services/voice_service.dart';

class CommRoomScreen extends StatefulWidget {
  final String roomCode;
  const CommRoomScreen({super.key, required this.roomCode});

  @override
  State<CommRoomScreen> createState() => _CommRoomScreenState();
}

class _CommRoomScreenState extends State<CommRoomScreen> {
  bool _isJoined = false;
  bool _loading = false;

  // The Floating Overlay Entry
  static OverlayEntry? _floatingMicEntry;

  void _showFloatingMic(BuildContext context) {
    // Prevent duplicate overlays
    _floatingMicEntry?.remove();
    
    // Starting position
    Offset position = const Offset(20, 100);

    _floatingMicEntry = OverlayEntry(
      builder: (context) => _FloatingPTT(
        initialPosition: position,
        onDispose: () => _floatingMicEntry = null,
      ),
    );

    Overlay.of(context).insert(_floatingMicEntry!);
  }

  Future<void> _connect() async {
    setState(() => _loading = true);
    await voiceService.initVoice(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() { _isJoined = true; _loading = false; });
      },
      onError: (err, msg) {
        if (mounted) setState(() => _loading = false);
      },
    ));
    await voiceService.joinRoom(widget.roomCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isJoined) ...[
              const Icon(Icons.settings_input_antenna, color: Colors.white24, size: 80),
              const SizedBox(height: 20),
              Text(widget.roomCode, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _connect,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(200, 50)),
                child: Text(_loading ? "CONNECTING..." : "ESTABLISH LINK"),
              ),
            ] else ...[
              const Icon(Icons.verified_user, color: Colors.cyanAccent, size: 80),
              const SizedBox(height: 10),
              const Text("LINK SECURE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  _showFloatingMic(context);
                  // Go back to the game lobby/screen
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                child: const Text("LAUNCH FLOATING MIC", style: TextStyle(color: Colors.black)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// Separate Widget for the Floating Draggable Button
class _FloatingPTT extends StatefulWidget {
  final Offset initialPosition;
  final VoidCallback onDispose;
  const _FloatingPTT({required this.initialPosition, required this.onDispose});

  @override
  State<_FloatingPTT> createState() => _FloatingPTTState();
}

class _FloatingPTTState extends State<_FloatingPTT> {
  late Offset pos;

  @override
  void initState() {
    super.initState();
    pos = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable(
        feedback: _micWidget(true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() => pos = details.offset);
        },
        child: GestureDetector(
          onLongPressStart: (_) {
            HapticFeedback.mediumImpact();
            voiceService.setMicActive(true);
          },
          onLongPressEnd: (_) {
            voiceService.setMicActive(false);
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: voiceService.isTalking,
            builder: (context, talking, _) => _micWidget(talking),
          ),
        ),
      ),
    );
  }

  Widget _micWidget(bool talking) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: talking ? Colors.redAccent : Colors.blueAccent.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Icon(talking ? Icons.mic : Icons.mic_none, color: Colors.white, size: 30),
      ),
    );
  }
}