import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/field.dart';
import 'field_location_picker_screen.dart';

class AddEditFieldScreen extends StatefulWidget {
  final Field? field; // null ise yeni tarla, dolu ise düzenleme

  const AddEditFieldScreen({super.key, this.field});

  @override
  State<AddEditFieldScreen> createState() => _AddEditFieldScreenState();
}

class _AddEditFieldScreenState extends State<AddEditFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _areaController;
  late TextEditingController _cropController;
  DateTime? _plantingDate;
  DateTime? _harvestDate;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  late FieldOwnership _ownership;

  bool get isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name ?? '');
    _areaController = TextEditingController(text: widget.field?.area.toString() ?? '');
    _cropController = TextEditingController(text: widget.field?.currentCrop ?? '');
    _plantingDate = widget.field?.plantingDate;
    _harvestDate = widget.field?.harvestDate;
    _latitude = widget.field?.latitude;
    _longitude = widget.field?.longitude;
    _locationName = widget.field?.locationName;
    _ownership = widget.field?.ownership ?? FieldOwnership.own;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPlanting) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPlanting
          ? (_plantingDate ?? DateTime.now())
          : (_harvestDate ?? DateTime.now().add(const Duration(days: 180))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        if (isPlanting) {
          _plantingDate = picked;
        } else {
          _harvestDate = picked;
        }
      });
    }
  }

  void _saveField() {
    if (_formKey.currentState!.validate()) {
      final field = Field(
        id: widget.field?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        area: double.parse(_areaController.text),
        currentCrop: _cropController.text.isEmpty ? null : _cropController.text,
        plantingDate: _plantingDate,
        harvestDate: _harvestDate,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName,
        ownership: _ownership,
        tasks: widget.field?.tasks ?? _getDefaultTasks(),
      );
      Navigator.pop(context, field);
    }
  }

  List<Task> _getDefaultTasks() {
    if (_cropController.text.isEmpty) return [];
    
    return [
      Task(
        id: '1',
        title: 'Toprak hazırlığı',
        description: 'Toprağı sürün ve düzleyin',
        isCompleted: false,
        category: TaskCategory.beforePlanting,
      ),
      Task(
        id: '2',
        title: 'Gübreleme',
        description: 'Organik gübre uygulayın',
        isCompleted: false,
        category: TaskCategory.beforePlanting,
      ),
      Task(
        id: '3',
        title: 'Ekim',
        description: 'Tohumları ekin',
        dueDate: _plantingDate,
        isCompleted: false,
        category: TaskCategory.planting,
      ),
      Task(
        id: '4',
        title: 'İlk sulama',
        description: 'Ekimden sonra sulama yapın',
        isCompleted: false,
        category: TaskCategory.afterPlanting,
      ),
      Task(
        id: '5',
        title: 'Hasat',
        description: 'Ürünleri hasat edin',
        dueDate: _harvestDate,
        isCompleted: false,
        category: TaskCategory.harvest,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: Text(isEditing ? 'Tarla Düzenle' : 'Yeni Tarla Ekle'),
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveField,
            child: Text(
              'Kaydet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildDatesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
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
          const Text(
            'Temel Bilgiler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tarla Adı *',
              hintText: 'Örn: Tarla 1, Üst Tarla',
              prefixIcon: const Icon(Icons.agriculture),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tarla adı gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _areaController,
            decoration: InputDecoration(
              labelText: 'Alan (dönüm) *',
              hintText: 'Örn: 2.5',
              prefixIcon: const Icon(Icons.straighten),
              suffixText: 'dönüm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alan gerekli';
              }
              if (double.tryParse(value) == null) {
                return 'Geçerli bir sayı girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cropController,
            decoration: InputDecoration(
              labelText: 'Ürün (Opsiyonel)',
              hintText: 'Örn: Buğday, Mısır, Domates',
              prefixIcon: const Icon(Icons.eco),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = _latitude != null && _longitude != null;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tarla Konumu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasLocation)
                TextButton.icon(
                  onPressed: _clearLocation,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Temizle'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasLocation ? Icons.check_circle_outline : Icons.map_outlined,
                      color: hasLocation
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasLocation
                                ? (_locationName ?? 'Adres bulunamadı, koordinatlar kaydedilecek')
                                : 'Henüz konum seçilmedi. Haritada işaretleyin.',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasLocation ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasLocation ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mülkiyet: ${_ownership == FieldOwnership.own ? 'Kendi tarlam' : 'Kiralık'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasLocation) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(hasLocation ? 'Konumu Düzenle' : 'Haritada Konum Seç'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mülkiyet Durumu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: FieldOwnership.values.map((ownership) {
                    final isSelected = _ownership == ownership;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300]!,
                            ),
                          ),
                          onPressed: () => setState(() => _ownership = ownership),
                          child: Column(
                            children: [
                              Icon(
                                ownership == FieldOwnership.own
                                    ? Icons.home_work_outlined
                                    : Icons.assignment_ind_outlined,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ownership == FieldOwnership.own
                                    ? 'Kendi Tarlam'
                                    : 'Kiralık Tarla',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldLocationPickerScreen(
          initialLocation: _latitude != null && _longitude != null
              ? LatLng(_latitude!, _longitude!)
              : null,
          initialAddress: _locationName,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
        _locationName = result['address'] as String?;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationName = null;
    });
  }

  Widget _buildDatesCard() {
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
          const Text(
            'Tarihler (Opsiyonel)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDateSelector(
            'Ekim Tarihi',
            _plantingDate,
            Icons.calendar_today,
            () => _selectDate(context, true),
          ),
          const SizedBox(height: 12),
          _buildDateSelector(
            'Hasat Tarihi',
            _harvestDate,
            Icons.agriculture,
            () => _selectDate(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd MMMM yyyy', 'tr_TR').format(date)
                        : 'Tarih seçin',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                      color: date != null ? Colors.black87 : Colors.grey[500],
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
