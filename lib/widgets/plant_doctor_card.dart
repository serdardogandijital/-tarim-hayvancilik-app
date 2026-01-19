import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/plant_analysis.dart';
import '../services/plant_analysis_service.dart';
import '../services/plant_storage_service.dart';

class PlantDoctorCard extends StatefulWidget {
  const PlantDoctorCard({super.key});

  @override
  State<PlantDoctorCard> createState() => _PlantDoctorCardState();
}

class _PlantDoctorCardState extends State<PlantDoctorCard> {
  final ImagePicker _picker = ImagePicker();
  final PlantAnalysisService _analysisService = PlantAnalysisService();
  
  bool _isAnalyzing = false;
  PlantAnalysis? _currentAnalysis;
  List<PlantAnalysis> _recentAnalyses = [];

  @override
  void initState() {
    super.initState();
    _loadRecentAnalyses();
  }

  Future<void> _loadRecentAnalyses() async {
    try {
      final analyses = await PlantStorageService.loadAnalyses();
      if (mounted) {
        setState(() {
          _recentAnalyses = analyses.take(3).toList();
          // Uygulama açıldığında son analizi gösterme - sadece yeni analiz yapıldığında göster
          // _currentAnalysis = null olarak kalacak
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (mounted) {
        setState(() {
          _isAnalyzing = true;
          _currentAnalysis = null;
        });
      }

      final analysis = await _analysisService.analyzePlant(image.path);
      await PlantStorageService.saveAnalysis(analysis);

      if (mounted) {
        setState(() {
          _currentAnalysis = analysis;
          _isAnalyzing = false;
        });
      }

      await _loadRecentAnalyses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analiz tamamlandı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildActionButtons(),
          if (_isAnalyzing) _buildLoadingState(),
          if (!_isAnalyzing && _currentAnalysis != null) _buildAnalysisResult(),
          if (!_isAnalyzing && _currentAnalysis == null && _recentAnalyses.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_florist, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bitki Doktoru AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Fotoğrafla bitki analizi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_recentAnalyses.isNotEmpty)
            GestureDetector(
              onTap: _showAnalysisHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_recentAnalyses.length} analiz',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.green[300]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'AI bitkinizi analiz ediyor...',
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu birkaç saniye sürebilir',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.eco, size: 48, color: Colors.green[300]),
          const SizedBox(height: 12),
          Text(
            _recentAnalyses.isEmpty ? 'Henüz analiz yok' : 'Yeni analiz için fotoğraf çekin',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bitki fotoğrafı çekerek başlayın',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          if (_recentAnalyses.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentAnalysis = _recentAnalyses.first;
                });
              },
              icon: Icon(Icons.history, size: 16, color: Colors.green[600]),
              label: Text(
                'Son analizi göster (${_recentAnalyses.length})',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final analysis = _currentAnalysis!;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (File(analysis.imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(analysis.imagePath),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            Icons.local_florist,
            'Bitki',
            analysis.plantName,
            Colors.green,
          ),
          if (analysis.scientificName.isNotEmpty)
            _buildInfoRow(
              Icons.science,
              'Bilimsel Adı',
              analysis.scientificName,
              Colors.blue,
            ),
          _buildInfoRow(
            Icons.health_and_safety,
            'Durum',
            analysis.status,
            _getStatusColor(analysis.status),
          ),
          _buildInfoRow(
            Icons.analytics,
            'Güven',
            '%${(analysis.confidence * 100).toStringAsFixed(0)}',
            Colors.purple,
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          if (analysis.diseases.isNotEmpty) ...[
            _buildSection('🔍 Tespit Edilen Sorunlar', analysis.diseases),
            const SizedBox(height: 12),
          ],
          
          if (analysis.treatments.isNotEmpty) ...[
            _buildSection('💊 Tedavi Önerileri', analysis.treatments),
            const SizedBox(height: 12),
          ],
          
          if (analysis.careAdvice.isNotEmpty) ...[
            _buildSection('🌱 Bakım Tavsiyeleri', analysis.careAdvice),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: _buildScheduleChip(
                  Icons.water_drop,
                  'Sulama',
                  analysis.wateringSchedule,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScheduleChip(
                  Icons.grass,
                  'Gübreleme',
                  analysis.fertilizingSchedule,
                  Colors.brown,
                ),
              ),
            ],
          ),
          
          if (analysis.harvestTime != null) ...[
            const SizedBox(height: 8),
            _buildScheduleChip(
              Icons.agriculture,
              'Hasat',
              analysis.harvestTime!,
              Colors.orange,
            ),
          ],
          
          if (analysis.preventionTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('🐛 Zararlı Önleme', analysis.preventionTips),
          ],
          
          const SizedBox(height: 12),
          Text(
            'Analiz: ${DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(analysis.timestamp)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.green[800],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: Colors.green[600])),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildScheduleChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Sağlıklı')) return Colors.green;
    if (status.contains('Hastalık') || status.contains('Zararlı')) return Colors.red;
    if (status.contains('Eksiklik')) return Colors.orange;
    return Colors.grey;
  }

  void _showAnalysisHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Geçmiş Analizler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _recentAnalyses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz analiz yok',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recentAnalyses.length,
                      itemBuilder: (context, index) {
                        final analysis = _recentAnalyses[index];
                        return _buildHistoryItem(analysis, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(PlantAnalysis analysis, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentAnalysis = analysis;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            if (File(analysis.imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(analysis.imagePath),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.eco, color: Colors.green[600]),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(analysis.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          analysis.status,
                          style: TextStyle(
                            color: _getStatusColor(analysis.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(analysis.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
