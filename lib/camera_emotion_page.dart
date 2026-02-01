import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'emotion_service.dart';

class CameraEmotionPage extends StatefulWidget {
  const CameraEmotionPage({super.key});

  @override
  State<CameraEmotionPage> createState() => _CameraEmotionPageState();
}

class _CameraEmotionPageState extends State<CameraEmotionPage> {
  CameraController? _controller;
  Future<void>? _initFuture;
  final EmotionService _emotionService = EmotionService();

  String? _lastEmotion;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initFuture = _controller!.initialize();
      await _emotionService.loadModel();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _captureEmotion() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isBusy) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      final emotion = await _emotionService.predictFromBytes(bytes);

      if (!mounted) return;

      setState(() {
        _lastEmotion = emotion;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detected emotion: $emotion')),
      );

      // Optionally return emotion back to previous page
      Navigator.pop(context, emotion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing emotion: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Emotion Detection'),
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Camera init error: ${snapshot.error}'),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: CameraPreview(_controller!),
                    ),
                    const SizedBox(height: 8),
                    if (_lastEmotion != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Last emotion: $_lastEmotion',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _captureEmotion,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture emotion'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
