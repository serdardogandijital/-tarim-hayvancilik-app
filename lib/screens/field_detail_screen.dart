import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/field.dart';
import '../services/field_storage_service.dart';
import 'add_edit_field_screen.dart';
import 'field_location_picker_screen.dart';

class FieldDetailScreen extends StatefulWidget {
  final Field field;

  const FieldDetailScreen({super.key, required this.field});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.field.tasks);
  }

  Future<void> _toggleTask(int index) async {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
    });
    await _saveTasksToStorage();
  }

  Future<void> _addTask() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddTaskDialog(),
    );

    if (result != null) {
      setState(() {
        _tasks.add(Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'],
          description: result['description'],
          dueDate: result['dueDate'],
          isCompleted: false,
          category: result['category'],
        ));
      });
      await _saveTasksToStorage();
    }
  }

  Future<void> _editTask(int index) async {
    final task = _tasks[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddTaskDialog(
        initialTitle: task.title,
        initialDescription: task.description,
        initialDueDate: task.dueDate,
        initialCategory: task.category,
      ),
    );

    if (result != null) {
      setState(() {
        _tasks[index] = task.copyWith(
          title: result['title'],
          description: result['description'],
          dueDate: result['dueDate'],
          category: result['category'],
        );
      });
      await _saveTasksToStorage();
    }
  }

  Future<void> _deleteTask(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text('${_tasks[index].title} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _tasks.removeAt(index);
      });
      await _saveTasksToStorage();
    }
  }

  Future<void> _saveTasksToStorage() async {
    final updatedField = widget.field.copyWith(tasks: _tasks);
    await FieldStorageService.updateField(updatedField);
  }

  Future<void> _editField() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditFieldScreen(field: widget.field),
      ),
    );
    
    if (result != null && result is Field) {
      Navigator.pop(context, {'action': 'edit', 'field': result});
    }
  }

  Future<void> _deleteField() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarlayı Sil'),
        content: Text('${widget.field.name} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context, {'action': 'delete', 'field': widget.field});
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final progress = _tasks.isNotEmpty ? completedCount / _tasks.length : 0.0;

    return WillPopScope(
      onWillPop: () async {
        // Geri giderken güncellenmiş tarlayı döndür
        final updatedField = widget.field.copyWith(tasks: _tasks);
        Navigator.pop(context, {'action': 'update', 'field': updatedField});
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        appBar: AppBar(
          title: Text(widget.field.name),
          backgroundColor: const Color(0xFFF5F1E8),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editField,
              tooltip: 'Düzenle',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteField,
              tooltip: 'Sil',
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildProgressCard(completedCount, progress),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildTasksCard(),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
              const Icon(Icons.agriculture, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.field.currentCrop ?? 'Boş Tarla',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.field.area} dönüm',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.field.ownership == FieldOwnership.own
                          ? Icons.home_work_outlined
                          : Icons.assignment_ind_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.field.ownership == FieldOwnership.own
                          ? 'Kendi Tarlam'
                          : 'Kiralık',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.field.plantingDate != null || widget.field.harvestDate != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            if (widget.field.plantingDate != null)
              _buildDateRow(
                Icons.calendar_today,
                'Ekim Tarihi',
                DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.field.plantingDate!),
              ),
            if (widget.field.harvestDate != null) ...[
              const SizedBox(height: 8),
              _buildDateRow(
                Icons.agriculture,
                'Hasat Tarihi',
                DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.field.harvestDate!),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, String date) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    if (!widget.field.hasLocation) {
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
              'Tarla Konumu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu tarla için henüz koordinat kaydedilmemiş.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _editField,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Konum Ekle'),
            ),
          ],
        ),
      );
    }

    final lat = widget.field.latitude!;
    final lng = widget.field.longitude!;
    final latLng = LatLng(lat, lng);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarla Konumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.field.locationName ??
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FieldLocationPickerScreen(
                        initialLocation: latLng,
                        initialAddress: widget.field.locationName,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fullscreen),
                label: const Text('Haritada Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latLng,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    enableScrollWheel: false,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.thtakvim.tarim_hayvancilik_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.pin_drop_outlined, size: 18),
              const SizedBox(width: 8),
              Text('${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completedCount, double progress) {
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
                'İlerleme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completedCount/${_tasks.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% tamamlandı',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    final tasksByCategory = <TaskCategory, List<Task>>{};
    for (var task in _tasks) {
      tasksByCategory.putIfAbsent(task.category, () => []).add(task);
    }

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
                'Yapılacaklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addTask,
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Görev Ekle',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz görev eklenmemiş',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addTask,
                      icon: const Icon(Icons.add),
                      label: const Text('İlk Görevi Ekle'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tasksByCategory.entries.map((entry) {
              return _buildCategorySection(entry.key, entry.value);
            }),
        ],
      ),
    );
  }

  Widget _buildCategorySection(TaskCategory category, List<Task> tasks) {
    final categoryName = _getCategoryName(category);
    final categoryIcon = _getCategoryIcon(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(categoryIcon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tasks.asMap().entries.map((entry) {
          final taskIndex = _tasks.indexOf(entry.value);
          return _buildTaskItem(entry.value, taskIndex);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskItem(Task task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: task.isCompleted,
        onChanged: (value) => _toggleTask(index),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text(
                DateFormat('dd MMM yyyy', 'tr_TR').format(task.dueDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: task.isCompleted ? Colors.grey : Colors.grey[600],
                ),
              )
            : null,
        secondary: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
          onSelected: (value) {
            if (value == 'edit') {
              _editTask(index);
            } else if (value == 'delete') {
              _deleteTask(index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.green,
      ),
    );
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.beforePlanting:
        return 'Ekimden Önce';
      case TaskCategory.planting:
        return 'Ekim Sırası';
      case TaskCategory.afterPlanting:
        return 'Ekimden Sonra';
      case TaskCategory.maintenance:
        return 'Bakım';
      case TaskCategory.harvest:
        return 'Hasat';
      case TaskCategory.other:
        return 'Diğer';
    }
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.beforePlanting:
        return Icons.grass;
      case TaskCategory.planting:
        return Icons.spa;
      case TaskCategory.afterPlanting:
        return Icons.water_drop;
      case TaskCategory.maintenance:
        return Icons.build;
      case TaskCategory.harvest:
        return Icons.agriculture;
      case TaskCategory.other:
        return Icons.more_horiz;
    }
  }
}

class _AddTaskDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDueDate;
  final TaskCategory? initialCategory;

  const _AddTaskDialog({
    this.initialTitle,
    this.initialDescription,
    this.initialDueDate,
    this.initialCategory,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  late TaskCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _dueDate = widget.initialDueDate;
    _category = widget.initialCategory ?? TaskCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev adı gerekli')),
      );
      return;
    }

    Navigator.pop(context, {
      'title': _titleController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'dueDate': _dueDate,
      'category': _category,
    });
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.beforePlanting:
        return 'Ekimden Önce';
      case TaskCategory.planting:
        return 'Ekim Sırası';
      case TaskCategory.afterPlanting:
        return 'Ekimden Sonra';
      case TaskCategory.maintenance:
        return 'Bakım';
      case TaskCategory.harvest:
        return 'Hasat';
      case TaskCategory.other:
        return 'Diğer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTitle == null ? 'Yeni Görev' : 'Görevi Düzenle',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Görev Adı *',
                  hintText: 'Örn: Gübreleme, Sulama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Detayları buraya yazın',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tarih (Opsiyonel)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dueDate != null
                                  ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_dueDate!)
                                  : 'Tarih seçin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _dueDate != null ? FontWeight.w500 : FontWeight.normal,
                                color: _dueDate != null ? Colors.black87 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskCategory>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: TaskCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
