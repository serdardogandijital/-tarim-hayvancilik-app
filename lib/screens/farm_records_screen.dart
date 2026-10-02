import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/farm_records.dart';
import '../services/animal_storage_service.dart';
import '../services/field_storage_service.dart';
import '../services/farm_record_service.dart';
import '../widgets/record_form.dart';

String money(int cents) =>
    '${NumberFormat('#,##0.00', 'tr_TR').format(cents / 100)} ₺';

class FarmRecordsScreen extends StatefulWidget {
  final int initialTab;
  final String? ownerType, ownerId, ownerName;
  const FarmRecordsScreen({
    super.key,
    this.initialTab = 0,
    this.ownerType,
    this.ownerId,
    this.ownerName,
  });
  @override
  State<FarmRecordsScreen> createState() => _FarmRecordsScreenState();
}

class _FarmRecordsScreenState extends State<FarmRecordsScreen> {
  List<StockItem> stocks = [];
  List<FinanceRecord> entries = [];
  Map<String, String> owners = {'': 'Genel çiftlik'};
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stock = await FarmRecordService.stocks();
    final finance = await FarmRecordService.finances();
    final animals = await AnimalStorageService.loadAnimals();
    final fields = await FieldStorageService.loadFields();
    if (!mounted) return;
    setState(() {
      stocks = stock;
      entries = finance;
      loaded = true;
      owners = {
        '': 'Genel çiftlik',
        for (final a in animals) 'animal:${a.id}': 'Hayvan: ${a.name}',
        for (final f in fields) 'field:${f.id}': 'Tarla: ${f.name}',
      };
      if (widget.ownerId != null) {
        owners.putIfAbsent(
          '${widget.ownerType}:${widget.ownerId}',
          () => widget.ownerName ?? 'Bağlı kayıt',
        );
      }
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

  Future<void> _finance([FinanceRecord? entry]) async {
    final options = {...owners};
    final ownerKey = entry == null
        ? (widget.ownerId == null
              ? ''
              : '${widget.ownerType}:${widget.ownerId}')
        : (entry.ownerId == null ? '' : '${entry.ownerType}:${entry.ownerId}');
    options.putIfAbsent(
      ownerKey,
      () => '${entry?.ownerName ?? 'Kayıt'} (artık mevcut değil)',
    );
    if (await editRecord(
      context,
      title: entry == null ? 'Gelir / gider ekle' : 'İşlemi düzenle',
      help:
          'Gerçekleşen tahsilat veya ödemeyi girin. Yem bilgisi ve stok hareketleri bu deftere otomatik eklenmez; aynı gideri iki kez kaydetmeyin.',
      fields: [
        const RecordInput(
          'kind',
          'İşlem türü',
          kind: 'choice',
          options: {'income': 'Gelir', 'expense': 'Gider'},
        ),
        const RecordInput('amount', 'Tutar (₺)', kind: 'number'),
        const RecordInput('date', 'İşlem tarihi', kind: 'date'),
        RecordInput(
          'category',
          'Kategori',
          kind: 'choice',
          options: {
            for (final c in [
              'Süt',
              'Hayvan',
              'Ürün',
              'Yem',
              'Gübre',
              'Mazot',
              'Veteriner',
              'İlaç',
              'İşçilik',
              'Kira',
              'Diğer',
            ])
              c: c,
          },
        ),
        RecordInput(
          'owner',
          'İlgili kayıt',
          kind: 'choice',
          options: options,
          optional: true,
        ),
        const RecordInput('note', 'Açıklama', kind: 'notes', optional: true),
      ],
      initial: {
        'kind': entry?.income == true ? 'income' : 'expense',
        'amount': entry == null ? '' : unitsText(entry.amountKurus, 2),
        'date': entry?.date ?? dayOnly(DateTime.now()),
        'category': entry?.category ?? 'Diğer',
        'owner': ownerKey,
        'note': entry?.note ?? '',
      },
      save: (v) {
        final key = v['owner'] as String? ?? '';
        final split = key.indexOf(':');
        return FarmRecordService.saveFinance(
          FinanceRecord(
            id: entry?.id ?? recordId(),
            category: v['category'],
            income: v['kind'] == 'income',
            date: v['date'],
            amountKurus: requiredUnits(v['amount'], 2),
            note: v['note'] ?? '',
            ownerType: split < 0 ? null : key.substring(0, split),
            ownerId: split < 0 ? null : key.substring(split + 1),
            ownerName: key.isEmpty
                ? null
                : (key == ownerKey && entry?.ownerName != null
                      ? entry!.ownerName
                      : options[key]),
          ),
        );
      },
    )) {
      await _load();
    }
  }

  Future<void> _stock() async {
    if (await editStock(context)) await _load();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: widget.initialTab,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.ownerName ?? 'Çiftlik kayıtları'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Yem ve malzeme'),
            Tab(text: 'Gelir–gider'),
          ],
        ),
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(children: [_stockView(), _financeView()]),
    ),
  );
  Widget _stockView() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _stock,
          icon: const Icon(Icons.add),
          label: const Text('Stok kartı ekle'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Depoya giren ve kullanılan miktarları kaydedin. Hayvanın günlük yem bilgisi stoğu otomatik düşürmez.',
          ),
        ),
        if (stocks.isEmpty) const Text('Henüz yem veya malzeme kaydı yok.'),
        for (final item in stocks)
          Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${unitsText(item.balanceMilli, 3)} ${item.unit} · Uyarı eşiği ${unitsText(item.minimumMilli, 3)}',
              ),
              leading: Icon(
                item.low ? Icons.warning_amber : Icons.inventory_2_outlined,
                color: item.low ? Colors.orange : Colors.green,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockDetailScreen(id: item.id),
                  ),
                );
                await _load();
              },
            ),
          ),
      ],
    ),
  );
  Widget _financeView() {
    final records = FarmRecordService.monthly(
      entries,
      month,
      ownerType: widget.ownerType,
      ownerId: widget.ownerId,
    )..sort((a, b) => b.date.compareTo(a.date));
    final income = FarmRecordService.total(records, true),
        expense = FarmRecordService.total(records, false);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Önceki ay',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'tr_TR').format(month),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Sonraki ay',
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kayıtlı gelir: ${money(income)}'),
                Text('Kayıtlı gider: ${money(expense)}'),
                Text(
                  'Fark: ${money(income - expense)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Bu fark, girilen işlemlere aittir; net kâr hesabı değildir.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _finance,
          icon: const Icon(Icons.add),
          label: const Text('Gelir / gider ekle'),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty) const Text('Bu ay için kayıt yok.'),
        for (final r in records)
          Card(
            child: ListTile(
              onTap: () => _finance(r),
              leading: Icon(
                r.income ? Icons.south_west : Icons.north_east,
                color: r.income ? Colors.green : Colors.deepOrange,
              ),
              title: Text(
                '${r.income ? '+' : '−'}${money(r.amountKurus)} · ${r.category}',
              ),
              subtitle: Text(
                '${DateFormat('dd.MM.yyyy').format(r.date)} · ${r.ownerName ?? 'Genel çiftlik'}${r.note.isEmpty ? '' : '\n${r.note}'}',
              ),
              trailing: IconButton(
                tooltip: 'İşlemi sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirmRecordDelete(
                    context,
                    'Bu gelir/gider işlemi silinsin mi?',
                  )) {
                    await _change(() => FarmRecordService.deleteFinance(r.id));
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

Future<bool> editStock(BuildContext context, [StockItem? item]) => editRecord(
  context,
  title: item == null ? 'Stok kartı ekle' : 'Stok kartını düzenle',
  fields: [
    const RecordInput('name', 'Yem / malzeme adı'),
    RecordInput(
      'unit',
      'Birim',
      kind: 'choice',
      options: {
        for (final u
            in item != null && item.movements.isNotEmpty
                ? [item.unit]
                : ['kg', 'litre', 'adet', 'çuval', 'balya'])
          u: u,
      },
    ),
    const RecordInput('minimum', 'Azalan stok uyarı eşiği', kind: 'number'),
  ],
  initial: {
    'name': item?.name ?? '',
    'unit': item?.unit ?? 'kg',
    'minimum': unitsText(item?.minimumMilli ?? 0, 3),
  },
  save: (v) => FarmRecordService.saveStock(
    StockItem(
      id: item?.id ?? recordId(),
      name: (v['name'] as String).trim(),
      unit: v['unit'],
      minimumMilli: requiredUnits(v['minimum'], 3, zero: true),
    ),
  ),
);

class StockDetailScreen extends StatefulWidget {
  final String id;
  const StockDetailScreen({super.key, required this.id});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockItem? item;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await FarmRecordService.stocks();
    if (mounted) {
      setState(() => item = items.where((i) => i.id == widget.id).firstOrNull);
    }
  }

  Future<void> _movement([StockMovement? movement]) async {
    if (await editRecord(
      context,
      title: movement == null
          ? 'Stok hareketi ekle'
          : 'Stok hareketini düzenle',
      fields: [
        const RecordInput(
          'kind',
          'Hareket',
          kind: 'choice',
          options: {'in': 'Giriş', 'out': 'Çıkış / kullanım'},
        ),
        RecordInput('amount', 'Miktar (${item!.unit})', kind: 'number'),
        const RecordInput('date', 'Hareket tarihi', kind: 'date'),
        const RecordInput(
          'note',
          'Açıklama / kullanım yeri',
          kind: 'notes',
          optional: true,
        ),
      ],
      initial: {
        'kind': movement == null || movement.quantityMilli > 0 ? 'in' : 'out',
        'amount': movement == null
            ? ''
            : unitsText(movement.quantityMilli.abs(), 3),
        'date': movement?.date ?? dayOnly(DateTime.now()),
        'note': movement?.note ?? '',
      },
      save: (v) => FarmRecordService.saveMovement(
        widget.id,
        StockMovement(
          id: movement?.id ?? recordId(),
          date: v['date'],
          quantityMilli:
              requiredUnits(v['amount'], 3) * (v['kind'] == 'in' ? 1 : -1),
          note: v['note'] ?? '',
        ),
      ),
    )) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(item?.name ?? 'Stok kartı'),
      actions: [
        if (item != null)
          IconButton(
            tooltip: 'Stok kartını düzenle',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (await editStock(context, item)) await _load();
            },
          ),
      ],
    ),
    body: item == null
        ? const Center(child: Text('Stok kartı yükleniyor veya bulunamadı.'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Kalan: ${unitsText(item!.balanceMilli, 3)} ${item!.unit}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Uyarı eşiği: ${unitsText(item!.minimumMilli, 3)} ${item!.unit}',
              ),
              if (item!.low)
                const Text(
                  'Stok uyarı eşiğinde veya altında.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _movement,
                icon: const Icon(Icons.add),
                label: const Text('Stok hareketi ekle'),
              ),
              for (final m in ([
                ...item!.movements,
              ]..sort((a, b) => b.date.compareTo(a.date))))
                ListTile(
                  onTap: () => _movement(m),
                  title: Text(
                    '${m.quantityMilli > 0 ? '+' : '−'}${unitsText(m.quantityMilli.abs(), 3)} ${item!.unit}',
                  ),
                  subtitle: Text(
                    '${DateFormat('dd.MM.yyyy').format(m.date)}${m.note.isEmpty ? '' : '\n${m.note}'}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Hareketi sil',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirmRecordDelete(
                        context,
                        'Bu hareket silinsin mi? Bakiye yeniden hesaplanır.',
                      )) {
                        try {
                          await FarmRecordService.deleteMovement(
                            widget.id,
                            m.id,
                          );
                          await _load();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              const Divider(),
              TextButton(
                onPressed: () async {
                  if (await confirmRecordDelete(
                    context,
                    'Stok kartı ve tüm hareketleri silinsin mi? Gelir–gider kayıtları etkilenmez.',
                  )) {
                    try {
                      await FarmRecordService.deleteStock(widget.id);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
                child: const Text('Stok kartını sil'),
              ),
            ],
          ),
  );
}
