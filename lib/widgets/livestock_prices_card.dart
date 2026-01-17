import 'package:flutter/material.dart';
import '../data/livestock_prices_data.dart';

class LivestockPricesCard extends StatelessWidget {
  final String? selectedCity;

  const LivestockPricesCard({super.key, this.selectedCity});

  @override
  Widget build(BuildContext context) {
    final prices = LivestockPricesData.getPricesForCity(selectedCity);

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
            children: [
              Icon(
                Icons.attach_money,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCity != null
                          ? 'Bugün $selectedCity Karkas Fiyatları'
                          : 'Karkas Hayvan Fiyatları',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Et ve Süt Kurumu resmi fiyatları',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prices != null)
            Column(
              children: [
                _buildPriceSection(
                  context,
                  'Büyükbaş',
                  Icons.agriculture,
                  [
                    _PriceItem('Tosun', prices['Büyükbaş (Tosun)']!),
                    _PriceItem('Dana', prices['Büyükbaş (Dana)']!),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceSection(
                  context,
                  'Küçükbaş',
                  Icons.pets,
                  [
                    _PriceItem('Koç', prices['Küçükbaş (Koç)']!),
                    _PriceItem('Toklu', prices['Küçükbaş (Toklu)']!),
                  ],
                ),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Konum seçilmedi',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_PriceItem> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(0)} ₺/kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PriceItem {
  final String name;
  final double price;

  _PriceItem(this.name, this.price);
}
