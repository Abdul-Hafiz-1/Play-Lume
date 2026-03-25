import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_service.dart';

final voiceService = VoiceService();

class PTTButton extends StatefulWidget {
  final Function(bool isTalking) onChanged;
  const PTTButton({super.key, required this.onChanged});

  @override
  State<PTTButton> createState() => _PTTButtonState();
}

class _PTTButtonState extends State<PTTButton> {
  bool _isPressed = false;
  Offset _position = const Offset(100, 100); // Initial position

  // Inside _PTTButtonState's _updateTalking method
void _updateTalking(bool talking) {
  if (_isPressed == talking) return;
  setState(() => _isPressed = talking);
  
  // 🔥 ACTIVATE AGORA MIC
  voiceService.setMicActive(talking); 
  
  HapticFeedback.lightImpact();
  if (talking) HapticFeedback.vibrate(); // Feel the "Mic On"
}

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(), // Capture spacebar
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _updateTalking(event is KeyDownEvent);
          }
        },
        child: Draggable(
          feedback: _buildButton(true),
          childWhenDragging: const SizedBox.shrink(),
          onDragEnd: (details) => setState(() => _position = details.offset),
          child: GestureDetector(
            onLongPressStart: (_) => _updateTalking(true),
            onLongPressEnd: (_) => _updateTalking(false),
            child: _buildButton(false),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(bool isDragging) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? Colors.redAccent : Colors.blueAccent.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: _isPressed ? Colors.red.withOpacity(0.5) : Colors.black26,
              blurRadius: _isPressed ? 20 : 10,
              spreadRadius: _isPressed ? 5 : 0,
            )
          ],
        ),
        child: Icon(
          _isPressed ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}