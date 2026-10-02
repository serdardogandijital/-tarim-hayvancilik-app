import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../models/farm_records.dart';
import '../services/animal_storage_service.dart';
import '../services/farm_record_service.dart';
import '../services/safe_list_store.dart';
import '../screens/animal_tracking_screen.dart';
import '../screens/farm_records_screen.dart';

class FarmSummaryCard extends StatefulWidget {
  const FarmSummaryCard({super.key});
  @override
  State<FarmSummaryCard> createState() => _FarmSummaryCardState();
}

class _FarmSummaryCardState extends State<FarmSummaryCard>
    with WidgetsBindingObserver {
  List<Animal> animals = [];
  List<StockItem> stocks = [];
  List<FinanceRecord> entries = [];
  bool loaded = false;
  bool failed = false;
  int request = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SafeListStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SafeListStore.revision.removeListener(_load);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final token = ++request;
    final a = await AnimalStorageService.loadAnimals();
    final s = await FarmRecordService.stocks();
    final f = await FarmRecordService.finances();
    if (!mounted || token != request) return;
    setState(() {
      animals = a;
      stocks = s;
      entries = f;
      loaded = true;
      failed = SafeListStore.errors.value.any(
        ['animals_data', 'farm_stock_v1', 'farm_finance_v1'].contains,
      );
    });
  }

  void _open(int tab) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => FarmRecordsScreen(initialTab: tab)),
  );
  void _milkAnimals() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Süt kaydı girilecek hayvanı seçin')),
            if (animals.isEmpty)
              const ListTile(
                title: Text('Önce Hayvancılık bölümünden hayvan ekleyin.'),
              ),
            for (final a in animals)
              ListTile(
                title: Text(a.name),
                subtitle: Text(
                  a.milkTrackingEnabled
                      ? 'Süt takibi açık'
                      : 'Süt takibi kapalı',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimalTrackingScreen(animalId: a.id),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final missing = FarmRecordService.missingMilk(animals, now);
    final month = FarmRecordService.monthly(entries, now);
    final low = stocks.where((s) => s.low).toList();
    final hasMilk = animals.any(
      (a) => a.milkRecords.any((r) => sameDay(r.date, now)),
    );
    final milk = _metric(
      icon: Icons.water_drop_outlined,
      tint: const Color(0xFFE9F1F5),
      color: const Color(0xFF46758B),
      title: 'Bugünkü süt',
      value: hasMilk
          ? '${FarmRecordService.milkTotal(animals, now).toStringAsFixed(1)} L'
          : 'Kayıt yok',
      detail: missing.isNotEmpty
          ? '${missing.length} hayvanda süt kaydı eksik'
          : hasMilk
          ? 'Günlük kayıtlar tamam'
          : 'Süt kaydı ekle',
      onTap: _milkAnimals,
    );
    final stock = _metric(
      icon: Icons.inventory_2_outlined,
      tint: const Color(0xFFFFF2DF),
      color: const Color(0xFF97672A),
      title: 'Yem ve malzeme',
      value: low.isEmpty ? '${stocks.length} ürün' : '${low.length} uyarı',
      detail: low.isEmpty
          ? 'Stokları görüntüle'
          : '${low.length} stok uyarı eşiğinde',
      onTap: () => _open(0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'Çiftlik özeti',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF243C30),
            ),
          ),
        ),
        if (!loaded)
          const LinearProgressIndicator()
        else if (failed)
          TextButton(
            onPressed: _load,
            child: const Text('Bazı kayıtlar okunamadı. Tekrar dene'),
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19) {
                return Column(
                  children: [milk, const SizedBox(height: 12), stock],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: milk),
                  const SizedBox(width: 12),
                  Expanded(child: stock),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFE9EEE5),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF526D46),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bu ay · Gelir − gider',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D7054),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            money(
                              FarmRecordService.total(month, true) -
                                  FarmRecordService.total(month, false),
                            ),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2F4B29),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gelir–gider defteri · Kayıtlı işlemler',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5D7054),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF526D46),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric({
    required IconData icon,
    required Color tint,
    required Color color,
    required String title,
    required String value,
    required String detail,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: Color(0xFF94A094),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6F7A71)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243C30),
                ),
              ),
              const SizedBox(height: 4),
              Text(detail, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
