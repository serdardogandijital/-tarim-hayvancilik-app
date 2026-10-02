import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import '../models/farm_records.dart';
import '../services/animal_storage_service.dart';
import '../services/farm_record_service.dart';
import '../services/notification_service.dart';
import '../widgets/record_form.dart';

class AnimalTrackingScreen extends StatefulWidget {
  final String animalId;
  final int initialTab;
  const AnimalTrackingScreen({
    super.key,
    required this.animalId,
    this.initialTab = 0,
  });
  @override
  State<AnimalTrackingScreen> createState() => _AnimalTrackingScreenState();
}

class _AnimalTrackingScreenState extends State<AnimalTrackingScreen> {
  Animal? animal;
  List<Animal> herd = [];
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final animals = await AnimalStorageService.loadAnimals();
    if (!mounted) return;
    setState(() {
      herd = animals;
      animal = animals.where((a) => a.id == widget.animalId).firstOrNull;
      loaded = true;
    });
  }

  Future<void> _change(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _milk([DateTime? date]) async {
    final a = animal!;
    final today = dayOnly(date ?? DateTime.now());
    final amount = FarmRecordService.dailyMilk(a)[today];
    if (await editRecord(
      context,
      title: 'Günlük süt kaydı',
      help:
          'Seçilen günün toplam litresini girin. O günün önceki kayıtlarının yerine bu toplam kaydedilir. 0 litre girilebilir; boş gün kayıt yok demektir.',
      fields: const [
        RecordInput('date', 'Kayıt tarihi', kind: 'date'),
        RecordInput('amount', 'Günlük toplam (litre)', kind: 'number'),
      ],
      initial: {
        'date': today,
        'amount': amount == null ? '' : amount.toString().replaceAll('.', ','),
      },
      save: (v) => FarmRecordService.saveMilk(
        a.id,
        v['date'],
        requiredUnits(v['amount'], 3, zero: true) / 1000,
        previousDate: date,
      ),
    )) {
      await _load();
    }
  }

  Future<void> _breeding([BreedingRecord? record]) async {
    final a = animal!;
    final childOptions = {
      for (final c in herd.where((c) => c.id != a.id))
        c.id: '${c.name} (${DateFormat('dd.MM.yyyy').format(c.birthDate)})',
    };
    // Keep deleted references visible so the user can explicitly remove them.
    for (final id in record?.offspringIds ?? <String>[]) {
      childOptions.putIfAbsent(id, () => 'Silinmiş yavru kaydı ($id)');
    }
    if (await editRecord(
      context,
      title: record == null ? 'Tohumlama kaydı ekle' : 'Üreme kaydını düzenle',
      help:
          'Beklenen doğum tarihini kendi kaydınıza veya veterinerinizin değerlendirmesine göre girin. Durum ve tarihler otomatik teşhis değildir.',
      fields: [
        const RecordInput('start', 'Tohumlama tarihi', kind: 'date'),
        RecordInput(
          'status',
          'Sonuç / durum',
          kind: 'choice',
          options: {for (final s in BreedingStatus.values) s.name: s.label},
        ),
        RecordInput(
          'check',
          'Kontrol tarihi',
          kind: 'date',
          optional: true,
          visible: (v) => v['status'] == 'pending',
        ),
        RecordInput(
          'expected',
          'Beklenen doğum tarihi',
          kind: 'date',
          visible: (v) => v['status'] == 'pregnant',
        ),
        RecordInput(
          'actual',
          'Gerçek doğum tarihi',
          kind: 'date',
          visible: (v) => v['status'] == 'born',
        ),
        RecordInput(
          'children',
          'Yavru kayıtları',
          kind: 'multi',
          options: childOptions,
          optional: true,
          visible: (v) => v['status'] == 'born',
        ),
        const RecordInput('notes', 'Notlar', kind: 'notes', optional: true),
      ],
      initial: {
        'start': record?.inseminationDate ?? dayOnly(DateTime.now()),
        'status': record?.status.name ?? 'pending',
        'check': record?.checkDate,
        'expected': record?.expectedBirthDate,
        'actual': record?.actualBirthDate,
        'children': record?.offspringIds ?? <String>[],
        'notes': record?.notes ?? '',
      },
      save: (v) => FarmRecordService.saveBreeding(
        a.id,
        BreedingRecord(
          id: record?.id ?? recordId(),
          inseminationDate: v['start'],
          status: BreedingStatus.values.byName(v['status']),
          checkDate: v['check'],
          expectedBirthDate: v['expected'],
          actualBirthDate: v['status'] == 'born' ? v['actual'] : null,
          offspringIds: v['status'] == 'born'
              ? List<String>.from(v['children'])
              : [],
          notes: v['notes'] ?? '',
        ),
      ),
    )) {
      await _load();
      if (animal != null) {
        await NotificationService.instance.scheduleAnimalNotifications(animal!);
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: widget.initialTab,
    child: Scaffold(
      appBar: AppBar(
        title: Text(animal?.name ?? 'Hayvan takibi'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Süt takibi'),
            Tab(text: 'Üreme takibi'),
          ],
        ),
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : animal == null
          ? const Center(child: Text('Hayvan kaydı okunamadı.'))
          : TabBarView(children: [_milkView(), _breedingView()]),
    ),
  );
  Widget _milkView() {
    final a = animal!;
    final daily = FarmRecordService.dailyMilk(a);
    final dates = daily.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = dayOnly(DateTime.now());
    final week = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = week.where(daily.containsKey).map((d) => daily[d]!).toList();
    final sum = values.fold<double>(0, (s, v) => s + v);
    final peak = max(1.0, values.fold<double>(0, max));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Günlük süt takibi açık'),
          subtitle: const Text(
            'Açıksa eksik kayıtlar ana sayfada görünür. Kapatmak geçmişi silmez.',
          ),
          value: a.milkTrackingEnabled,
          onChanged: (v) =>
              _change(() => FarmRecordService.milkTracking(a.id, v)),
        ),
        FilledButton.icon(
          onPressed: _milk,
          icon: const Icon(Icons.add),
          label: const Text('Süt kaydı ekle'),
        ),
        const SizedBox(height: 16),
        Text(
          'Son 7 gün: ${sum.toStringAsFixed(1)} litre',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${values.length}/7 gün kayıtlı${values.isEmpty ? '' : ' · Kayıtlı gün ortalaması ${(sum / values.length).toStringAsFixed(1)} L'}',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 165,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: week.map((d) {
              final value = daily[d];
              return Expanded(
                child: Semantics(
                  label:
                      '${DateFormat('dd.MM').format(d)}: ${value == null ? 'Kayıt yok' : '$value litre'}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        child: Text(
                          value == null ? '—' : value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: value == null ? 3 : max(3, 105 * value / peak),
                        color: value == null
                            ? Colors.grey.shade300
                            : Colors.green,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd.MM').format(d),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Text(
          '— Kayıt yok; sıfır üretim olarak hesaplanmaz.',
          style: TextStyle(fontSize: 12),
        ),
        const Divider(height: 32),
        if (dates.isEmpty) const Text('Henüz süt kaydı yok.'),
        for (final d in dates)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${daily[d]!.toStringAsFixed(2)} litre'),
            subtitle: Text(DateFormat('dd.MM.yyyy').format(d)),
            onTap: () => _milk(d),
            trailing: IconButton(
              tooltip: 'Süt kaydını sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirmRecordDelete(
                  context,
                  'Bu günün süt kaydı silinsin mi?',
                )) {
                  await _change(() => FarmRecordService.deleteMilk(a.id, d));
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _breedingView() {
    final a = animal!;
    final records = [...a.breedingRecords]
      ..sort((a, b) => b.inseminationDate.compareTo(a.inseminationDate));
    final mothers = herd
        .where(
          (m) => m.breedingRecords.any((r) => r.offspringIds.contains(a.id)),
        )
        .toList();
    String date(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (a.lastBirthDate != null)
          Text('Önceki son doğurma kaydı: ${date(a.lastBirthDate!)}'),
        if (a.nextHeatDate != null)
          Text('Kızgınlık takip tarihi: ${date(a.nextHeatDate!)}'),
        for (final m in mothers)
          ListTile(
            title: Text('Anne: ${m.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AnimalTrackingScreen(animalId: m.id, initialTab: 1),
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: _breeding,
          icon: const Icon(Icons.add),
          label: const Text('Tohumlama kaydı ekle'),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const Text('Henüz tohumlama veya doğum geçmişi eklenmedi.'),
        for (final r in records)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.status.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Tohumlama: ${date(r.inseminationDate)}'),
                  if (r.checkDate != null)
                    Text('Kontrol: ${date(r.checkDate!)}'),
                  if (r.expectedBirthDate != null)
                    Text('Beklenen doğum: ${date(r.expectedBirthDate!)}'),
                  if (r.actualBirthDate != null)
                    Text('Gerçekleşen doğum: ${date(r.actualBirthDate!)}'),
                  for (final id in r.offspringIds)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Yavru: ${herd.where((c) => c.id == id).firstOrNull?.name ?? 'Kayıt silinmiş'}',
                      ),
                      onTap: herd.any((c) => c.id == id)
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnimalTrackingScreen(
                                  animalId: id,
                                  initialTab: 1,
                                ),
                              ),
                            )
                          : null,
                    ),
                  if (r.notes.isNotEmpty) Text(r.notes),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => _breeding(r),
                        child: const Text('Düzenle'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await confirmRecordDelete(
                            context,
                            'Üreme kaydı ve yavru bağlantıları silinsin mi? Hayvan kayıtları korunur.',
                          )) {
                            await _change(
                              () =>
                                  FarmRecordService.deleteBreeding(a.id, r.id),
                            );
                            if (animal != null) {
                              await NotificationService.instance
                                  .scheduleAnimalNotifications(animal!);
                            }
                          }
                        },
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
