import '../widgets/analysis_credits_card.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/livestock_ml_service.dart';

class LiveScaleScreen extends StatefulWidget {
  const LiveScaleScreen({super.key});

  @override
  State<LiveScaleScreen> createState() => _LiveScaleScreenState();
}

class _LiveScaleScreenState extends State<LiveScaleScreen> {
  CameraController? _controller;
  final LivestockMLService _mlService = LivestockMLService();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isCapturing = false;
  bool _showMeasurementInput = false; // Ölçüm giriş ekranı
  int _currentStep = 0;
  double? _estimatedWeight;
  double? _formulaWeight;
  String? _bodyCondition;
  String? _animalType;
  String? _breed;
  final List<XFile> _capturedImages = [];

  final List<String> _steps = [
    'Hayvanı ÖNDEN çekin',
    'Hayvanı YANDAN çekin',
    'Hayvanı ARKADAN çekin',
  ];

  final List<IconData> _stepIcons = [
    Icons.arrow_upward,
    Icons.arrow_forward,
    Icons.arrow_downward,
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kamera izni gerekli')));
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera bulunamadı'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _mlService.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      _capturedImages.add(image);

      if (_currentStep < _steps.length - 1) {
        // Sonraki adıma geç
        setState(() {
          _currentStep++;
          _isCapturing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fotoğraf ${_capturedImages.length}/3 çekildi'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 3 fotoğraf tamamlandı, ölçüm giriş ekranını göster
        setState(() {
          _isCapturing = false;
          _showMeasurementInput = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 3 fotoğraf çekildi! Şimdi ölçüleri girin'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf çekme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performFinalAnalysis() async {
    if (_isAnalyzing) return;
    // Önce formül ile hesapla
    final formulaW = _calculateFormulaWeight();

    setState(() {
      _isAnalyzing = true;
      _showMeasurementInput = false;
      _formulaWeight = formulaW;
    });

    try {
      Map<String, dynamic>? aiResult;

      // Fotoğraf varsa AI analizi yap - HER ZAMAN yap
      if (_capturedImages.isNotEmpty) {
        try {
          aiResult = await _mlService.analyzeImages(
            _capturedImages.map((image) => File(image.path)).toList(),
            chestCircumferenceCm: double.tryParse(
              _chestController.text.replaceAll(',', '.'),
            ),
            bodyLengthCm: double.tryParse(
              _lengthController.text.replaceAll(',', '.'),
            ),
          );

          if (!mounted) return;
          // Hayvan bulunamadı hatası kontrolü
          if (aiResult.containsKey('error') &&
              (aiResult['error'] != 'analysis_failed' ||
                  _formulaWeight == null)) {
            setState(() {
              _isAnalyzing = false;
              _showMeasurementInput = true;
            });
            if (aiResult['error'] == 'no_credits') {
              await showCreditsDialog(context);
              return;
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '❌ ${aiResult['message'] ?? 'Fotoğrafta sığır bulunamadı'}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          print('AI analiz hatası: $e');
        }
      }

      if (!mounted) return;
      // Girilmiş gerçek ölçüleri, görsel tahminle karıştırma.
      double finalWeight;

      if (_formulaWeight != null) {
        // Sadece formül
        finalWeight = _formulaWeight!;
      } else if (aiResult != null && aiResult.containsKey('weight')) {
        // Sadece AI
        finalWeight = (aiResult['weight'] as num).toDouble();
      } else {
        // Hiçbiri yoksa hata göster
        setState(() {
          _isAnalyzing = false;
          _showMeasurementInput = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Analiz yapılamadı. Lütfen ölçüleri girin veya tekrar deneyin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _estimatedWeight = finalWeight;
        _bodyCondition = aiResult?['conditionScore'] ?? 'Değerlendirilemedi';
        _animalType = aiResult?['animalType'] ?? 'Sığır';
        _breed = aiResult?['breed'] ?? 'Bilinmiyor';
      });

      // Hemen göster - delay kaldırıldı
      if (mounted) {
        _showResultDialog();
      }
    } catch (e) {
      if (!mounted) return;
      // Hata olsa bile formül sonucu varsa göster
      if (_formulaWeight != null) {
        setState(() {
          _isAnalyzing = false;
          _estimatedWeight = _formulaWeight;
          _bodyCondition = 'Değerlendirilemedi';
          _animalType = 'Sığır';
          _breed = 'Bilinmiyor';
        });
        if (mounted) {
          _showResultDialog();
        }
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _estimatedWeight = null;
        _showMeasurementInput = true;
        _bodyCondition = 'Değerlendirilemedi';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Analiz tamamlanamadı. Ölçüleri kontrol edip tekrar deneyin.',
            ),
          ),
        );
      }
    }
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
            const Expanded(child: Text('Analiz Tamamlandı')),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_estimatedWeight?.toStringAsFixed(0) ?? "0"} kg',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_bodyCondition != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _bodyCondition!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Yaklaşık tahmin • Tartı ile doğrulayın',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_animalType != null || _breed != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (_animalType != null)
                      Column(
                        children: [
                          Icon(Icons.pets, size: 20, color: Colors.blue[700]),
                          const SizedBox(height: 4),
                          Text(
                            _animalType!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    if (_breed != null)
                      Column(
                        children: [
                          Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _breed!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _formulaWeight != null
                  ? 'Girdiğiniz ölçülerden hesaplanan yaklaşık ağırlık.'
                  : 'Üç açıdan görsel tahmin; ölçek bilgisi yok. Tartı ile doğrulayın.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showShareScreen();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showShareScreen() {
    // En iyi fotoğrafı seç (yandan çekilmiş)
    String? bestImagePath;
    if (_capturedImages.isNotEmpty) {
      bestImagePath = _capturedImages.length > 1
          ? _capturedImages[1].path
          : _capturedImages[0].path;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _ShareScreen(
        weight: _estimatedWeight ?? 0,
        breed: _breed ?? 'Bilinmiyor',
        condition: _bodyCondition ?? 'Değerlendirilemedi',
        imagePath: bestImagePath,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _resetCapture() {
    setState(() {
      _capturedImages.clear();
      _currentStep = 0;
      _estimatedWeight = null;
      _formulaWeight = null;
      _bodyCondition = null;
      _animalType = null;
      _breed = null;
      _showMeasurementInput = false;
      _chestController.clear();
      _lengthController.clear();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _mlService.dispose();
    _chestController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  // Schaeffer formülü ile ağırlık hesaplama
  double? _calculateFormulaWeight() {
    final chest = double.tryParse(_chestController.text.replaceAll(',', '.'));
    final length = double.tryParse(_lengthController.text.replaceAll(',', '.'));

    if (chest == null ||
        length == null ||
        !chest.isFinite ||
        !length.isFinite ||
        chest <= 0 ||
        length <= 0 ||
        chest > 500 ||
        length > 500) {
      return null;
    }

    // Schaeffer formülü: (Göğüs çevresi² × Vücut uzunluğu) / 10800
    final weight = (chest * chest * length) / 10800;
    return weight;
  }

  Widget _buildMeasurementInputScreen() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başarı mesajı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3 Fotoğraf Çekildi!',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Üç açı birlikte analiz edilir. Mezura ölçüsü ekleyebilirsiniz.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Çekilen fotoğraflar önizleme
              SizedBox(
                height: 80,
                child: Row(
                  children: _capturedImages.asMap().entries.map((entry) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(entry.value.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Ölçüm girişi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          color: Colors.green[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ölçüm Girin',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Doğru ağırlık tahmini için ölçüleri girin',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Göğüs çevresi
                    TextField(
                      controller: _chestController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Göğüs Çevresi',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        hintText: 'Örn: 180',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        suffixText: 'cm',
                        suffixStyle: const TextStyle(color: Colors.green),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vücut uzunluğu
                    TextField(
                      controller: _lengthController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Vücut Uzunluğu',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        hintText: 'Örn: 150',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        suffixText: 'cm',
                        suffixStyle: const TextStyle(color: Colors.green),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.straighten,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ölçüm açıklaması
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[300],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nasıl Ölçülür?',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Göğüs Çevresi: Ön bacakların hemen arkasından çevre ölçümü\n• Vücut Uzunluğu: Omuz noktasından kuyruk kökünün başlangıcına',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Hesapla butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _performFinalAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Ağırlık Hesapla',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Ölçüm olmadan devam et
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _chestController.clear();
                    _lengthController.clear();
                    _performFinalAnalysis();
                  },
                  child: Text(
                    'Ölçüm girmeden sadece AI ile tahmin et',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Canlı Baskül'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Analiz hakları',
            onPressed: _isAnalyzing ? null : () => showCreditsDialog(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
          if (_capturedImages.isNotEmpty || _showMeasurementInput)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetCapture,
              tooltip: 'Yeniden Başla',
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Kamera hazırlanıyor...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _showMeasurementInput
          ? _buildMeasurementInputScreen()
          : _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.greenAccent),
                  const SizedBox(height: 24),
                  const Text(
                    'AI Analiz Yapılıyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ChatGPT Vision ile ağırlık tahmin ediliyor',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Kamera önizleme
                if (_controller != null && _controller!.value.isInitialized)
                  Positioned.fill(child: CameraPreview(_controller!))
                else
                  Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Text(
                        'Kamera bulunamadı',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),

                // Üst bilgi paneli
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _stepIcons[_currentStep],
                              color: Colors.greenAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _steps[_currentStep],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aynı hayvanı düz zeminde, gövdesi ve ayakları tam görünecek şekilde çekin. Yaklaşmadan güvenli mesafeyi koruyun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        // İlerleme göstergesi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final isCaptured = index < _capturedImages.length;
                            final isCurrent = index == _currentStep;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCaptured
                                    ? Colors.green
                                    : (isCurrent
                                          ? Colors.greenAccent.withOpacity(0.3)
                                          : Colors.grey[800]),
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrent
                                    ? Border.all(
                                        color: Colors.greenAccent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: isCaptured
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Colors.greenAccent
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fotoğraf ${_capturedImages.length}/3',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Alt çekim butonu
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capturePhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.grey : Colors.white,
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCapturing
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  size: 36,
                                  color: Colors.green[700],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Çekim talimatı
                Positioned(
                  bottom: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Butona basarak fotoğraf çekin',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Sosyal Medya Paylaşım Ekranı
class _ShareScreen extends StatefulWidget {
  final double weight;
  final String breed;
  final String condition;
  final String? imagePath;
  final VoidCallback onClose;

  const _ShareScreen({
    required this.weight,
    required this.breed,
    required this.condition,
    this.imagePath,
    required this.onClose,
  });

  @override
  State<_ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<_ShareScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareToSocialMedia(String platform) async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Paylaşım kartını resme çevir
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Kart bulunamadı');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Geçici dosyaya kaydet
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/th_takvim_hayvan_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      // Önce loading'i kapat
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }

      // Paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🐄 Hayvanımın yaklaşık ağırlığı: ${widget.weight.toStringAsFixed(0)} kg\n\n📱 Çiftçi+ ile tahmin edildi. Tartı ile doğrulanmalıdır.\n#THtakvim #hayvancılık #çiftçi',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.share, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sosyal Medyada Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Paylaşım kartı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _shareCardKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[700]!, Colors.green[900]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Logo ve başlık
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'TH Takvim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Hayvan fotoğrafı
                          if (widget.imagePath != null &&
                              File(widget.imagePath!).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(widget.imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.pets,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Ağırlık
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Tahmini Ağırlık',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${widget.weight.toStringAsFixed(0)} kg',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Watermark - şık tasarım
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'TH Takvim',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'App Store & Google Play\'den indirin',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hayvanınızın Yaklaşık Ağırlığını Hesaplayın',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sosyal medya butonları
                  const Text(
                    'Paylaşmak için bir platform seçin',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 16),

                  if (_isSharing)
                    const CircularProgressIndicator(color: Colors.green)
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _shareToSocialMedia('whatsapp'),
                        ),
                        _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          onTap: () => _shareToSocialMedia('facebook'),
                        ),
                        _buildSocialButton(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: const Color(0xFFE4405F),
                          onTap: () => _shareToSocialMedia('instagram'),
                        ),
                        _buildSocialButton(
                          icon: Icons.music_note,
                          label: 'TikTok',
                          color: const Color(0xFF000000),
                          onTap: () => _shareToSocialMedia('tiktok'),
                        ),
                        _buildSocialButton(
                          icon: Icons.share,
                          label: 'Diğer',
                          color: Colors.grey[700]!,
                          onTap: () => _shareToSocialMedia('other'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Ana sayfaya dön butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ana Sayfaya Dön'),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
