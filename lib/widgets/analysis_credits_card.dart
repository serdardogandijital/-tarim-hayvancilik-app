import 'package:flutter/material.dart';
import '../services/analysis_credits.dart';
import '../services/ad_service.dart';
import '../services/analysis_purchases.dart';

class AnalysisCreditsCard extends StatefulWidget {
  const AnalysisCreditsCard({super.key});
  @override
  State<AnalysisCreditsCard> createState() => _AnalysisCreditsCardState();
}

class _AnalysisCreditsCardState extends State<AnalysisCreditsCard> {
  @override
  void initState() {
    super.initState();
    AnalysisCredits.instance.refresh();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AnalysisCredits.instance,
    builder: (context, _) {
      final credits = AnalysisCredits.instance;
      return Material(
        color: const Color(0xFFE8EFE3),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: credits.error != null
              ? credits.refresh
              : () => showCreditsDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 22,
                  color: Color(0xFF406B39),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credits.ready
                            ? '${credits.available} analiz hakkın var'
                            : 'Analiz hakları',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C4E2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        credits.error ?? 'Her yeni günde +1 bonus hak',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5D7457),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  credits.error != null ? 'Tekrar dene' : 'Hak ekle',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C4E2D),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF406B39),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showCreditsDialog(
  BuildContext context, {
  RewardCredits? rewards,
  AnalysisPurchases? purchases,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RewardDialog(
      rewards: rewards ?? RewardCredits.instance,
      purchases: purchases ?? AnalysisPurchases.instance,
    ),
  );
}

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({required this.rewards, required this.purchases});
  final RewardCredits rewards;
  final AnalysisPurchases purchases;
  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  String? message;
  @override
  void initState() {
    super.initState();
    widget.purchases.load();
  }

  Widget _pack(AnalysisPack pack, bool blocked) {
    final purchases = widget.purchases;
    final product = purchases.products[pack.id];
    final available = purchases.canBuy(pack.id) && !blocked;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pack.credits == 50
            ? const Color(0xFFE8EFE3)
            : const Color(0xFFF3F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pack.credits} analiz hakkı',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C4E2D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product?.price ?? pack.plannedPrice,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            product == null
                ? 'Planlanan fiyat · Henüz satışta değil'
                : 'Tek seferlik ödeme · Abonelik değil',
            style: const TextStyle(fontSize: 11),
          ),
          if (product != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: available
                    ? () async {
                        setState(() => message = null);
                        await purchases.buy(pack.id);
                      }
                    : null,
                child: Text(purchases.busy ? 'İşlem sürüyor…' : 'Satın al'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.rewards,
      widget.rewards.credits,
      widget.purchases,
    ]),
    builder: (context, _) {
      final rewards = widget.rewards;
      return PopScope(
        canPop: !rewards.busy && !widget.purchases.busy,
        child: AlertDialog(
          scrollable: true,
          title: Text('${rewards.credits.available} analiz hakkın var'),
          content: SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canlı baskül ve bitki analizi için ortak haklar.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...AnalysisPack.all.map((pack) => _pack(pack, rewards.busy)),
                if (widget.purchases.busy) const LinearProgressIndicator(),
                if (message != null || widget.purchases.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      message ?? widget.purchases.message!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (widget.purchases.ready || widget.purchases.needsSync)
                  TextButton.icon(
                    onPressed: rewards.busy || widget.purchases.busy
                        ? null
                        : widget.purchases.sync,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Ödemeyi kontrol et'),
                  ),
                const Divider(height: 24),
                const Text(
                  'Ücretsiz hak kazan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'İlk kullanımda 3 hak, sonraki günlerin ilk girişinde +1 hak. Hakların birikir. Başarılı fotoğraf analizi 1 hak kullanır; ölçülerle hesaplama ücretsizdir.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'İstersen bir ödüllü reklamı tamamlayarak +1 hak kazanabilirsin. Erken kapatırsan hak eklenmez.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: rewards.busy || widget.purchases.busy
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Şimdi değil'),
            ),
            FilledButton(
              onPressed: rewards.busy || widget.purchases.busy
                  ? null
                  : () async {
                      final result = await rewards.earn();
                      if (mounted) setState(() => message = result);
                    },
              child: Text(
                rewards.busy
                    ? 'Lütfen bekleyin…'
                    : rewards.hasPendingReward
                    ? 'Ödülü kaydet'
                    : 'Reklam izle · +1 hak',
              ),
            ),
          ],
        ),
      );
    },
  );
}
