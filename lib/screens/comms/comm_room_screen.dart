import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:ui';
import '../../services/voice_service.dart';
import '../../services/firebase_service.dart';

class CommRoomScreen extends StatefulWidget {
  final String roomCode;
  const CommRoomScreen({super.key, required this.roomCode});

  @override
  State<CommRoomScreen> createState() => _CommRoomScreenState();
}

class _CommRoomScreenState extends State<CommRoomScreen> {
  bool _isRoomActive = false;
  bool _isConnecting = false;

  // lib/screens/comms/comm_room_screen.dart

// lib/screens/comms/comm_room_screen.dart

Future<void> _initializeLink() async {
  setState(() => _isConnecting = true);
  
  // 🖐️ PHYSICAL GESTURE: Triggering haptic helps "prime" the browser
  HapticFeedback.mediumImpact(); 

  // --- Permission Handling ---
  if (await Permission.microphone.request().isDenied) {
    debugPrint("❌ Microphone Permission Denied.");
    if (mounted) setState(() => _isConnecting = false);
    // You should show a dialog to the user here explaining why the permission is needed.
    return;
  }

  try {
    // 1. Setup Engine & Handlers
    await voiceService.initVoice(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ Agora: Joined Successfully");
        if (mounted) {
          setState(() {
            _isRoomActive = true;
            _isConnecting = false;
          });
        }
      },
      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        if (state == RemoteAudioState.remoteAudioStateDecoding) {
          debugPrint("🔊 Receiving Audio from: $remoteUid");
        }
      },
      onError: (err, msg) {
        debugPrint("❌ Agora Error: $err");
        if (mounted) setState(() => _isConnecting = false);
      }
    ));

    // 2. JOIN AGORA IMMEDIATELY
    // Do not put 'await' for Firestore here, do Agora FIRST
    await voiceService.joinRoom(widget.roomCode);
    
    // 3. Register in Database (Background task)
    firebaseService.joinCommRoom(widget.roomCode).then((_) {
      debugPrint("✅ Firestore: Player Registered");
    });

  } catch (e) {
    debugPrint("Link Error: $e");
    if (mounted) setState(() => _isConnecting = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          _buildGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isRoomActive ? _buildDashboard() : _buildSetup(),
                  ),
                ),
                _buildBottomActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isConnecting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
  return Column(
    key: const ValueKey("dashboard"),
    children: [
      const Icon(Icons.verified_user, color: Colors.greenAccent, size: 60),
      const Text("COMMS ENCRYPTED", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
      const SizedBox(height: 30),
      Expanded(
        child: StreamBuilder(
          stream: firebaseService.getRoomStream(widget.roomCode),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("LINKING...", style: TextStyle(color: Colors.white24)));
            }

            final players = List.from(snapshot.data!.get('players') ?? []);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: players.length,
              itemBuilder: (context, i) {
                final player = players[i] as Map<String, dynamic>;
                final bool isMe = player['userId'] == firebaseService.userId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMe ? Colors.blueAccent : Colors.white10,
                    child: const Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  title: Text(player['nickname'] ?? "Unknown", style: const TextStyle(color: Colors.white)),
                  trailing: isMe ? null : const Icon(Icons.graphic_eq, color: Colors.greenAccent, size: 18),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildSetup() {
    return Column(
      key: const ValueKey("setup"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: QrImageView(data: widget.roomCode, size: 200.0),
        ),
        const SizedBox(height: 30),
        Text("${widget.roomCode.substring(0, 4)} ${widget.roomCode.substring(4, 8)}",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 8)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _isRoomActive 
      ? Row(children: [
          Expanded(child: _btn("EXIT", Colors.redAccent.withOpacity(0.1), Colors.redAccent, () {
            voiceService.leaveRoom();
            Navigator.pop(context);
          })),
          const SizedBox(width: 20),
          Expanded(child: _btn("PLAY", Colors.blueAccent, Colors.white, () {
            _showFloatingMicOverlay(context);
            Navigator.pop(context); 
          })),
        ])
      : _btn("INITIALIZE ENCRYPTED LINK", Colors.blueAccent, Colors.white, _initializeLink),
    );
  }

  Widget _btn(String label, Color color, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1))),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.all(24.0),
    child: Row(children: [
      const Icon(Icons.wifi_tethering, color: Colors.blueAccent),
      const SizedBox(width: 12),
      const Text("COMMS HQ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildLoadingOverlay() => Container(
    color: Colors.black87,
    child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
  );

  Widget _buildGlow() => Positioned(top: 100, left: 100, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 100)])));

  void _showFloatingMicOverlay(BuildContext context) {
    OverlayEntry? entry;
    Offset position = const Offset(20, 100);
    bool isTalking = false;

    entry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) {
          return Positioned(
            right: position.dx,
            bottom: position.dy,
            child: Draggable(
              feedback: _micIcon(isTalking),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                setStateOverlay(() {
                  double h = MediaQuery.of(context).size.height;
                  double w = MediaQuery.of(context).size.width;
                  position = Offset((w - details.offset.dx - 75).clamp(20, w - 100), (h - details.offset.dy - 75).clamp(20, h - 100));
                });
              },
              child: GestureDetector(
                onLongPressStart: (_) { setStateOverlay(() => isTalking = true); voiceService.setMicActive(true); },
                onLongPressEnd: (_) { setStateOverlay(() => isTalking = false); voiceService.setMicActive(false); },
                child: _micIcon(isTalking),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  Widget _micIcon(bool talking) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 75, height: 75,
        decoration: BoxDecoration(shape: BoxShape.circle, color: talking ? Colors.redAccent : Colors.blueAccent, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]),
        child: Icon(talking ? Icons.mic : Icons.mic_none, color: Colors.white, size: 30),
      ),
    );
  }
}