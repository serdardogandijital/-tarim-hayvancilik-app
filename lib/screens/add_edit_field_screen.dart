import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/field.dart';

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

  bool get isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name ?? '');
    _areaController = TextEditingController(text: widget.field?.area.toString() ?? '');
    _cropController = TextEditingController(text: widget.field?.currentCrop ?? '');
    _plantingDate = widget.field?.plantingDate;
    _harvestDate = widget.field?.harvestDate;
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
