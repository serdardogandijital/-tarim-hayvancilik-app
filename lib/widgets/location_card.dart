import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final String address;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onManualSelect;
  final bool isManualSelection;

  const LocationCard({
    super.key,
    required this.address,
    required this.isLoading,
    required this.onRefresh,
    required this.onManualSelect,
    this.isManualSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onManualSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 6),
            isLoading
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    address,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
