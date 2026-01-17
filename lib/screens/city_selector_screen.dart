import 'package:flutter/material.dart';
import '../models/city.dart';

class CitySelectorScreen extends StatefulWidget {
  const CitySelectorScreen({super.key});

  @override
  State<CitySelectorScreen> createState() => _CitySelectorScreenState();
}

class _CitySelectorScreenState extends State<CitySelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<City> _filteredCities = City.getAllCities();
  String _selectedRegion = 'Tümü';

  final List<String> _regions = [
    'Tümü',
    'Marmara',
    'Ege',
    'Akdeniz',
    'İç Anadolu',
    'Karadeniz',
    'Doğu Anadolu',
    'Güneydoğu Anadolu',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredCities = City.getAllCities().where((city) {
        final matchesSearch = city.name.toLowerCase().contains(query) ||
            city.plateCode.contains(query);
        final matchesRegion =
            _selectedRegion == 'Tümü' || city.region == _selectedRegion;
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
      _filterCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İl Seçin'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'İl veya plaka kodu ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = region == _selectedRegion;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (selected) {
                      _selectRegion(region);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredCities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'İl bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            city.plateCode,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          city.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(city.region),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context, city);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
