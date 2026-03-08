import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

// 1. Hide the snackbarKey from the service to resolve the ambiguity
import '../../services/firebase_service.dart' hide snackbarKey; 

// 2. Import main.dart for the global navigator and snackbar keys
import '../../main.dart'; 

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});
  
  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  late AnimationController _pulseController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the glassmorphic icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _continueToHome() async {
    final String enteredName = _nicknameController.text.trim();
    
    if (enteredName.isEmpty) {
      HapticFeedback.vibrate(); // Feedback for empty input
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(content: Text("ACCESS DENIED: Enter Nickname")),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact(); // Tactical feedback

    // Sync with Firebase
    await firebaseService.loginOrSetNickname(enteredName);
    
    if (mounted && firebaseService.isLoggedIn) {
      // SUCCESS: Pass the nickname as an argument to the home route
      Navigator.pushReplacementNamed(
        context, 
        '/home', 
        arguments: enteredName, 
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
      snackbarKey.currentState?.showSnackBar( 
        const SnackBar(content: Text("SYNC FAILED: Check connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Signature Radial Gradient
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [Color(0xFF162252), Color(0xFF04060E)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GLASSMORPHIC CONTROLLER ICON
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.05).animate(_pulseController),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded, 
                          size: 70, 
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // BRANDING
                const Text(
                  'PLAY LUME', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 42, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 4
                  ),
                ),
                const Text(
                  'INITIALIZING NEURAL LINK...', 
                  style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
                ),
                const SizedBox(height: 50),

                // GLASSMORPHIC TEXTFIELD
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _nicknameController,
                        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'IDENTIFY YOURSELF',
                          hintStyle: TextStyle(color: Colors.white12, fontSize: 14),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.security, color: Colors.white24, size: 20),
                          contentPadding: EdgeInsets.symmetric(vertical: 20),
                        ),
                        onSubmitted: (_) => _continueToHome(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : _continueToHome, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'ESTABLISH CONNECTION', 
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}