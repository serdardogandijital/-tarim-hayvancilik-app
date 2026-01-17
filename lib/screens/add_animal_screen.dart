import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _selectedType = 'İnek';
  DateTime _birthDate = DateTime.now();
  DateTime? _lastBirthDate;
  DateTime? _nextHeatDate;

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
      );
      Navigator.pop(context, animal);
    }
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
              title: const Text('Son Doğum Tarihi (Opsiyonel)'),
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
              title: const Text('Sonraki Öğüre Tarihi (Opsiyonel)'),
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
}
