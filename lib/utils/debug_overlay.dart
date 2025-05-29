import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:scalemasterguitar/utils/audio_utils.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showDebug = false;
  final Map<String, String> _debugInfo = {};
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
    
    // Refresh debug info every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_showDebug) {
        _loadDebugInfo();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDebugInfo() async {
    if (!mounted) return;
    
    final debugData = <String, String>{};
    
    // App info
    debugData['App Version'] = '1.0.8';
    debugData['Platform'] = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Other';
    debugData['Device'] = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    
    // Audio session status
    try {
      await AudioSession.instance;
      debugData['Audio Session'] = 'Initialized';
      
      debugData['Audio Player'] = AudioPlayerManager().isInitialized ? 'Initialized' : 'Not Initialized';
    } catch (e) {
      debugData['Audio Session'] = 'Error: $e';
    }
    
    // Check if sound font is loaded
    try {
      final ByteData data = await rootBundle.load('assets/sounds/sf2/FluidR3_GM.sf2');
      debugData['Sound Font'] = 'Loaded (${(data.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB)';
    } catch (e) {
      debugData['Sound Font'] = 'Not found: $e';
    }
    
    // Test audio playback
    try {
      // This is just checking if the methods are available, not actually playing
      // Create an instance to verify it's available
      AudioPlayerManager();
      debugData['Audio Methods'] = 'Available';
    } catch (e) {
      debugData['Audio Methods'] = 'Error: $e';
    }
    
    if (mounted) {
      setState(() {
        _debugInfo.clear();
        _debugInfo.addAll(debugData);
      });
    }
  }
  
  Future<void> _testAudio() async {
    try {
      final audioPlayerManager = AudioPlayerManager();
      await audioPlayerManager.playSound('assets/sounds/sf2/FluidR3_GM.sf2');
      
      if (mounted) {
        setState(() {
          _debugInfo['Audio Test'] = 'Test sound played';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugInfo['Audio Test'] = 'Failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 20,
          top: MediaQuery.of(context).padding.top + 10,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.black.withOpacity(0.5),
            child: Icon(
              _showDebug ? Icons.visibility_off : Icons.bug_report,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showDebug = !_showDebug;
                if (_showDebug) {
                  _loadDebugInfo();
                }
              });
            },
          ),
        ),
        if (_showDebug)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Debug Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Divider(color: Colors.white30),
                  ..._debugInfo.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: entry.value.contains('Error') || entry.value.contains('Not found') || entry.value.contains('Failed') 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _testAudio,
                      child: const Text('Test Audio Playback'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
