import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/farm_records.dart';
import '../services/safe_list_store.dart';

class RecordInput {
  final String keyName, label, kind;
  final Map<String, String> options;
  final bool optional;
  final bool Function(Map<String, dynamic>)? visible;
  const RecordInput(
    this.keyName,
    this.label, {
    this.kind = 'text',
    this.options = const {},
    this.optional = false,
    this.visible,
  });
}

Future<bool> editRecord(
  BuildContext context, {
  required String title,
  required List<RecordInput> fields,
  required Map<String, dynamic> initial,
  required Future<void> Function(Map<String, dynamic>) save,
  String? help,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecordForm(
        title: title,
        fields: fields,
        initial: initial,
        save: save,
        help: help,
      ),
    ) ??
    false;

class _RecordForm extends StatefulWidget {
  final String title;
  final List<RecordInput> fields;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic>) save;
  final String? help;
  const _RecordForm({
    required this.title,
    required this.fields,
    required this.initial,
    required this.save,
    this.help,
  });
  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  late final values = Map<String, dynamic>.from(widget.initial);
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.help != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.help!),
              ),
            for (final field in widget.fields.where(
              (f) => f.visible?.call(values) ?? true,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _field(field),
              ),
            if (error != null)
              Text(
                error!,
                key: const ValueKey('record-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    for (final f in widget.fields.where(
                      (f) => (f.visible?.call(values) ?? true) && !f.optional,
                    )) {
                      if (values[f.keyName] == null ||
                          values[f.keyName].toString().trim().isEmpty) {
                        throw RecordValidationFailure(
                          '${f.label} alanını doldurun.',
                        );
                      }
                    }
                    await widget.save(values);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        busy = false;
                        error = e.toString();
                      });
                    }
                  }
                },
          child: Text(busy ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    ),
  );
  Widget _field(RecordInput field) {
    final key = field.keyName;
    if (field.kind == 'date') {
      final date = values[key] as DateTime?;
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: ValueKey(key),
              icon: const Icon(Icons.event),
              onPressed: busy
                  ? null
                  : () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2200),
                      );
                      if (selected != null && mounted) {
                        setState(() => values[key] = selected);
                      }
                    },
              label: Text(
                '${field.label}: ${date == null ? 'Seçin' : DateFormat('dd.MM.yyyy').format(date)}',
              ),
            ),
          ),
          if (field.optional && date != null)
            IconButton(
              tooltip: '${field.label} temizle',
              onPressed: busy ? null : () => setState(() => values[key] = null),
              icon: const Icon(Icons.clear),
            ),
        ],
      );
    }
    if (field.kind == 'choice') {
      return DropdownButtonFormField<String>(
        key: ValueKey('$key-${values[key]}'),
        initialValue: values[key] as String?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: field.options.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: busy ? null : (v) => setState(() => values[key] = v),
      );
    }
    if (field.kind == 'multi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label),
          if (field.options.isEmpty)
            const Text(
              'Önce yavruyu Hayvancılık bölümünden hayvan olarak kaydedin.',
            ),
          for (final option in field.options.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.value),
              value: (values[key] as List<String>? ?? []).contains(option.key),
              onChanged: busy
                  ? null
                  : (selected) => setState(() {
                      final ids = List<String>.from(values[key] ?? []);
                      if (selected == true) {
                        ids.add(option.key);
                      } else {
                        ids.remove(option.key);
                      }
                      values[key] = ids;
                    }),
            ),
        ],
      );
    }
    return TextFormField(
      key: ValueKey(key),
      initialValue: values[key]?.toString() ?? '',
      enabled: !busy,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: field.kind == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: field.kind == 'notes' ? 3 : 1,
      onChanged: (v) => values[key] = v,
    );
  }
}

int requiredUnits(dynamic value, int digits, {bool zero = false}) {
  final amount = parseUnits(value?.toString() ?? '', digits);
  if (amount == null || (zero ? amount < 0 : amount <= 0)) {
    throw RecordValidationFailure(
      'Geçerli ${zero ? 'sıfır veya pozitif' : 'pozitif'} miktar girin. En fazla $digits ondalık basamak kullanın.',
    );
  }
  return amount;
}

Future<bool> confirmRecordDelete(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ??
    false;
