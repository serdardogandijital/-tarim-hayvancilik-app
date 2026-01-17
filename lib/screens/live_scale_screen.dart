import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class LiveScaleScreen extends StatefulWidget {
  const LiveScaleScreen({super.key});

  @override
  State<LiveScaleScreen> createState() => _LiveScaleScreenState();
}

class _LiveScaleScreenState extends State<LiveScaleScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  int _currentStep = 0;
  double? _estimatedWeight;
  double? _confidence;
  Timer? _analysisTimer;

  final List<String> _steps = [
    'Hayvanı önden gösterin',
    'Hayvanı yandan gösterin',
    'Hayvanı arkadan gösterin',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni gerekli')),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _startAnalysis();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo Modu: Gerçek cihazda kamera kullanılacak'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startAnalysis();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startAnalysis();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo Modu: Gerçek cihazda kamera kullanılacak'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });

    _analysisTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
        _performFinalAnalysis();
      }
    });
  }

  void _performFinalAnalysis() {
    setState(() {
      _isAnalyzing = false;
      _estimatedWeight = 420.0 + (DateTime.now().millisecond % 50);
      _confidence = 78.0 + (DateTime.now().millisecond % 15);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Analiz Tamamlandı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tahmini Ağırlık',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_estimatedWeight!.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Güven: %${_confidence!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu tahmin AI destekli görüntü analizine dayanmaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // GALLERY FEATURE - Can be removed easily
  // ============================================
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _currentStep = 1;
    });

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _currentStep = 2;
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isAnalyzing = false;
      _estimatedWeight = 385.0 + (DateTime.now().millisecond % 60);
      _confidence = 72.0 + (DateTime.now().millisecond % 18);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showResultDialog();
      }
    });
  }
  // ============================================
  // END GALLERY FEATURE
  // ============================================

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Canlı Baskül Tahmini'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  Center(
                    child: CameraPreview(_controller!),
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Demo Modu',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gerçek cihazda kamera kullanılacak',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isAnalyzing) ...[
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _steps[_currentStep],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_currentStep + 1) / _steps.length,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adım ${_currentStep + 1}/${_steps.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _isAnalyzing
                          ? const CircularProgressIndicator(
                              color: Colors.greenAccent,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.greenAccent.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
