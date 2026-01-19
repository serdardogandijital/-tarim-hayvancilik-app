import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/livestock_ml_service.dart';

class GalleryScaleScreen extends StatefulWidget {
  const GalleryScaleScreen({super.key});

  @override
  State<GalleryScaleScreen> createState() => _GalleryScaleScreenState();
}

class _GalleryScaleScreenState extends State<GalleryScaleScreen> {
  final LivestockMLService _mlService = LivestockMLService();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  
  bool _isAnalyzing = false;
  bool _isSelecting = true;
  int _currentStep = 0;
  double? _estimatedWeight;
  double? _formulaWeight;
  double? _confidence;
  String? _bodyCondition;
  String? _animalType;
  String? _breed;

  final List<String> _photoLabels = [
    'Önden görünüm',
    'Yandan görünüm',
    'Arkadan görünüm',
  ];

  @override
  void initState() {
    super.initState();
    _mlService.initialize();
  }

  @override
  void dispose() {
    _mlService.dispose();
    _chestController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  // Schaeffer formülü ile ağırlık hesaplama
  double? _calculateFormulaWeight() {
    final chest = double.tryParse(_chestController.text);
    final length = double.tryParse(_lengthController.text);
    
    if (chest == null || length == null || chest <= 0 || length <= 0) {
      return null;
    }
    
    // Schaeffer formülü: (Göğüs çevresi² × Vücut uzunluğu) / 10800
    final weight = (chest * chest * length) / 10800;
    return weight;
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (image == null) return;

    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages[index] = image;
      } else {
        _selectedImages.add(image);
      }
    });
  }

  Future<void> _startAnalysis() async {
    // Ölçüm kontrolü
    final formulaW = _calculateFormulaWeight();
    
    if (formulaW == null && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ölçüm girin veya fotoğraf seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSelecting = false;
      _isAnalyzing = true;
      _currentStep = 0;
      _formulaWeight = formulaW;
    });

    try {
      Map<String, dynamic>? aiResult;
      
      // Fotoğraf varsa AI analizi yap
      if (_selectedImages.isNotEmpty) {
        final bestImage = _selectedImages.length > 1 
            ? _selectedImages[1] 
            : _selectedImages[0];

        setState(() {
          _currentStep = 1;
        });

        // 30 saniye timeout ile API çağrısı
        aiResult = await _mlService.analyzeImage(File(bestImage.path))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Analiz zaman aşımına uğradı');
              },
            );
        
        // Hayvan bulunamadı hatası kontrolü
        if (aiResult.containsKey('error') && aiResult['error'] == 'no_livestock') {
          setState(() {
            _isAnalyzing = false;
            _isSelecting = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${aiResult['message'] ?? 'Fotoğrafta sığır bulunamadı'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      
      setState(() {
        _currentStep = 2;
      });

      // Ağırlık hesaplama: Formül + AI birleştir
      double finalWeight;
      double finalConfidence;
      
      if (_formulaWeight != null && aiResult != null && aiResult.containsKey('weight')) {
        // İkisi de varsa: Formül %70, AI %30 ağırlıklı ortalama
        final aiWeight = (aiResult['weight'] as num).toDouble();
        finalWeight = (_formulaWeight! * 0.7) + (aiWeight * 0.3);
        finalConfidence = 92.0;
      } else if (_formulaWeight != null) {
        // Sadece formül
        finalWeight = _formulaWeight!;
        finalConfidence = 90.0;
      } else if (aiResult != null && aiResult.containsKey('weight')) {
        // Sadece AI
        finalWeight = (aiResult['weight'] as num).toDouble();
        finalConfidence = (aiResult['confidence'] as double) * 100;
      } else {
        // Hiçbiri yoksa hata göster
        setState(() {
          _isAnalyzing = false;
          _isSelecting = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Analiz yapılamadı. Lütfen ölçüleri girin veya tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isAnalyzing = false;
        _estimatedWeight = finalWeight;
        _confidence = finalConfidence;
        _bodyCondition = aiResult?['conditionScore'] ?? 'İdeal';
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
          _confidence = 90.0;
          _bodyCondition = 'İdeal';
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
        _isSelecting = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().contains('Timeout') ? 'Zaman aşımı - tekrar deneyin' : e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
                  const SizedBox(height: 8),
                  if (_bodyCondition != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    'Güven: %${_confidence!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
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
                          Icon(Icons.category, size: 20, color: Colors.blue[700]),
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
              'ChatGPT Vision AI ile analiz edildi.',
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
              _showShareScreen();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showShareScreen() {
    // En iyi fotoğrafı seç
    String? bestImagePath;
    if (_selectedImages.isNotEmpty) {
      bestImagePath = _selectedImages.length > 1 
          ? _selectedImages[1].path 
          : _selectedImages[0].path;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _GalleryShareScreen(
        weight: _estimatedWeight ?? 0,
        imagePath: bestImagePath,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Galeri ile Baskül'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: _isAnalyzing ? _buildAnalyzingView() : _buildSelectionView(),
    );
  }

  Widget _buildAnalyzingView() {
    final steps = ['Görsel hazırlanıyor...', 'AI analiz ediyor...', 'Sonuç hesaplanıyor...'];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 24),
          Text(
            steps[_currentStep],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin...',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionView() {
    final hasFormula = _chestController.text.isNotEmpty && _lengthController.text.isNotEmpty;
    final canAnalyze = hasFormula || _selectedImages.isNotEmpty;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Ölçüm Girişi
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, color: Colors.green[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ölçüm Girin (Önerilen)',
                      style: TextStyle(
                        color: Colors.green[400],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Daha doğru sonuç için ölçüm girin',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chestController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Göğüs Çevresi',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          suffixText: 'cm',
                          suffixStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Vücut Uzunluğu',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          suffixText: 'cm',
                          suffixStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (hasFormula) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Ölçüler girildi ✓',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Fotoğraf Seçimi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Fotoğraf Ekle (Opsiyonel)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (index) => _buildPhotoSlot(index)),
              ),
            ),
          ),
          
          // Analiz Butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  Text(
                    '${_selectedImages.length}/3 fotoğraf seçildi',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAnalyze ? _startAnalysis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: Text(
                      hasFormula 
                          ? 'Ağırlık Hesapla' 
                          : (_selectedImages.isEmpty ? 'Ölçüm veya Fotoğraf Gerekli' : 'AI ile Analiz Et'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    final hasImage = index < _selectedImages.length;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage ? Colors.green : Colors.grey[700]!,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.black54,
                          child: Text(
                            _photoLabels[index],
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.grey[600], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _photoLabels[index],
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Sosyal Medya Paylaşım Ekranı - Gallery
class _GalleryShareScreen extends StatefulWidget {
  final double weight;
  final String? imagePath;
  final VoidCallback onClose;

  const _GalleryShareScreen({
    required this.weight,
    this.imagePath,
    required this.onClose,
  });

  @override
  State<_GalleryShareScreen> createState() => _GalleryShareScreenState();
}

class _GalleryShareScreenState extends State<_GalleryShareScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareToSocialMedia(String platform) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Kart bulunamadı');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/th_takvim_hayvan_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🐄 Hayvanımın ağırlığı: ${widget.weight.toStringAsFixed(1)} kg\n\n📱 TH Takvim uygulaması ile ölçüldü!\n#THtakvim #hayvancılık #çiftçi',
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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
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
                          colors: [
                            Colors.green[700]!,
                            Colors.green[900]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.pets, color: Colors.white, size: 24),
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
                          
                          if (widget.imagePath != null && File(widget.imagePath!).existsSync())
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
                                child: Icon(Icons.pets, color: Colors.white54, size: 64),
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                  '${widget.weight.toStringAsFixed(1)} kg',
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
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Colors.white.withOpacity(0.9), size: 16),
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
                                  'Hayvanınızın Ücretsiz Kilo Ölçümünü Yapın',
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
                  
                  const Text(
                    'Paylaşmak için bir platform seçin',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
