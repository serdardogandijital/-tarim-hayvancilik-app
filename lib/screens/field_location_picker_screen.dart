import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class FieldLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final bool isReadOnly;

  const FieldLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.isReadOnly = false,
  });

  @override
  State<FieldLocationPickerScreen> createState() => _FieldLocationPickerScreenState();
}

class _FieldLocationPickerScreenState extends State<FieldLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(39.925533, 32.866287); // Ankara
  late final MapController _mapController;

  LatLng? _selectedLocation;
  LatLng _mapCenter = _defaultCenter;
  String? _address;
  bool _isFetchingLocation = false;
  bool _isFetchingAddress = false;
  String? _error;
  bool _useSatellite = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _address = widget.initialAddress;

    if (_selectedLocation != null) {
      _mapCenter = _selectedLocation!;
    } else if (!widget.isReadOnly) {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isFetchingLocation = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisleri kapalı');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi');
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _mapCenter = currentLocation;
        _selectedLocation = currentLocation;
      });
      await _reverseGeocode(currentLocation);
      _mapController.move(_mapCenter, 15);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() {
      _isFetchingAddress = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final buffer = [
          if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) p.thoroughfare,
          if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) p.subThoroughfare,
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
        ].whereType<String>().join(', ');
        setState(() {
          _address = buffer.isNotEmpty ? buffer : '${p.locality ?? ''} ${p.country ?? ''}'.trim();
        });
      } else {
        setState(() {
          _address = null;
        });
      }
    } catch (e) {
      setState(() {
        _address = null;
        _error = 'Adres çözümlenirken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isFetchingAddress = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (widget.isReadOnly) return;
    setState(() {
      _selectedLocation = latLng;
      _error = null;
    });
    _reverseGeocode(latLng);
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritada bir nokta seçin')),
      );
      return;
    }

    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly ? 'Tarla Konumu' : 'Tarla Konumu Seç'),
        actions: [
          if (!widget.isReadOnly && _selectedLocation != null)
            TextButton(
              onPressed: () => setState(() {
                _selectedLocation = null;
                _address = null;
              }),
              child: const Text('Temizle'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 13,
                    interactionOptions: widget.isReadOnly
                        ? const InteractionOptions(enableScrollWheel: true)
                        : const InteractionOptions(),
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _useSatellite
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.thtakvim.tarim_hayvancilik_app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_isFetchingLocation)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(30),
                      constraints: const BoxConstraints(minWidth: 60, minHeight: 40),
                      isSelected: [!_useSatellite, _useSatellite],
                      onPressed: widget.isReadOnly
                          ? null
                          : (index) {
                              setState(() {
                                _useSatellite = index == 1;
                              });
                            },
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
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seçili Konum',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_selectedLocation == null)
                  const Text('Henüz bir nokta seçilmedi'),
                if (_selectedLocation != null) ...[
                  Text(
                    '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                    '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  if (_isFetchingAddress)
                    Row(
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Adres bulunuyor...'),
                      ],
                    )
                  else if (_address != null && _address!.isNotEmpty)
                    Text(
                      _address!,
                      style: const TextStyle(color: Colors.grey),
                    )
                  else
                    const Text(
                      'Adres bulunamadı, koordinatlar kaydedilecek.',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
                const SizedBox(height: 12),
                if (!widget.isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Bu Konumu Kaydet'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isReadOnly || _isFetchingLocation
          ? null
          : FloatingActionButton.extended(
              onPressed: _determinePosition,
              icon: const Icon(Icons.my_location),
              label: const Text('Konumumu Bul'),
            ),
    );
  }
}
