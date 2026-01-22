import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../models/animal.dart';
import '../services/animal_storage_service.dart';
import 'add_animal_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Widget _buildAttachmentsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Belgeler & Fotoğraflar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (_animal.attachments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Henüz eklenen belge bulunmuyor.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._animal.attachments.map(
                (attachment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _attachmentIcon(attachment.type, attachment.name),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                        .format(attachment.addedAt),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Aç',
                    onPressed: () => _openAttachment(attachment),
                  ),
                  onTap: () => _openAttachment(attachment),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(AnimalAttachment attachment) async {
    final file = File(attachment.filePath);
    if (!await file.exists()) {
      _showSnack('Dosya bulunamadı: ${attachment.name}');
      return;
    }

    final result = await OpenFilex.open(attachment.filePath);
    if (result.type != ResultType.done) {
      _showSnack('Dosya açılamadı (${result.message})');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  IconData _attachmentIcon(String type, String fileName) {
    if (type == 'photo') {
      return Icons.photo;
    }
    final extension = p.extension(fileName).toLowerCase();
    if (extension == '.pdf') return Icons.picture_as_pdf;
    if (extension == '.doc' || extension == '.docx') return Icons.description;
    return Icons.attach_file;
  }

  Future<void> _updateAnimal(Animal updatedAnimal) async {
    await AnimalStorageService.updateAnimal(updatedAnimal);
    setState(() {
      _animal = updatedAnimal;
    });
  }

  IconData _getAnimalIcon(String type) {
    final lowerType = type.toLowerCase();
    
    // Büyükbaş hayvanlar
    if (lowerType.contains('inek') || 
        lowerType.contains('dana') || 
        lowerType.contains('tosun') ||
        lowerType.contains('boğa') ||
        lowerType.contains('düve') ||
        lowerType.contains('manda') ||
        lowerType.contains('öküz')) {
      return Icons.pets;
    }
    
    // Küçükbaş hayvanlar - Koyun
    if (lowerType.contains('koyun') || 
        lowerType.contains('koç') || 
        lowerType.contains('kuzu') ||
        lowerType.contains('toklu')) {
      return Icons.cruelty_free;
    }
    
    // Küçükbaş hayvanlar - Keçi
    if (lowerType.contains('keçi') || 
        lowerType.contains('oğlak') ||
        lowerType.contains('teke')) {
      return Icons.pets_outlined;
    }
    
    return Icons.pets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_animal.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAnimalScreen(animal: _animal),
                ),
              );
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hayvanı Sil'),
                  content: Text('${_animal.name} kaydını silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, 'delete');
                      },
                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _getAnimalIcon(_animal.type),
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _animal.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_animal.type} - ${_animal.breed}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Genel Bilgiler',
            [
              _buildInfoRow(Icons.cake, 'Doğum Tarihi',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_animal.birthDate)),
              _buildInfoRow(Icons.calendar_today, 'Yaş', '${_animal.ageInYears} yaşında'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Üreme Bilgileri',
            [
              if (_animal.lastBirthDate != null)
                _buildInfoRow(
                  Icons.child_care,
                  'Son Doğurma Tarihi',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_animal.lastBirthDate!),
                ),
              if (_animal.daysSinceLastBirth != null)
                _buildInfoRow(
                  Icons.access_time,
                  'Son Doğurmadan İtibaren',
                  '${_animal.daysSinceLastBirth} gün',
                ),
              if (_animal.nextHeatDate != null)
                _buildInfoRow(
                  Icons.event,
                  'Sonraki Kızgınlık Takibi',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_animal.nextHeatDate!),
                ),
              if (_animal.daysUntilNextHeat != null)
                _buildInfoRow(
                  Icons.timer,
                  'Kalan Süre',
                  _animal.daysUntilNextHeat! > 0
                      ? '${_animal.daysUntilNextHeat} gün'
                      : 'Bugün',
                  color: _animal.daysUntilNextHeat! <= 7 ? Colors.orange : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVaccineCard(context),
          const SizedBox(height: 16),
          _buildFeedCard(context),
          const SizedBox(height: 16),
          _buildAttachmentsCard(context),
          if (_animal.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Notlar',
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _animal.notes,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aşı Kayıtları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addVaccine(context),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const Divider(),
            if (_animal.vaccines.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Henüz aşı kaydı yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._animal.vaccines.map((vaccine) => ListTile(
                    leading: const Icon(Icons.vaccines, color: Colors.green),
                    title: Text(vaccine.name),
                    subtitle: Text(
                      'Yapıldı: ${DateFormat('dd MMM yyyy', 'tr_TR').format(vaccine.date)}' +
                          (vaccine.nextDate != null
                              ? '\nSonraki: ${DateFormat('dd MMM yyyy', 'tr_TR').format(vaccine.nextDate!)}'
                              : ''),
                    ),
                    isThreeLine: vaccine.nextDate != null,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yem Bilgisi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editFeed(context),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              Icons.grass,
              'Günlük Yem',
              _animal.dailyFeedAmount != null
                  ? '${_animal.dailyFeedAmount!.toStringAsFixed(1)} kg'
                  : 'Girilmedi',
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Aylık Maliyet',
              _animal.monthlyFeedCost != null
                  ? '${_animal.monthlyFeedCost!.toStringAsFixed(0)} ₺'
                  : 'Girilmedi',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVaccine(BuildContext context) async {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    DateTime? nextDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aşı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Aşı Adı',
                    hintText: 'Örn: Şap, Brusella',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Yapılma Tarihi'),
                  subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Sonraki Aşı (Opsiyonel)'),
                  subtitle: Text(nextDate != null
                      ? DateFormat('dd MMMM yyyy', 'tr_TR').format(nextDate!)
                      : 'Seçilmedi'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: nextDate ?? DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => nextDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final updatedVaccines = List<VaccineRecord>.from(_animal.vaccines)
        ..add(VaccineRecord(
          name: nameController.text,
          date: selectedDate,
          nextDate: nextDate,
        ));

      await _updateAnimal(_animal.copyWith(vaccines: updatedVaccines));
    }
  }

  Future<void> _editFeed(BuildContext context) async {
    final dailyController = TextEditingController(
      text: _animal.dailyFeedAmount?.toString() ?? '',
    );
    final costController = TextEditingController(
      text: _animal.monthlyFeedCost?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yem Bilgisi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dailyController,
              decoration: const InputDecoration(
                labelText: 'Günlük Yem Miktarı (kg)',
                hintText: 'Örn: 5.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Aylık Yem Maliyeti (₺)',
                hintText: 'Örn: 1500',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true) {
      final dailyAmount = double.tryParse(dailyController.text);
      final monthlyCost = double.tryParse(costController.text);

      await _updateAnimal(_animal.copyWith(
        dailyFeedAmount: dailyAmount,
        monthlyFeedCost: monthlyCost,
      ));
    }
  }
}
