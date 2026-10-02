import 'package:flutter/material.dart';

class LivestockPricesCard extends StatelessWidget {
  final String? selectedCity;
  const LivestockPricesCard({super.key, this.selectedCity});
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karkas Hayvan Fiyatları',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Doğrulanmış güncel fiyat bilgisi şu anda mevcut değil.'),
        ],
      ),
    ),
  );
}
