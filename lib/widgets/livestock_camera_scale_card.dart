import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/livestock_ml_service.dart';

class LivestockCameraScaleCard extends StatefulWidget {
  const LivestockCameraScaleCard({super.key});

  @override
  State<LivestockCameraScaleCard> createState() => _LivestockCameraScaleCardState();
}

class _LivestockCameraScaleCardState extends State<LivestockCameraScaleCard> {
  final ImagePicker _imagePicker = ImagePicker();
  final LivestockMLService _mlService = LivestockMLService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  double? _estimatedWeight;
  String? _bodyConditionScore;
  double? _confidence;
  String? _analysisMethod;

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _selectedImage = File(photo.path);
        _isAnalyzing = true;
        _estimatedWeight = null;
        _bodyConditionScore = null;
      });

      await _analyzeImage();
    } catch (e) {
      _showError('Kamera hatası: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _selectedImage = File(photo.path);
        _isAnalyzing = true;
        _estimatedWeight = null;
        _bodyConditionScore = null;
      });

      await _analyzeImage();
    } catch (e) {
      _showError('Galeri hatası: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    try {
      // ML servisini başlat
      await _mlService.initialize();
      
      // Görüntüyü analiz et
      final result = await _mlService.analyzeImage(_selectedImage!);
      
      setState(() {
        _estimatedWeight = result['weight'];
        _bodyConditionScore = result['conditionScore'];
        _confidence = result['confidence'];
        _analysisMethod = result['method'];
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Analiz hatası: $e');
    }
  }

  String _getHealthStatus() {
    if (_bodyConditionScore == null) return '';
    
    switch (_bodyConditionScore!) {
      case 'Zayıf':
        return 'Dikkat: Yetersiz beslenme riski';
      case 'Orta-Zayıf':
        return 'Uyarı: Yem miktarını artırın';
      case 'İdeal':
        return 'Mükemmel: Sağlıklı kondisyon';
      case 'İyi':
        return 'İyi: Dengeli beslenme';
      case 'Aşırı Kilolu':
        return 'Dikkat: Yem kontrolü gerekli';
      default:
        return '';
    }
  }

  Color _getConditionColor() {
    if (_bodyConditionScore == null) return Colors.grey;
    
    switch (_bodyConditionScore!) {
      case 'Zayıf':
      case 'Aşırı Kilolu':
        return Colors.red;
      case 'Orta-Zayıf':
        return Colors.orange;
      case 'İdeal':
        return Colors.green;
      case 'İyi':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<String> _getHealthRecommendations() {
    if (_bodyConditionScore == null) return [];
    
    switch (_bodyConditionScore!) {
      case 'Zayıf':
        return [
          'Günlük yem miktarını %20 artırın',
          'Protein oranı yüksek yem tercih edin',
          'Veteriner kontrolü önerilir',
          'Parazit kontrolü yapın',
        ];
      case 'Orta-Zayıf':
        return [
          'Yem kalitesini kontrol edin',
          'Günlük yem miktarını %10 artırın',
          'Su tüketimini izleyin',
        ];
      case 'İdeal':
        return [
          'Mevcut besleme programına devam edin',
          'Düzenli tartı takibi yapın',
          'Mevsimsel değişikliklere dikkat edin',
        ];
      case 'İyi':
        return [
          'Besleme dengeli, devam edin',
          'Aylık kilo takibi yapın',
        ];
      case 'Aşırı Kilolu':
        return [
          'Yem miktarını kademeli azaltın',
          'Hareket alanını genişletin',
          'Yüksek lifli, düşük kalorili yem verin',
        ];
      default:
        return [];
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _estimatedWeight = null;
      _bodyConditionScore = null;
      _confidence = null;
      _analysisMethod = null;
      _isAnalyzing = false;
    });
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamera ile Kilo Tahmini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hayvan fotoğrafı ile yapay zeka analizi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImage == null) ...[
            _buildImagePickerButtons(),
          ] else ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
            if (_isAnalyzing) _buildAnalyzingIndicator(),
            if (!_isAnalyzing && _estimatedWeight != null) _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePickerButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera ile Çek'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeriden Seç'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        _selectedImage!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Yapay zeka görüntüyü analiz ediyor...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final conditionColor = _getConditionColor();
    final healthStatus = _getHealthStatus();
    final recommendations = _getHealthRecommendations();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: conditionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: conditionColor.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Icon(
                _bodyConditionScore == 'İdeal' || _bodyConditionScore == 'İyi'
                    ? Icons.check_circle
                    : Icons.warning,
                color: conditionColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  healthStatus,
                  style: TextStyle(
                    color: conditionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultItem(
                    'Tahmini Kilo',
                    '${_estimatedWeight!.toStringAsFixed(0)} kg',
                    Icons.monitor_weight,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  _buildResultItem(
                    'Vücut Kondisyonu',
                    _bodyConditionScore!,
                    Icons.favorite,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Öneriler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        if (_confidence != null && _analysisMethod != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _analysisMethod!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Güven: ${(_confidence! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Analiz'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt özelliği yakında eklenecek')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
