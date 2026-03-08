import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart'; 
import 'package:flutter/services.dart'; 
import 'dart:async';
import 'dart:io';

class DontGetCaughtScreen extends StatefulWidget {
  final List<String> players;
  const DontGetCaughtScreen({super.key, required this.players});

  @override
  State<DontGetCaughtScreen> createState() => _DontGetCaughtScreenState();
}

class _DontGetCaughtScreenState extends State<DontGetCaughtScreen> {
  String _gamePhase = 'setup'; 
  int _totalRounds = 1;
  int _currentRound = 1;
  String _mode = 'time'; 
  double _limit = 15; // RESTORED: Default limit [cite: 2026-03-02]

  String? _seeker;
  Map<String, int> _totalCaughtCounts = {}; 

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isTakingPhoto = false;

  List<XFile> _capturedImages = [];
  Timer? _timer;
  int _timeLeft = 0;

  int _currentReviewIndex = 0;
  List<String> _currentlySelectedInPhoto = [];

  @override
  void initState() {
    super.initState();
    _totalRounds = widget.players.length; 
    if (widget.players.isNotEmpty) {
      _seeker = widget.players.first;
    }
    for (var player in widget.players) {
      _totalCaughtCounts[player] = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _setupNextRound() {
    int seekerIndex = (_currentRound - 1) % widget.players.length;
    setState(() {
      _seeker = widget.players[seekerIndex];
      _capturedImages.clear();
      _gamePhase = 'round_setup';
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(_cameras![0], ResolutionPreset.medium, enableAudio: false);
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
          _gamePhase = 'capturing';
        });
        if (_mode == 'time') {
          _timeLeft = _limit.toInt();
          _startTimer();
        }
      }
    } catch (e) {
      _showError("Failed to initialize camera: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _finishCapturing();
        }
      });
    });
  }

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || _cameraController == null || _isTakingPhoto) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() => _isTakingPhoto = true);
    try {
      XFile file = await _cameraController!.takePicture();
      setState(() {
        _capturedImages.add(file);
      });
      if (_mode == 'pics' && _capturedImages.length >= _limit.toInt()) {
        _finishCapturing();
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isTakingPhoto = false);
    }
  }

  void _finishCapturing() {
    _timer?.cancel();
    _cameraController?.dispose();
    setState(() {
      _isCameraInitialized = false;
      if (_capturedImages.isEmpty) {
        _gamePhase = 'round_results'; 
      } else {
        _gamePhase = 'review';
        _currentReviewIndex = 0;
        _currentlySelectedInPhoto = [];
      }
    });
  }

  Future<void> _downloadCurrentPhoto() async {
    try {
      bool hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);
      String path = _capturedImages[_currentReviewIndex].path;
      await Gal.putImage(path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo saved!"), backgroundColor: Color(0xFF00FF88)));
    } catch (e) {
      _showError("Failed: $e");
    }
  }

  void _saveReviewAndNext() {
    for (String player in _currentlySelectedInPhoto) {
      _totalCaughtCounts[player] = (_totalCaughtCounts[player] ?? 0) + 1;
    }
    setState(() {
      if (_currentReviewIndex < _capturedImages.length - 1) {
        _currentReviewIndex++;
        _currentlySelectedInPhoto = [];
      } else {
        _gamePhase = 'round_results';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Don't Get Caught"), automaticallyImplyLeading: _gamePhase == 'setup'),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(-0.8, -0.6), radius: 1.2, colors: [Color(0xFF162252), Color(0xFF04060E)], stops: [0.0, 1.0]),
        ),
        child: SafeArea(child: Padding(padding: const EdgeInsets.all(20.0), child: _buildCurrentPhase())),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_gamePhase) {
      case 'setup': return _buildSetupPhase();
      case 'round_setup': return _buildRoundSetupPhase();
      case 'capturing': return _buildCapturePhase();
      case 'review': return _buildReviewPhase();
      case 'round_results': return _buildRoundResultsPhase();
      case 'final_results': return _buildFinalResultsPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildSetupPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("GAME PARAMETERS", style: TextStyle(color: Color(0xFF8E95A3), letterSpacing: 2, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 30),
        
        // Mode Selection
        Row(
          children: [
            Expanded(child: _modeTile('time', Icons.timer, "Time Attack")),
            const SizedBox(width: 12),
            Expanded(child: _modeTile('pics', Icons.photo_camera, "Photo Limit")),
          ],
        ),
        const SizedBox(height: 30),

        // RESTORED: Limit Slider [cite: 2026-03-02]
        Text(_mode == 'time' ? "Time Limit: ${_limit.toInt()}s" : "Photo Limit: ${_limit.toInt()} pics", 
             style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          value: _limit, min: 5, max: 60, divisions: 11,
          activeColor: const Color(0xFF3B82F6),
          onChanged: (val) => setState(() => _limit = val),
        ),

        const SizedBox(height: 20),
        Text("Total Rounds: $_totalRounds", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          value: _totalRounds.toDouble(), min: 1, max: (widget.players.length * 2).toDouble(),
          activeColor: const Color(0xFF00FF88),
          onChanged: (val) => setState(() => _totalRounds = val.toInt()),
        ),

        const Spacer(),
        ElevatedButton(onPressed: _setupNextRound, child: const Text('Confirm Settings')),
      ],
    );
  }

  Widget _modeTile(String mode, IconData icon, String label) {
    bool isSel = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() { _mode = mode; _limit = mode == 'time' ? 15 : 10; }),
      child: Card(
        color: isSel ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFF0E1329),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF1F2947))),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Icon(icon, color: isSel ? Colors.white : Colors.white38), const SizedBox(height: 8), Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.white38))])),
      ),
    );
  }

  Widget _buildRoundSetupPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.blind, size: 80, color: Color(0xFF3B82F6)),
        const SizedBox(height: 24),
        Text("ROUND $_currentRound: $_seeker", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("Seeker: Put on your blindfold now. \n\nEveryone else: Hide!", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E95A3))),
        ),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _initCamera, child: const Text("Blindfold On - Start!")),
      ],
    );
  }

  Widget _buildCapturePhase() {
    if (!_isCameraInitialized || _cameraController == null) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: CameraPreview(_cameraController!))),
        // FULL SCREEN GESTURE DETECTOR [cite: 2026-03-02]
        Positioned.fill(
          child: GestureDetector(
            onTap: _takePhoto,
            child: Container(
              color: Colors.black.withOpacity(0.01), // Capture taps across screen
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(_mode == 'time' ? "TIME: $_timeLeft" : "PHOTOS: ${_capturedImages.length}/${_limit.toInt()}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPhase() {
    XFile currentImage = _capturedImages[_currentReviewIndex];
    List<String> targets = widget.players.where((p) => p != _seeker).toList();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Review ${_currentReviewIndex + 1}/${_capturedImages.length}"),
            IconButton(icon: const Icon(Icons.download, color: Color(0xFF00FF88)), onPressed: _downloadCurrentPhoto),
          ],
        ),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(currentImage.path), fit: BoxFit.cover))),
        const SizedBox(height: 10),
        const Text("Who was caught?"),
        Wrap(spacing: 8, children: targets.map((p) => FilterChip(label: Text(p), selected: _currentlySelectedInPhoto.contains(p), onSelected: (s) => setState(() => s ? _currentlySelectedInPhoto.add(p) : _currentlySelectedInPhoto.remove(p)))).toList()),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _saveReviewAndNext, child: const Text("Next Photo")),
      ],
    );
  }

  Widget _buildRoundResultsPhase() {
    return Column(
      children: [
        const Text("ROUND COMPLETE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        _buildLeaderboard(),
        ElevatedButton(onPressed: () { if (_currentRound < _totalRounds) { _currentRound++; _setupNextRound(); } else { setState(() => _gamePhase = 'final_results'); } }, child: const Text("Continue")),
      ],
    );
  }

  Widget _buildFinalResultsPhase() {
    return Column(
      children: [
        const Text("FINAL STANDINGS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        _buildLeaderboard(),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Return to HQ")),
      ],
    );
  }

  Widget _buildLeaderboard() {
    List<MapEntry<String, int>> sorted = _totalCaughtCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Expanded(child: ListView(children: sorted.map((e) => Card(color: const Color(0xFF0E1329), child: ListTile(title: Text(e.key, style: const TextStyle(color: Colors.white)), trailing: Text("${e.value} Caught", style: const TextStyle(color: Color(0xFF3B82F6)))))).toList()));
  }
}