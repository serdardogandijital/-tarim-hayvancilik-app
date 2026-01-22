import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/animal.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animal;

  const AddAnimalScreen({super.key, this.animal});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedType = 'İnek';
  DateTime _birthDate = DateTime.now();
  DateTime? _lastBirthDate;
  DateTime? _nextHeatDate;
  List<AnimalAttachment> _attachments = [];

  final List<String> _animalTypes = [
    'İnek',
    'Koyun',
    'Keçi',
    'At',
    'Manda',
    'Deve',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      _nameController.text = widget.animal!.name;
      _breedController.text = widget.animal!.breed;
      _notesController.text = widget.animal!.notes;
      _selectedType = widget.animal!.type;
      _birthDate = widget.animal!.birthDate;
      _lastBirthDate = widget.animal!.lastBirthDate;
      _nextHeatDate = widget.animal!.nextHeatDate;
      _attachments = widget.animal!.attachments
          .map((attachment) => attachment.copyWith())
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: type == 'birth'
          ? _birthDate
          : (type == 'lastBirth' ? (_lastBirthDate ?? DateTime.now()) : (_nextHeatDate ?? DateTime.now())),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (type == 'birth') {
          _birthDate = picked;
        } else if (type == 'lastBirth') {
          _lastBirthDate = picked;
        } else {
          _nextHeatDate = picked;
        }
      });
    }
  }

  void _saveAnimal() {
    if (_formKey.currentState!.validate()) {
      final animal = Animal(
        id: widget.animal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        breed: _breedController.text,
        birthDate: _birthDate,
        lastBirthDate: _lastBirthDate,
        nextHeatDate: _nextHeatDate,
        notes: _notesController.text,
        attachments: _attachments,
      );
      Navigator.pop(context, animal);
    }
  }

  Future<void> _showAttachmentOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera ile fotoğraf çek'),
              onTap: () {
                Navigator.pop(context);
                _addAttachmentFromImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden fotoğraf seç'),
              onTap: () {
                Navigator.pop(context);
                _addAttachmentFromImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Belge yükle (PDF, fatura vb.)'),
              onTap: () {
                Navigator.pop(context);
                _addAttachmentFromFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttachmentFromImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      final savedPath = await _copyFileToAppDir(File(picked.path), picked.name);
      final attachment = AnimalAttachment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'photo',
        name: picked.name,
        filePath: savedPath,
        addedAt: DateTime.now(),
      );

      setState(() {
        _attachments.add(attachment);
      });
    } catch (e) {
      _showError('Fotoğraf eklenirken hata oluştu: $e');
    }
  }

  Future<void> _addAttachmentFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      String? savedPath;

      if (file.bytes != null) {
        savedPath = await _saveBytesToAppDir(file.bytes!, file.name);
      } else if (file.path != null) {
        savedPath = await _copyFileToAppDir(File(file.path!), file.name);
      }

      if (savedPath == null) {
        _showError('Belge kaydedilemedi.');
        return;
      }

      final attachment = AnimalAttachment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'document',
        name: file.name,
        filePath: savedPath,
        addedAt: DateTime.now(),
      );

      setState(() {
        _attachments.add(attachment);
      });
    } catch (e) {
      _showError('Belge eklenirken hata oluştu: $e');
    }
  }

  Future<String> _copyFileToAppDir(File sourceFile, String originalName) async {
    final dir = await _ensureAttachmentDir();
    final sanitizedName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName',
    );
    final newFile = await sourceFile.copy(targetPath);
    return newFile.path;
  }

  Future<String> _saveBytesToAppDir(Uint8List bytes, String originalName) async {
    final dir = await _ensureAttachmentDir();
    final sanitizedName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName',
    );
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _ensureAttachmentDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(baseDir.path, 'animal_attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  void _removeAttachment(String id) {
    setState(() {
      _attachments.removeWhere((attachment) => attachment.id == id);
    });
  }

  void _showError(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal == null ? 'Hayvan Ekle' : 'Hayvan Düzenle'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hayvan Adı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen hayvan adı girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Hayvan Türü',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _animalTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Cins',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen cins girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Doğum Tarihi'),
              subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(_birthDate)),
              leading: const Icon(Icons.cake),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'birth'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Son Doğurma Tarihi (Opsiyonel)'),
              subtitle: Text(_lastBirthDate != null
                  ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_lastBirthDate!)
                  : 'Seçilmedi'),
              leading: const Icon(Icons.child_care),
              trailing: _lastBirthDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _lastBirthDate = null;
                        });
                      },
                    )
                  : const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'lastBirth'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sonraki Kızgınlık Takibi (Opsiyonel)'),
              subtitle: Text(_nextHeatDate != null
                  ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_nextHeatDate!)
                  : 'Seçilmedi'),
              leading: const Icon(Icons.event),
              trailing: _nextHeatDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _nextHeatDate = null;
                        });
                      },
                    )
                  : const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'nextHeat'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar (Opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildAttachmentSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAnimal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.animal == null ? 'Kaydet' : 'Güncelle',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Belgeler / Fotoğraflar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_attachments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz eklenen belge yok',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _attachments
                    .map(
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
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeAttachment(attachment.id),
                          tooltip: 'Kaldır',
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
