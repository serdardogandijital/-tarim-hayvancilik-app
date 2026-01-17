import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/planting_data.dart';

class TodayPlantingCard extends StatelessWidget {
  final String? selectedCity;

  const TodayPlantingCard({super.key, this.selectedCity});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = now.month;
    final cityName = selectedCity ?? 'Bu Bölgede';
    final region = PlantingData.getRegion(selectedCity);
    
    final todayCrops = PlantingData.getTodayPlantableCrops(selectedCity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7A9B5C),
            Color(0xFFA8C686),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bugün $cityName\'da Ne Ekilir?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$region Bölgesi • ${DateFormat('MMMM', 'tr_TR').format(now)} Ayı',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (todayCrops.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu ay için önerilen ekim bulunmamaktadır',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...todayCrops.take(2).map((crop) => _buildCropItem(crop, context)),
        ],
      ),
    );
  }

  IconData _getIconForCropType(String? type) {
    switch (type) {
      case 'Sebze':
        return Icons.eco_outlined;
      case 'Meyve':
        return Icons.apple_outlined;
      case 'Tahıl':
        return Icons.grass_outlined;
      case 'Baklagil':
        return Icons.grain_outlined;
      case 'Endüstri':
        return Icons.factory_outlined;
      case 'Yem':
        return Icons.pets_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  Widget _buildCropItem(Map<String, String> crop, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIconForCropType(crop['type']),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop['name']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  crop['note']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
