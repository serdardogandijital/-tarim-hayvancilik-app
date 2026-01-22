import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/field.dart';

class AllFieldsMapScreen extends StatefulWidget {
  final List<Field> fields;

  const AllFieldsMapScreen({super.key, required this.fields});

  @override
  State<AllFieldsMapScreen> createState() => _AllFieldsMapScreenState();
}

class _AllFieldsMapScreenState extends State<AllFieldsMapScreen> {
  static const LatLng _defaultCenter = LatLng(39.925533, 32.866287);
  late final MapController _mapController;
  late final TextEditingController _searchController;
  bool _useSatellite = true;
  Field? _focusedField;
  bool _hasCenteredInitially = false;
  List<Field> _searchResults = [];

  List<Field> get _fieldsWithLocation =>
      widget.fields.where((field) => field.hasLocation).toList();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _updateSearchResults(_searchController.text);
    });
    final withLocation = _fieldsWithLocation;
    if (withLocation.isNotEmpty) {
      _focusedField = withLocation.last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusedField != null && !_hasCenteredInitially) {
          _centerOnField(_focusedField!, zoom: 13.5);
          _hasCenteredInitially = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    if (_focusedField != null && _focusedField!.hasLocation) {
      return LatLng(_focusedField!.latitude!, _focusedField!.longitude!);
    }
    return _defaultCenter;
  }

  double get _initialZoom => _fieldsWithLocation.length > 1 ? 12 : 13.5;

  Color _markerColor(Field field) {
    return field.ownership == FieldOwnership.own
        ? Colors.green.shade600
        : Colors.orange.shade600;
  }

  void _centerOnField(Field field, {double zoom = 13}) {
    if (!field.hasLocation) return;
    final target = LatLng(field.latitude!, field.longitude!);
    _mapController.move(target, zoom);
  }

  void _updateSearchResults(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final lower = trimmed.toLowerCase();
    setState(() {
      _searchResults = _fieldsWithLocation
          .where((field) => field.name.toLowerCase().contains(lower))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _selectField(Field field) {
    setState(() {
      _focusedField = field;
      _searchController.text = field.name;
      _searchResults = [];
    });
    _centerOnField(field, zoom: 14.5);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchResults = []);
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fieldsWithLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Tarlalar Haritada'),
        actions: [
          if (fields.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Tümünü ortala',
              onPressed: () {
                if (fields.isEmpty) return;
                final lat = fields.map((f) => f.latitude!).reduce((a, b) => a + b) /
                    fields.length;
                final lng = fields.map((f) => f.longitude!).reduce((a, b) => a + b) /
                    fields.length;
                _mapController.move(LatLng(lat, lng), fields.length > 1 ? 6.5 : 13);
              },
            ),
        ],
      ),
      body: fields.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                _MapLegend(onToggle: (useSatellite) {
                  setState(() {
                    _useSatellite = useSatellite;
                  });
                }, useSatellite: _useSatellite),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tarla ismi ara',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _clearSearch,
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final field = _searchResults[index];
                              return ListTile(
                                leading: Icon(
                                  field.ownership == FieldOwnership.own
                                      ? Icons.home_work_outlined
                                      : Icons.assignment_ind_outlined,
                                  color: _markerColor(field),
                                ),
                                title: Text(field.name),
                                subtitle: field.locationName != null
                                    ? Text(
                                        field.locationName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        '${field.latitude!.toStringAsFixed(4)}, ${field.longitude!.toStringAsFixed(4)}',
                                      ),
                                onTap: () => _selectField(field),
                              );
                            },
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemCount: _searchResults.length,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: _initialZoom,
                          interactionOptions: const InteractionOptions(
                            enableScrollWheel: true,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _useSatellite
                                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.thtakvim.tarim_hayvancilik_app',
                          ),
                          MarkerLayer(
                            markers: fields.map((field) {
                              final point = LatLng(field.latitude!, field.longitude!);
                              final isFocused = _focusedField?.id == field.id;
                              return Marker(
                                point: point,
                                width: 60,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _focusedField = field;
                                    });
                                    _centerOnField(field, zoom: 13.5);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isFocused
                                          ? _markerColor(field)
                                          : _markerColor(field).withOpacity(0.85),
                                      shape: BoxShape.circle,
                                      boxShadow: isFocused
                                          ? [
                                              BoxShadow(
                                                color: _markerColor(field).withOpacity(0.5),
                                                blurRadius: 16,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.agriculture,
                                          color: Colors.white,
                                          size: isFocused ? 24 : 20,
                                        ),
                                        if (isFocused)
                                          Text(
                                            field.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (_focusedField != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _FieldInfoCard(field: _focusedField!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final bool useSatellite;
  final ValueChanged<bool> onToggle;

  const _MapLegend({required this.useSatellite, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegendDot(color: Colors.green.shade600, label: 'Kendi Tarlam'),
                _LegendDot(color: Colors.orange.shade600, label: 'Kiralık Tarla'),
              ],
            ),
          ),
          ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            constraints: const BoxConstraints(minWidth: 60, minHeight: 36),
            isSelected: [!useSatellite, useSatellite],
            onPressed: (index) => onToggle(index == 1),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Harita'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Uydu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FieldInfoCard extends StatelessWidget {
  final Field field;

  const _FieldInfoCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  field.ownership == FieldOwnership.own
                      ? Icons.home_work_outlined
                      : Icons.assignment_ind_outlined,
                  color: field.ownership == FieldOwnership.own
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${field.area} dönüm',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (field.locationName != null)
              Text(
                field.locationName!,
                style: const TextStyle(color: Colors.black87),
              )
            else
              Text(
                '${field.latitude!.toStringAsFixed(5)}, ${field.longitude!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.black87),
              ),
            if (field.currentCrop != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ürün: ${field.currentCrop}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Henüz konumu kaydedilmiş tarla yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tarla eklerken haritada konum seçerek tüm tarlalarınızı birlikte görebilirsiniz.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
